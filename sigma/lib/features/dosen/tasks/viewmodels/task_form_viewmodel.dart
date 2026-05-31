import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/dosen_model.dart';
import '../../../../data/models/pengajaran_model.dart';
import '../../../../data/repositories/pengajaran_repository.dart';
import '../../../../data/services/task_service.dart';
import '../../../../data/services/pengajaran_service.dart';
import '../../../../core/network/mongo_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

    final cacheBox = Hive.box<String>('kelasCacheBox');
    if (cacheBox.containsKey(idKelasHex)) {
      String cachedName = cacheBox.get(idKelasHex)!;
      _kelasCacheNames[idKelasHex] = cachedName;
      return cachedName;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);
      
      if (isOffline || MongoDatabase.isOffline) {
         return "Kelas (${idKelasHex.substring(0, 4)})";
      }

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
        await cacheBox.put(idKelasHex, name);
        
        return name;
      }
      return "Unknown";
    } catch (e) {
      return "Kelas (${idKelasHex.substring(0, 4)})";
    }
  }

  Future<void> loadPengajaran(DosenModel currentDosen, {TaskModel? taskToEdit}) async {
    if (isDisposed) return;
    
    // 🔥 PERBAIKAN: Hanya tampilkan indikator loading jika memori benar-benar masih kosong
    if (listPengajaran.isEmpty) {
      isLoadingPengajaran = true;
      notifyListeners();
    }

    try {
      String kodeDosenLogin = currentDosen.kodeDosen;
      
      // 1. Tarik dari Memori Lokal (Instan)
      listPengajaran = _pengajaranRepo.getLocalPengajaran(kodeDosenLogin);

      if (listPengajaran.isNotEmpty && !isDisposed) {
        await _generateUniqueMatkul();
        if (taskToEdit != null) await _initDropdownsForEdit(taskToEdit);
        
        // Matikan loading karena data lokal sudah siap dipakai
        isLoadingPengajaran = false;
        notifyListeners();
      }

      // 2. Tarik dari MongoDB (Background Sync / Diam-diam)
      await _pengajaranRepo.syncPengajaran(kodeDosenLogin);
      final updatedList = _pengajaranRepo.getLocalPengajaran(kodeDosenLogin);

      // 3. Update UI hanya jika ada kelas/mata kuliah baru dari server
      if (!isDisposed && (updatedList.length != listPengajaran.length || listPengajaran.isEmpty)) {
        listPengajaran = updatedList;
        await _generateUniqueMatkul();
        if (taskToEdit != null) await _initDropdownsForEdit(taskToEdit);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading pengajaran: $e');
    } finally {
      if (!isDisposed) {
        isLoadingPengajaran = false;
        notifyListeners();
      }
    }
  }

  Future<void> _generateUniqueMatkul() async {
    Set<String> tempMatkul = {};
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);

    for (var p in listPengajaran) {
      String realName = p.namaMk;
      if (p.namaMk == p.kodeMk || p.namaMk.isEmpty) {
        if (_matkulRealNames.containsKey(p.kodeMk)) {
          realName = _matkulRealNames[p.kodeMk]!;
        } else if (!isOffline) {
          try {
            final masterMk = await MongoDatabase.db
                .collection('mata_kuliah')
                .findOne(where.eq('kode_mk', p.kodeMk.trim()));
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
      final int matchIndex = listPengajaran.indexWhere((p) => task.kodeMk == p.kodeMk);
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

  void removeAttachment(int index) {
    lampiran.removeAt(index);
    notifyListeners();
  }

  // 🔥 PERBAIKAN UTAMA: Konversi ke Base64 (Null & Size Safe)
  Future<String?> pickFileAndConvert() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        final platformFile = result.files.single;
        
        // Cek ukuran max 5MB agar MongoDB tidak kepenuhan
        final fileSizeInMB = platformFile.size / (1024 * 1024);
        if (fileSizeInMB > 5.0) {
            return 'Ukuran file terlalu besar! Maksimal 5MB.';
        }

        File file = File(platformFile.path!);
        String fileName = platformFile.name;

        // 1. Baca file & 2. Konversi ke Base64
        List<int> fileBytes = await file.readAsBytes();
        String base64Data = base64Encode(fileBytes);

        // 3. Simpan Base64 ke array Lampiran 
        lampiran.add({
          'type': 'file',
          'name': fileName,
          'data': base64Data, // Data yang akan di-save ke MongoDB
          'size': platformFile.size.toString(),
          'uri': platformFile.path ?? '', // Opsi path lokal (Jaga-jaga)
        });

        notifyListeners();
        return null; // Tidak ada error
      }
    } catch (e) {
      print("Error picking file: $e");
      return "Gagal membaca file: $e";
    }
    return null;
  }

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

    String namaRealMatkul = _matkulRealNames[matched.kodeMk] ?? matched.namaMk;

    final newTask = TaskModel(
      id: newTaskId,
      idUser: cleanUserId,
      namaTugas: namaTugasController.text,
      deskripsi: deskripsiController.text.isNotEmpty ? deskripsiController.text : null,
      kodeMk: matched.kodeMk,
      namaMkSnapshot: namaRealMatkul,
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
      debugPrint("❌ Error Create Task: $e");
      return false;
    }
  }

  Future<bool> updateTaskForStudents(TaskModel taskLama, UserModel currentUser) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null || selectedTargetKelas.isEmpty) return false;

    final matched = _getMatchedPengajaran();
    if (matched == null) return false;

    try {
      final taskBox = Hive.box<TaskModel>('tasks');

      taskLama.namaTugas = namaTugasController.text;
      taskLama.deskripsi = deskripsiController.text.isNotEmpty ? deskripsiController.text : null;
      taskLama.kodeMk = matched.kodeMk;
      taskLama.namaMkSnapshot = _matkulRealNames[matched.kodeMk] ?? matched.namaMk;
      taskLama.deadline = selectedDeadline!;
      taskLama.lampiran = lampiran.isNotEmpty ? lampiran : null;
      taskLama.updatedAt = DateTime.now();
      taskLama.targetKelas = selectedTargetKelas.map((n) => _kelasNameToIdMap[n]!).toList();
      taskLama.isSynced = false;

      await taskBox.put(taskLama.id, taskLama);
      _backgroundSync(taskLama, isCreate: false);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Error Update Task: $e");
      return false;
    }
  }

  Future<void> _backgroundSync(TaskModel task, {required bool isCreate}) async {
    try {
      final result = await Connectivity().checkConnectivity();
      bool isOnline = !(result as List).contains(ConnectivityResult.none);

      if (isOnline) {
        bool cloudSuccess = isCreate
            ? await _taskService.createTask(task)
            : await _taskService.updateTask(task);

        if (cloudSuccess) {
          task.isSynced = true;
          final taskBox = Hive.box<TaskModel>('tasks');
          await taskBox.put(task.id, task);
          notifyListeners(); 
        }
      }
    } catch (e) {
      debugPrint("☁️ Background Sync Error: $e");
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