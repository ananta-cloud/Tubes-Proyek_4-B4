import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/models/pengajaran_model.dart';
import '../../../../data/repositories/pengajaran_repository.dart';
import '../../../../data/services/task_service.dart';

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

  void initializeForEdit(TaskModel? task) {
    if (task != null) {
      namaTugasController.text = task.namaTugas;
      deskripsiController.text = task.deskripsi ?? '';
      selectedDeadline = task.deadline;
      lampiran = task.lampiran ?? [];
    }
  }

  Future<void> loadPengajaran(String idDosen, {TaskModel? taskToEdit}) async {
    isLoadingPengajaran = true;
    notifyListeners();

    try {
      listPengajaran = _pengajaranRepo.getLocalPengajaran(idDosen);
      _generateUniqueMatkul();
      if (taskToEdit != null) _initDropdownsForEdit(taskToEdit);
      notifyListeners();

      await _pengajaranRepo.syncPengajaran(idDosen);

      listPengajaran = _pengajaranRepo.getLocalPengajaran(idDosen);
      _generateUniqueMatkul();
      if (taskToEdit != null) _initDropdownsForEdit(taskToEdit);
    } catch (e) {
      print('Error loading pengajaran: $e');
    }

    isLoadingPengajaran = false;
    notifyListeners();
  }

  void _generateUniqueMatkul() {
    uniqueMatkulList = listPengajaran
        .map((p) => "${p.kodeMk} - ${p.namaMk}")
        .toSet()
        .toList();
  }

  // ====================================================================
  // PERBAIKAN: MEMBACA SEMUA TUGAS KELOMPOK UNTUK CENTANG BIRU
  // ====================================================================
  void _initDropdownsForEdit(TaskModel task) {
    try {
      final matched = listPengajaran.firstWhere((p) => p.id == task.idMk);
      selectedMatkulDisplay = "${matched.kodeMk} - ${matched.namaMk}";
      _updateAvailableKelas();
      
      // Cari SEMUA tugas yang tergabung dalam 1 grup (nama & deadline sama)
      final taskBox = Hive.box<TaskModel>('tasks');
      final listTugasSejenis = taskBox.values.where((t) => 
        t.namaTugas == task.namaTugas && 
        t.deadline.isAtSameMomentAs(task.deadline) &&
        t.idMk == task.idMk
      );

      List<String> semuaKelasTercentang = [];
      
      for (var t in listTugasSejenis) {
        if (t.namaMkSnapshot != null && t.namaMkSnapshot!.contains('(')) {
          String kelas = t.namaMkSnapshot!.split('(').last.replaceAll(')', '').trim();
          if (availableKelasList.contains(kelas) && !semuaKelasTercentang.contains(kelas)) {
            semuaKelasTercentang.add(kelas);
          }
        }
      }

      // Masukkan ke List State UI agar menyala biru di form!
      selectedTargetKelas = semuaKelasTercentang;
    } catch (_) {}
  }

  void selectMatkul(String? matkulDisplay) {
    selectedMatkulDisplay = matkulDisplay;
    selectedTargetKelas = [];
    _updateAvailableKelas();
    notifyListeners();
  }

  void _updateAvailableKelas() {
    if (selectedMatkulDisplay == null) {
      availableKelasList = [];
    } else {
      try {
        final matchedDocs = listPengajaran.where(
          (p) => "${p.kodeMk} - ${p.namaMk}" == selectedMatkulDisplay,
        );

        Set<String> combinedKelas = {};
        for (var doc in matchedDocs) {
          combinedKelas.addAll(doc.targetKelas);
        }
        availableKelasList = combinedKelas.toList();
      } catch (e) {
        availableKelasList = [];
      }
    }
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

      // 2. BUKA SISTEM FILE MANAGER BAWAAN HP
      // Kita kembalikan ke FileType.any agar sistem HP tidak crash (invalid_format_type)
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

  Future<bool> createTaskForStudents(String userId) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null || selectedTargetKelas.isEmpty) return false;

    final matched = _getMatchedPengajaran();
    if (matched == null) return false;

    final String cleanUserId = userId.replaceAll('ObjectId("', '').replaceAll('")', '');
    bool allSuccess = true;

    for (String kelas in selectedTargetKelas) {
      final String newTaskId = ObjectId().toHexString();
      final newTask = TaskModel(
        id: newTaskId,
        idUser: cleanUserId,
        namaTugas: namaTugasController.text,
        deskripsi: deskripsiController.text.isNotEmpty ? deskripsiController.text : null,
        idMk: matched.id,
        namaMkSnapshot: "${matched.kodeMk} - ${matched.namaMk} ($kelas)",
        deadline: selectedDeadline!,
        status: 'BELUM',
        isSynced: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lampiran: lampiran.isNotEmpty ? lampiran : null,
      );

      try {
        final taskBox = Hive.box<TaskModel>('tasks');
        await taskBox.put(newTaskId, newTask);
        _backgroundSync(newTask, isCreate: true);
      } catch (e) {
        allSuccess = false;
      }
    }
    notifyListeners();
    return allSuccess;
  }

  // ====================================================================
  // PERBAIKAN: EDIT TUGAS DENGAN LOGIKA TAMBAH/HAPUS CENTANG
  // ====================================================================
  Future<bool> updateTaskForStudents(TaskModel taskLama) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null || selectedTargetKelas.isEmpty) return false;

    final matched = _getMatchedPengajaran();
    if (matched == null) return false;

    try {
      final taskBox = Hive.box<TaskModel>('tasks');

      // 1. Kumpulkan semua tugas lama di grup ini
      final listTugasSejenis = taskBox.values.where((t) =>
          t.namaTugas == taskLama.namaTugas &&
          t.deadline.isAtSameMomentAs(taskLama.deadline) &&
          t.idMk == taskLama.idMk).toList();

      Map<String, TaskModel> existingTasksByClass = {};
      for (var t in listTugasSejenis) {
        if (t.namaMkSnapshot != null && t.namaMkSnapshot!.contains('(')) {
          String kelas = t.namaMkSnapshot!.split('(').last.replaceAll(')', '').trim();
          existingTasksByClass[kelas] = t;
        }
      }

      // 2. Cek setiap kelas yang DI-CENTANG oleh Dosen
      for (String kelas in selectedTargetKelas) {
        if (existingTasksByClass.containsKey(kelas)) {
          // A. Jika kelas sudah ada, UPDATE TUGASNYA
          TaskModel tToUpdate = existingTasksByClass[kelas]!;
          tToUpdate.namaTugas = namaTugasController.text;
          tToUpdate.deskripsi = deskripsiController.text.isNotEmpty ? deskripsiController.text : null;
          tToUpdate.idMk = matched.id;
          tToUpdate.namaMkSnapshot = "${matched.kodeMk} - ${matched.namaMk} ($kelas)";
          tToUpdate.deadline = selectedDeadline!;
          tToUpdate.lampiran = lampiran.isNotEmpty ? lampiran : null;
          tToUpdate.updatedAt = DateTime.now();
          tToUpdate.isSynced = false;

          await tToUpdate.save();
          _backgroundSync(tToUpdate, isCreate: false);

          existingTasksByClass.remove(kelas); // Buang dari daftar pengecekan
        } else {
          // B. Jika Dosen mencentang kelas BARU, BUAT TUGAS BARU untuk kelas tersebut
          final String newTaskId = ObjectId().toHexString();
          final newTask = TaskModel(
            id: newTaskId,
            idUser: taskLama.idUser,
            namaTugas: namaTugasController.text,
            deskripsi: deskripsiController.text.isNotEmpty ? deskripsiController.text : null,
            idMk: matched.id,
            namaMkSnapshot: "${matched.kodeMk} - ${matched.namaMk} ($kelas)",
            deadline: selectedDeadline!,
            status: 'BELUM',
            isSynced: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            lampiran: lampiran.isNotEmpty ? lampiran : null,
          );
          await taskBox.put(newTaskId, newTask);
          _backgroundSync(newTask, isCreate: true);
        }
      }

      // 3. Hapus sisa tugas lama jika Dosen HILANGKAN CENTANG kelas tersebut
      for (var tToDelete in existingTasksByClass.values) {
        await taskBox.delete(tToDelete.id);
        _taskService.deleteTask(tToDelete.id); // Hapus juga dari database server!
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