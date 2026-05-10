import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/models/mata_kuliah_model.dart';
import '../../../../data/services/task_service.dart';
import '../../../../data/services/mata_kuliah_service.dart';

class TaskFormViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final MataKuliahService _mataKuliahService = MataKuliahService();

  // Form controllers
  final TextEditingController namaTugasController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  String? selectedMatkul;
  DateTime? selectedDeadline;
  List<Map<String, String>> lampiran = [];

  // Mata kuliah options
  List<MataKuliahModel> matkulList = [];
  bool isLoadingMatkul = false;

  // Initialize form for editing
  void initializeForEdit(TaskModel? task) {
    if (task != null) {
      namaTugasController.text = task.namaTugas;
      deskripsiController.text = task.deskripsi ?? '';
      selectedMatkul = task.namaMkSnapshot;
      selectedDeadline = task.deadline;
      lampiran = task.lampiran ?? [];
    }
  }

  // Load mata kuliah dari database
  Future<void> loadMataKuliah(String? idJurusan, String? idProdi) async {
    isLoadingMatkul = true;
    notifyListeners();

    try {
      if (idJurusan != null && idJurusan.isNotEmpty) {
        matkulList = await _mataKuliahService.getMataKuliahByJurusan(idJurusan);
      } else if (idProdi != null && idProdi.isNotEmpty) {
        matkulList = await _mataKuliahService.getMataKuliahByProdi(idProdi);
      } else {
        matkulList = await _mataKuliahService.getAllMataKuliah();
      }
    } catch (e) {
      print('Error loading mata kuliah: $e');
      matkulList = [];
    }

    isLoadingMatkul = false;
    notifyListeners();
  }

  // Add attachment
  void addAttachment(String type, String title, String uri) {
    lampiran.add({'type': type, 'title': title, 'uri': uri});
    notifyListeners();
  }

  // Remove attachment
  void removeAttachment(int index) {
    lampiran.removeAt(index);
    notifyListeners();
  }

  Future<PlatformFile?> pickFile() async {
    try {
      // 1. CEK DAN MINTA IZIN AKSES STORAGE / MEDIA
      if (Platform.isAndroid || Platform.isIOS) {
        // Izin untuk Android 12 ke bawah
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }

        // Izin untuk Android 13 ke atas (menggunakan media photos/videos)
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          await Permission.photos.request();
        }
      }

      // 2. BUKA SISTEM FILE MANAGER BAWAAN HP
      // Kita kembalikan ke FileType.any agar sistem HP tidak crash (invalid_format_type)
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        // withData di-set false agar aplikasi tidak kehabisan RAM saat memilih file besar
        withData: false,
      );

      if (result != null) {
        return result.files.single;
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  // Create task for students
  Future<bool> createTaskForStudents(String dosenId) async {
    print(
      '\n🔵 [TaskFormVM] createTaskForStudents called with dosenId: $dosenId',
    );

    if (namaTugasController.text.isEmpty || selectedDeadline == null) {
      print('❌ [TaskFormVM] Validation failed - empty name or no deadline');
      return false;
    }

    final newId = ObjectId().toHexString();
    print('📝 [TaskFormVM] New task ID: $newId');

    final newTask = TaskModel(
      id: newId,
      idUser: dosenId,
      namaTugas: namaTugasController.text,
      deskripsi: deskripsiController.text.isNotEmpty
          ? deskripsiController.text
          : null,
      idMk: null,
      namaMkSnapshot: selectedMatkul,
      deadline: selectedDeadline!,
      status: 'BELUM',
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lampiran: lampiran.isNotEmpty ? lampiran : null,
    );

    print(
      '📦 [TaskFormVM] Task to save: ${newTask.namaTugas} for user: ${newTask.idUser}',
    );

    // Save to local Hive first
    try {
      final taskBox = await Hive.openBox<TaskModel>('tasks');
      await taskBox.put(newId, newTask);
      print('✅ [TaskFormVM] Task saved to Hive - box size: ${taskBox.length}');
    } catch (e) {
      print('❌ [TaskFormVM] Error saving to Hive: $e');
      return false;
    }

    // Sync to MongoDB if online
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

    if (!isOffline) {
      bool success = await _taskService.createTask(newTask);
      if (success) {
        newTask.isSynced = true;
        final taskBox = await Hive.openBox<TaskModel>('tasks');
        await taskBox.put(newId, newTask);
        print('✅ [TaskFormVM] Task synced to MongoDB');
        return true;
      }
    } else {
      print('🔌 [TaskFormVM] Offline mode - task saved locally only');
    }

    return true;
  }

  // Update task for students
  Future<bool> updateTaskForStudents(TaskModel task) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null) {
      return false;
    }

    task.namaTugas = namaTugasController.text;
    task.deskripsi = deskripsiController.text.isNotEmpty
        ? deskripsiController.text
        : null;
    task.namaMkSnapshot = selectedMatkul;
    task.deadline = selectedDeadline!;
    task.lampiran = lampiran.isNotEmpty ? lampiran : null;
    task.updatedAt = DateTime.now();

    // Save to local Hive first
    final taskBox = await Hive.openBox<TaskModel>('tasks');
    await taskBox.put(task.id, task);

    // Sync to MongoDB if online
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

    if (!isOffline) {
      bool success = await _taskService.updateTask(task);
      if (success) {
        task.isSynced = true;
        await taskBox.put(task.id, task); // Update synced status
        return true;
      }
    }

    return true; // Return true since saved locally
  }

  // Clear form
  void clearForm() {
    namaTugasController.clear();
    deskripsiController.clear();
    selectedMatkul = null;
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
