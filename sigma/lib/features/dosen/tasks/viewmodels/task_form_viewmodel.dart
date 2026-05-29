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
  final Map<String, String> _kelasNameToIdMap = {};
  
  // 🔥 MAP BARU: Menyimpan nama asli mata kuliah agar dropdown tidak error
  final Map<String, String> _matkulRealNames = {};

  void initializeForEdit(TaskModel task) {
    namaTugasController.text = task.namaTugas;
    deskripsiController.text = task.deskripsi ?? '';
    selectedDeadline = task.deadline;
    lampiran = task.lampiran ?? [];
    notifyListeners();
  }

  Future<String> _resolveNamaKelas(String idKelasHex) async {
    if (idKelasHex.length != 24) return idKelasHex;
    if (_kelasCacheNames.containsKey(idKelasHex)) return _kelasCacheNames[idKelasHex]!;

    try {
      final kelasDoc = await MongoDatabase.kelasCollection.findOne(where.id(ObjectId.parse(idKelasHex)));

      if (kelasDoc != null && kelasDoc.containsKey('nama_kelas')) {
        String name = kelasDoc['nama_kelas'].toString();

        if (kelasDoc['id_prodi'] != null) {
          final dynamic rawProdiId = kelasDoc['id_prodi'];
          final ObjectId prodiObjId = rawProdiId is ObjectId ? rawProdiId : ObjectId.parse(rawProdiId.toString());

          final prodiDoc = await MongoDatabase.db.collection('prodi').findOne(where.id(prodiObjId));

          if (prodiDoc != null && prodiDoc['nama_prodi'] != null) {
            String namaProdi = prodiDoc['nama_prodi'].toString().toUpperCase();
            if (namaProdi.contains('D3') || namaProdi.contains('D-III')) {
              name += "-D3";
            } else if (namaProdi.contains('D4') || namaProdi.contains('D-IV') || namaProdi.contains('SARJANA TERAPAN')) {
              name += "-D4";
            }
          }
        }
        _kelasCacheNames[idKelasHex] = name;
        return name;
      }
      return "Unknown";
    } catch (e) {
      return "Error";
    }
  }

  Future<void> loadPengajaran(DosenModel currentDosen, {TaskModel? taskToEdit}) async {
    if (isDisposed) return;
    isLoadingPengajaran = true;
    notifyListeners();

    try {
      String kodeDosenLogin = currentDosen.kodeDosen;
      listPengajaran = _pengajaranRepo.getLocalPengajaran(kodeDosenLogin);

      if (listPengajaran.isNotEmpty && !isDisposed) {
        await _generateUniqueMatkul(); // 🔥 Await agar matkul asli tercari
        if (taskToEdit != null) await _initDropdownsForEdit(taskToEdit);
        notifyListeners();
      }

      await _pengajaranRepo.syncPengajaran(kodeDosenLogin);
      final updatedList = _pengajaranRepo.getLocalPengajaran(kodeDosenLogin);

      if (!isDisposed && (updatedList.length != listPengajaran.length || listPengajaran.isEmpty)) {
        listPengajaran = updatedList;
        await _generateUniqueMatkul(); // 🔥 Await agar matkul asli tercari
        if (taskToEdit != null) await _initDropdownsForEdit(taskToEdit);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading pengajaran: $e');
    } finally {
      if (!isDisposed) {
        isLoadingPengajaran = false;
        notifyListeners();
      }
    }
  }

  // 🔥 FUNGSI DIUBAH: Mencari nama asli jika datanya berupa KODE - KODE
  Future<void> _generateUniqueMatkul() async {
    Set<String> tempMatkul = {};

    for (var p in listPengajaran) {
      String realName = p.namaMk;

      // Jika namanya aneh (sama dengan kode mk), kita cari di master data!
      if (p.namaMk == p.kodeMk || p.namaMk.isEmpty) {
        if (_matkulRealNames.containsKey(p.kodeMk)) {
          realName = _matkulRealNames[p.kodeMk]!;
        } else {
          try {
            final masterMk = await MongoDatabase.db.collection('mata_kuliah').findOne(
              where.eq('kode_mk', p.kodeMk.trim())
            );
            if (masterMk != null && masterMk['nama_mk'] != null) {
              realName = masterMk['nama_mk'].toString();
              _matkulRealNames[p.kodeMk] = realName;
            }
          } catch (e) {
            print("Error fetch real matkul name: $e");
          }
        }
      } else {
        _matkulRealNames[p.kodeMk] = p.namaMk;
      }
      
      tempMatkul.add("${p.kodeMk} - $realName");
    }

    uniqueMatkulList = tempMatkul.toList();
  }

  Future<void> _initDropdownsForEdit(TaskModel task) async {
    try {
      final int matchIndex = listPengajaran.indexWhere((p) {
        return task.kodeMk == p.kodeMk;
      });

      if (matchIndex == -1) return;

      final matched = listPengajaran[matchIndex];
      String realName = _matkulRealNames[matched.kodeMk] ?? matched.namaMk;
      selectedMatkulDisplay = "${matched.kodeMk} - $realName";

      await _updateAvailableKelas();

      List<String> loadedKelasNames = [];

      if (task.targetKelas != null && task.targetKelas!.isNotEmpty) {
        for (String idKelas in task.targetKelas!) {
            String name = await _resolveNamaKelas(idKelas);
            loadedKelasNames.add(name);
        }
      } 
      
      selectedTargetKelas = loadedKelasNames.where((k) => availableKelasList.contains(k)).toSet().toList();
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

  Future<void> _updateAvailableKelas() async {
    if (selectedMatkulDisplay == null) {
      availableKelasList = [];
      _kelasNameToIdMap.clear();
      notifyListeners();
      return;
    }

    // Ambil KODE MK dari dropdown (Misal dari "25IF1107 - Pemrograman", kita ambil "25IF1107")
    String kodeMkSelected = selectedMatkulDisplay!.split(' - ').first.trim();
    final matchedDocs = listPengajaran.where((p) => p.kodeMk == kodeMkSelected);

    Set<String> tempKelasNames = {};
    _kelasNameToIdMap.clear();

    for (var doc in matchedDocs) {
      for (var id in doc.targetKelas) {
        String nama = await _resolveNamaKelas(id);
        tempKelasNames.add(nama);
        _kelasNameToIdMap[nama] = id; 
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
      String kodeMkSelected = selectedMatkulDisplay!.split(' - ').first.trim();
      return listPengajaran.firstWhere((p) => p.kodeMk == kodeMkSelected);
    } catch (_) {
      return null;
    }
  }

  // ==================== LAMPIRAN & UPLOAD ====================
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false, withData: false);
      if (result != null) return result.files.single;
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  // =========================================================================
  // FUNGSI CREATE 
  // =========================================================================
  Future<bool> createTaskForStudents(UserModel currentUser) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null || selectedTargetKelas.isEmpty) return false;

    final matched = _getMatchedPengajaran();
    if (matched == null) return false;

    final String cleanUserId = currentUser.id.replaceAll(RegExp(r'ObjectId\(|"|\)'), '');
    final String newTaskId = ObjectId().toHexString();

    List<String> idsUntukDatabase = selectedTargetKelas
        .map((nama) => _kelasNameToIdMap[nama] ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // 🔥 Gunakan nama bersih yang sudah dicegat
    String namaRealMatkul = _matkulRealNames[matched.kodeMk] ?? matched.namaMk;

    final newTask = TaskModel(
      id: newTaskId,
      idUser: cleanUserId,
      namaTugas: namaTugasController.text,
      deskripsi: deskripsiController.text.isNotEmpty ? deskripsiController.text : null,
      kodeMk: matched.kodeMk,
      namaMkSnapshot: namaRealMatkul, // Menyimpan nama matkul yang bersih
      deadline: selectedDeadline!,
      status: 'BELUM',
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lampiran: lampiran.isNotEmpty ? lampiran : null,
      targetKelas: idsUntukDatabase, 
      namaDosen: currentUser.nama,
    );

    try {
      final taskBox = Hive.box<TaskModel>('tasks');
      await taskBox.put(newTaskId, newTask);
      _backgroundSync(newTask, isCreate: true);
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ Error Create: $e");
      return false;
    }
  }

  // =========================================================================
  // FUNGSI EDIT 
  // =========================================================================
  Future<bool> updateTaskForStudents(TaskModel taskLama, UserModel currentUser) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null || selectedTargetKelas.isEmpty) return false;

    final matched = _getMatchedPengajaran();
    if (matched == null) return false;

    try {
      final taskBox = Hive.box<TaskModel>('tasks');

      final listTugasSejenis = taskBox.values.where((t) {
        bool isNameSame = t.namaTugas == taskLama.namaTugas;
        bool isTimeSame = t.deadline.year == taskLama.deadline.year &&
                          t.deadline.month == taskLama.deadline.month &&
                          t.deadline.day == taskLama.deadline.day &&
                          t.deadline.hour == taskLama.deadline.hour &&
                          t.deadline.minute == taskLama.deadline.minute;
        bool isMatkulSame = t.kodeMk == taskLama.kodeMk;
        return isNameSame && isTimeSame && isMatkulSame;
      }).toList();

      if (listTugasSejenis.isEmpty) return false;

      List<String> idsUntukDatabase = selectedTargetKelas
          .map((nama) => _kelasNameToIdMap[nama] ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // 🔥 Gunakan nama bersih yang sudah dicegat
      String namaRealMatkul = _matkulRealNames[matched.kodeMk] ?? matched.namaMk;

      TaskModel tToUpdate = listTugasSejenis[0];
      
      tToUpdate.namaTugas = namaTugasController.text;
      tToUpdate.deskripsi = deskripsiController.text.isNotEmpty ? deskripsiController.text : null;
      tToUpdate.kodeMk = matched.kodeMk;
      tToUpdate.namaMkSnapshot = namaRealMatkul; 
      tToUpdate.deadline = selectedDeadline!;
      tToUpdate.lampiran = lampiran.isNotEmpty ? lampiran : null;
      tToUpdate.updatedAt = DateTime.now();
      tToUpdate.isSynced = false;
      tToUpdate.targetKelas = idsUntukDatabase; 
      tToUpdate.namaDosen = currentUser.nama;

      await tToUpdate.save();
      _backgroundSync(tToUpdate, isCreate: false);

      for (int i = 1; i < listTugasSejenis.length; i++) {
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
      bool isOnline = !(connectivityResult as List).contains(ConnectivityResult.none);

      if (isOnline) {
        bool cloudSuccess = isCreate ? await _taskService.createTask(task) : await _taskService.updateTask(task);
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
    isDisposed = true;
    namaTugasController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }
}