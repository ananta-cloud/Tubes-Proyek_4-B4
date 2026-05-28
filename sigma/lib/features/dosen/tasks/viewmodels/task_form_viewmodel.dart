import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/dosen_model.dart';
import '../../../../data/models/pengajaran_model.dart';
import '../../../../data/repositories/pengajaran_repository.dart';
import '../../../../data/services/task_service.dart';
import '../../../../data/services/pengajaran_service.dart';
import '../../../../core/network/mongo_database.dart';

class TaskFormViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final PengajaranRepository _pengajaranRepo = PengajaranRepository();

  final TextEditingController namaTugasController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();

  String? selectedMatkulDisplay;
  List<String> selectedTargetKelas = [];

  List<PengajaranModel> listPengajaran = [];
  List<String> uniqueMatkulList = [];
  List<String> availableKelasList = [];

  DateTime? selectedDeadline;
  List<Map<String, String>> lampiran = [];
  bool isLoadingPengajaran = false;
  bool isLoading = false;
  bool isDisposed = false;

  final PengajaranService _pengajaranService = PengajaranService();

  final Map<String, String> _kelasCacheNames = {};

  // Di dalam TaskFormViewModel.dart
  // Di dalam TaskFormViewModel.dart
  void initializeForEdit(TaskModel task) {
    print("DEBUG: Memulai inisialisasi edit untuk tugas: ${task.namaTugas}");
    
    // 1. Set teks
    namaTugasController.text = task.namaTugas;
    deskripsiController.text = task.deskripsi ?? '';
    
    // 2. Set deadline & lampiran
    selectedDeadline = task.deadline;
    lampiran = task.lampiran ?? [];

    // Catatan: selectedMatkulDisplay dan selectedTargetKelas JANGAN di-set di sini, 
    // karena uniqueMatkulList belum tersedia. Biarkan _initDropdownsForEdit yang mengerjakannya.

    notifyListeners();
  }

  // ====================================================================
  // PERBAIKAN: RESOLVE NAMA KELAS DENGAN PRODI (Menjadi "2B-D3")
  // ====================================================================
  Future<String> _resolveNamaKelas(String idKelasHex) async {
    // Pengaman: Jika data sudah berupa teks biasa (bukan ID 24 karakter), kembalikan langsung
    if (idKelasHex.length != 24) return idKelasHex;

    // Ambil dari memori lokal jika sudah pernah di-fetch sebelumnya
    if (_kelasCacheNames.containsKey(idKelasHex)) {
      return _kelasCacheNames[idKelasHex]!;
    }

    try {
      final kelasDoc = await MongoDatabase.kelasCollection.findOne(
        where.id(ObjectId.fromHexString(idKelasHex)),
      );

      if (kelasDoc != null && kelasDoc.containsKey('nama_kelas')) {
        String name = kelasDoc['nama_kelas'].toString(); // Dapat "2B"

        // Tarik data prodi agar namanya kembali menjadi "2B-D3"
        if (kelasDoc['id_prodi'] != null) {
          final dynamic rawProdiId = kelasDoc['id_prodi'];
          final ObjectId prodiObjId = rawProdiId is ObjectId
              ? rawProdiId
              : ObjectId.fromHexString(rawProdiId.toString());

          final prodiDoc = await MongoDatabase.db
              .collection('prodi')
              .findOne(where.id(prodiObjId));

          if (prodiDoc != null && prodiDoc['nama_prodi'] != null) {
            String namaProdi = prodiDoc['nama_prodi'].toString().toUpperCase();
            if (namaProdi.contains('D3') || namaProdi.contains('D-III')) {
              name += "-D3";
            } else if (namaProdi.contains('D4') ||
                namaProdi.contains('D-IV') ||
                namaProdi.contains('SARJANA TERAPAN')) {
              name += "-D4";
            }
          }
        }

        _kelasCacheNames[idKelasHex] = name; // Simpan ke cache
        return name;
      }
      return "Unknown";
    } catch (e) {
      return "Error";
    }
  }

  Future<void> loadPengajaran(
    DosenModel currentDosen, {
    TaskModel? taskToEdit,
  }) async {
    // Cek apakah ViewModel masih aktif sebelum memulai
    if (isDisposed) return;

    isLoadingPengajaran = true;
    notifyListeners();

    try {
      String kodeDosenLogin = currentDosen.kodeDosen;

      // 1. Ambil data dari Hive (Lokal)
      listPengajaran = _pengajaranRepo.getLocalPengajaran(kodeDosenLogin);

      if (listPengajaran.isNotEmpty && !isDisposed) {
        print(
          "⚡ [LOKAL] Memuat ${listPengajaran.length} mata kuliah dari Hive.",
        );
        _generateUniqueMatkul();
        if (taskToEdit != null) await _initDropdownsForEdit(taskToEdit);
        notifyListeners();
      }

      print("☁️ [CLOUD] Mencoba sinkronisasi jadwal mata kuliah ke MongoDB...");

      // 2. Sinkronisasi dari Cloud
      await _pengajaranRepo.syncPengajaran(kodeDosenLogin);

      // 3. Ambil data yang sudah terupdate
      final updatedList = _pengajaranRepo.getLocalPengajaran(kodeDosenLogin);

      // Gunakan pengecekan !isDisposed sebelum notifyListeners()
      if (!isDisposed &&
          (updatedList.length != listPengajaran.length ||
              listPengajaran.isEmpty)) {
        listPengajaran = updatedList;
        _generateUniqueMatkul();
        if (taskToEdit != null) await _initDropdownsForEdit(taskToEdit);

        print("✅ [SYNC] Dropdown diperbarui dengan data terbaru dari Cloud.");
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading pengajaran: $e');
    } finally {
      // Pastikan status loading dimatikan jika ViewModel belum disposed
      if (!isDisposed) {
        isLoadingPengajaran = false;
        notifyListeners();
      }
    }
  }

  void _generateUniqueMatkul() {
    uniqueMatkulList = listPengajaran
        .map((p) => "${p.kodeMk} - ${p.namaMk}")
        .toSet()
        .toList();
  }

  Future<void> _initDropdownsForEdit(TaskModel task) async {
    try {
      // 1. CARI MATA KULIAH BERDASARKAN KODE MK (Bukan berdasarkan ID lagi)
      final int matchIndex = listPengajaran.indexWhere((p) {
        if (task.namaMkSnapshot == null) return false;
        // Mengecek apakah snapshot teks "KODE - NAMA" diawali dengan kodeMk dari list pengajaran
        return task.namaMkSnapshot!.startsWith(p.kodeMk);
      });

      if (matchIndex == -1) {
         print("Warning: Mata Kuliah untuk tugas '${task.namaTugas}' tidak ditemukan dalam jadwal Dosen saat ini.");
         return; // Hentikan proses dropdown, biarkan form teks saja yang terisi
      }

      // Ambil data yang cocok
      final matched = listPengajaran[matchIndex];

      // 2. SET DROPDOWN MATA KULIAH
      selectedMatkulDisplay = "${matched.kodeMk} - ${matched.namaMk}";
      print("DEBUG: Dropdown diset ke: $selectedMatkulDisplay");

      // 3. UPDATE LIST KELAS BERDASARKAN MATKUL YANG TERPILIH
      await _updateAvailableKelas();

      // 4. SET TARGET KELAS YANG SUDAH DICENTANG
      final taskBox = Hive.box<TaskModel>('tasks');
      final listTugasSejenis = taskBox.values.where(
        (t) =>
            t.namaTugas == task.namaTugas &&
            t.deadline.isAtSameMomentAs(task.deadline) &&
            // Ubah juga pencarian tugas sejenis agar mencocokkan kode/nama snapshot, bukan idMk
            t.namaMkSnapshot != null && t.namaMkSnapshot!.startsWith(matched.kodeMk),
      );

      List<String> semuaKelasTercentang = [];
      for (var t in listTugasSejenis) {
        if (t.kelas != null && t.kelas!.isNotEmpty) {
           semuaKelasTercentang.add(t.kelas!);
        } else if (t.namaMkSnapshot != null && t.namaMkSnapshot!.contains('(')) {
          // Fallback jika field kelas kosong, ekstrak dari snapshot
          String kelas = t.namaMkSnapshot!
              .split('(')
              .last
              .replaceAll(')', '')
              .trim();
          semuaKelasTercentang.add(kelas);
        }
      }

      // Filter agar yang dicentang hanya kelas yang memang valid ada di mata kuliah tersebut
      selectedTargetKelas = semuaKelasTercentang
          .where((k) => availableKelasList.contains(k))
          .toSet()
          .toList();

      print("DEBUG: Target kelas diset ke: $selectedTargetKelas");
      notifyListeners();

    } catch (e) {
      print('Error init dropdown edit: $e');
    }
  }

  void selectMatkul(String? matkulDisplay) {
    selectedMatkulDisplay = matkulDisplay;
    selectedTargetKelas = [];
    _updateAvailableKelas();
    notifyListeners();
  }

  // 🔥 PERBAIKAN: Ubah menjadi Future<void>
  Future<void> _updateAvailableKelas() async {
    if (selectedMatkulDisplay == null) {
      availableKelasList = [];
      notifyListeners();
      return;
    }

    final matchedDocs = listPengajaran.where(
      (p) => "${p.kodeMk} - ${p.namaMk}" == selectedMatkulDisplay,
    );

    Set<String> tempKelasNames = {};

    for (var doc in matchedDocs) {
      for (var id in doc.targetKelas) {
        String nama = await _resolveNamaKelas(id);
        tempKelasNames.add(nama);
      }
    }

    availableKelasList = tempKelasNames.toList();
    notifyListeners();
  }

  void toggleKelas(String kelas) {
    if (selectedTargetKelas.contains(kelas)) {
      selectedTargetKelas.remove(kelas);
    } else {
      selectedTargetKelas.add(kelas);
    }
    notifyListeners();
  }

  PengajaranModel? _getMatchedPengajaran() {
    if (selectedMatkulDisplay == null) return null;
    try {
      return listPengajaran.firstWhere(
        (p) => "${p.kodeMk} - ${p.namaMk}" == selectedMatkulDisplay,
      );
    } catch (_) {
      return null;
    }
  }

  // ====================================================================
  // LAMPIRAN & UPLOAD
  // ====================================================================
  void addAttachment(String type, String title, String uri) {
    lampiran.add({'type': type, 'title': title, 'uri': uri});
    notifyListeners();
  }

  void removeAttachment(int index) {
    lampiran.removeAt(index);
    notifyListeners();
  }

  Future<PlatformFile?> pickFile() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) await Permission.storage.request();

        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) await Permission.photos.request();
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );
      if (result != null) return result.files.single;
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  // =========================================================================
  // FUNGSI CREATE (Menyimpan targetKelas & namaDosen)
  // =========================================================================
  Future<bool> createTaskForStudents(UserModel currentUser) async {
    if (namaTugasController.text.isEmpty ||
        selectedDeadline == null ||
        selectedTargetKelas.isEmpty)
      return false;

    final matched = _getMatchedPengajaran();
    if (matched == null) return false;

    final String cleanUserId = currentUser.id
        .replaceAll('ObjectId("', '')
        .replaceAll('")', '');
    bool allSuccess = true;

    for (String kelas in selectedTargetKelas) {
      final String newTaskId = ObjectId().toHexString();
      final newTask = TaskModel(
        id: newTaskId,
        idUser: cleanUserId,
        namaTugas: namaTugasController.text,
        deskripsi: deskripsiController.text.isNotEmpty
            ? deskripsiController.text
            : null,
        idMk: matched.id,
        namaMkSnapshot: "${matched.kodeMk} - ${matched.namaMk} ($kelas)",
        deadline: selectedDeadline!,
        status: 'BELUM',
        isSynced: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lampiran: lampiran.isNotEmpty ? lampiran : null,
        kelas: kelas,
        namaDosen: currentUser.nama,
      );

      try {
        final taskBox = Hive.box<TaskModel>('tasks');
        await taskBox.put(newTaskId, newTask);
        _backgroundSync(newTask, isCreate: true);
      } catch (e) {
        print("❌ Error Create: $e");
        allSuccess = false;
      }
    }
    notifyListeners();
    return allSuccess;
  }

  // =========================================================================
  // FUNGSI EDIT (Menyimpan targetKelas & namaDosen)
  // =========================================================================
  // =========================================================================
  // FUNGSI EDIT (Pencarian Menggunakan Data Lama agar Tidak Duplikat)
  // =========================================================================
  Future<bool> updateTaskForStudents(
    TaskModel taskLama,
    UserModel currentUser,
  ) async {
    if (namaTugasController.text.isEmpty ||
        selectedDeadline == null ||
        selectedTargetKelas.isEmpty) return false;

    final matched = _getMatchedPengajaran();
    if (matched == null) return false;

    try {
      final taskBox = Hive.box<TaskModel>('tasks');

      // 1. CARI TUGAS LAMA DI DATABASE
      // WAJIB menggunakan data dari 'taskLama', bukan data yang baru diketik di form!
      final listTugasSejenis = taskBox.values.where((t) {
        bool isNameSame = t.namaTugas == taskLama.namaTugas;
        // Pengecekan waktu kebal terhadap perbedaan detik/milidetik dari server
        bool isTimeSame = t.deadline.year == taskLama.deadline.year &&
                          t.deadline.month == taskLama.deadline.month &&
                          t.deadline.day == taskLama.deadline.day &&
                          t.deadline.hour == taskLama.deadline.hour &&
                          t.deadline.minute == taskLama.deadline.minute;
        bool isMatkulSame = t.idMk == taskLama.idMk;

        return isNameSame && isTimeSame && isMatkulSame;
      }).toList();

      // 2. TIMPA TUGAS LAMA SECARA BERURUTAN
      int i = 0;
      for (; i < selectedTargetKelas.length; i++) {
        String kelas = selectedTargetKelas[i];

        if (i < listTugasSejenis.length) {
          // A. REUSE TUGAS LAMA (Gunakan ID yang sama, timpa datanya)
          TaskModel tToUpdate = listTugasSejenis[i];
          
          tToUpdate.namaTugas = namaTugasController.text; // Timpa nama
          tToUpdate.deskripsi = deskripsiController.text.isNotEmpty
              ? deskripsiController.text
              : null;
          tToUpdate.idMk = matched.id; // Timpa Matkul
          tToUpdate.namaMkSnapshot = "${matched.kodeMk} - ${matched.namaMk} ($kelas)";
          tToUpdate.deadline = selectedDeadline!; // Timpa Deadline
          tToUpdate.lampiran = lampiran.isNotEmpty ? lampiran : null;
          tToUpdate.updatedAt = DateTime.now();
          tToUpdate.isSynced = false;
          tToUpdate.kelas = kelas; // Timpa Kelas
          tToUpdate.namaDosen = currentUser.nama;

          await tToUpdate.save(); // Simpan perubahan ke ID yang sama!
          _backgroundSync(tToUpdate, isCreate: false);
        } else {
          // B. BUAT TUGAS BARU HANYA JIKA KELAS DITAMBAH (Misal awalnya 1 kelas, jadi 2 kelas)
          final String newTaskId = ObjectId().toHexString();
          final newTask = TaskModel(
            id: newTaskId,
            idUser: taskLama.idUser,
            namaTugas: namaTugasController.text,
            deskripsi: deskripsiController.text.isNotEmpty
                ? deskripsiController.text
                : null,
            idMk: matched.id,
            namaMkSnapshot: "${matched.kodeMk} - ${matched.namaMk} ($kelas)",
            deadline: selectedDeadline!,
            status: 'BELUM',
            isSynced: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            lampiran: lampiran.isNotEmpty ? lampiran : null,
            kelas: kelas,
            namaDosen: currentUser.nama,
          );
          await taskBox.put(newTaskId, newTask);
          _backgroundSync(newTask, isCreate: true);
        }
      }

      // 3. HAPUS SISA TUGAS JIKA KELAS DIKURANGI (Misal awalnya 2 kelas, dikurangi jadi 1)
      for (; i < listTugasSejenis.length; i++) {
        TaskModel tToDelete = listTugasSejenis[i];
        await taskBox.delete(tToDelete.id);
        _taskService.deleteTask(tToDelete.id);
      }

      notifyListeners();
      return true;
    } catch (e) {
      print("❌ Error Update: $e");
      return false;
    }
  }

  Future<void> _backgroundSync(TaskModel task, {required bool isCreate}) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = !(connectivityResult as List).contains(
        ConnectivityResult.none,
      );

      if (isOnline) {
        bool cloudSuccess = isCreate
            ? await _taskService.createTask(task)
            : await _taskService.updateTask(task);
        if (cloudSuccess) {
          task.isSynced = true;
          await task.save();
        }
      }
    } catch (e) {
      print("☁️ Background Sync Error: $e");
    }
  }

  void clearForm() {
    namaTugasController.clear();
    deskripsiController.clear();
    selectedMatkulDisplay = null;
    selectedTargetKelas = [];
    availableKelasList = [];
    selectedDeadline = null;
    lampiran.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    namaTugasController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }
}
