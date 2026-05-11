import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/models/pengajaran_model.dart'; // IMPORT BARU
import '../../../../data/repositories/pengajaran_repository.dart'; // IMPORT BARU
import '../../../../data/services/task_service.dart';

class TaskFormViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final PengajaranRepository _pengajaranRepo = PengajaranRepository();

  // Form controllers
  final TextEditingController namaTugasController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();

  // Variabel untuk Dropdown Pengajaran
  PengajaranModel? selectedPengajaran;
  DateTime? selectedDeadline;
  List<Map<String, String>> lampiran = [];

  // List Pengajaran (Matkul + Kelas)
  List<PengajaranModel> listPengajaran = [];
  bool isLoadingPengajaran = false;

  // Initialize form for editing
  void initializeForEdit(TaskModel? task) {
    if (task != null) {
      namaTugasController.text = task.namaTugas;
      deskripsiController.text = task.deskripsi ?? '';
      selectedDeadline = task.deadline;
      lampiran = task.lampiran ?? [];

      // Catatan: selectedPengajaran akan di-set di UI atau setelah data listPengajaran ter-load
      // agar referensi objek Dropdown-nya valid.
    }
  }

  // =========================================================================
  // LOGIKA BARU: LOAD PENGAJARAN (OFFLINE-FIRST)
  // =========================================================================
  Future<void> loadPengajaran(String idDosen) async {
    isLoadingPengajaran = true;
    notifyListeners();

    try {
      // 1. Ambil dari lokal (Hive) dulu agar UI instan merender Dropdown
      listPengajaran = _pengajaranRepo.getLocalPengajaran(idDosen);
      notifyListeners();

      // 2. Tarik data terbaru dari server di background
      await _pengajaranRepo.syncPengajaran(idDosen);

      // 3. Update list setelah sync selesai agar UI mengikuti data Cloud terbaru
      listPengajaran = _pengajaranRepo.getLocalPengajaran(idDosen);
    } catch (e) {
      print('Error loading pengajaran: $e');
    }

    isLoadingPengajaran = false;
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
      if (Platform.isAndroid || Platform.isIOS) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }

        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          await Permission.photos.request();
        }
      }

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
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
  Future<bool> createTaskForStudents(String userId) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null)
      return false;

    final String newTaskId = ObjectId().toHexString();
    final String cleanUserId = userId
        .replaceAll('ObjectId("', '')
        .replaceAll('")', '');

    final newTask = TaskModel(
      id: newTaskId,
      idUser: cleanUserId,
      namaTugas: namaTugasController.text,
      deskripsi: deskripsiController.text.isNotEmpty
          ? deskripsiController.text
          : null,

      // KITA SIMPAN ID PENGAJARAN (Junction) KE DALAM DATABASE TUGAS
      // Pastikan di TaskModel Anda, "idMk" sudah direfaktor menjadi "idPengajaran"
      idMk: selectedPengajaran?.id,

      // Simpan Snapshot informatif (Misal: "Proyek 4 - 2B-D3")
      namaMkSnapshot: selectedPengajaran != null
          ? "${selectedPengajaran!.namaMk} - ${selectedPengajaran!.targetKelas}"
          : null,

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
      notifyListeners();

      _backgroundSync(newTask, isCreate: true);
      return true;
    } catch (e) {
      print("❌ Error Create: $e");
      return false;
    }
  }

  Future<bool> updateTaskForStudents(TaskModel task) async {
    if (namaTugasController.text.isEmpty || selectedDeadline == null)
      return false;

    task.namaTugas = namaTugasController.text;
    task.deskripsi = deskripsiController.text.isNotEmpty
        ? deskripsiController.text
        : null;

    // UPDATE REFERENSI PENGAJARAN
    task.idMk = selectedPengajaran?.id;
    task.namaMkSnapshot = selectedPengajaran != null
        ? "${selectedPengajaran!.namaMk} - ${selectedPengajaran!.targetKelas}"
        : null;

    task.deadline = selectedDeadline!;
    task.lampiran = lampiran.isNotEmpty ? lampiran : null;
    task.updatedAt = DateTime.now();
    task.isSynced = false;

    try {
      await task.save();
      notifyListeners();

      _backgroundSync(task, isCreate: false);
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
    selectedPengajaran = null; // Clear state pengajaran
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
