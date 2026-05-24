import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../../../data/models/task_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/task_service.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  // Pastikan nama kotaknya 'tasks' sesuai dengan yang ada di main.dart
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');

  List<TaskModel> get tasks {
    final list = _taskBox.values.toList();
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  // 1. SINKRONISASI (Ubah parameter menjadi UserModel)
  Future<void> syncTasks(UserModel user) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);

    // 🔥 PENTING: Eksekusi antrean offline terlebih dahulu jika ada sinyal!
    if (!isOffline) {
      await syncOfflineTaskActions();
    } else {
      return; // Jika offline, berhenti di sini (tampilkan data lokal)
    }

    try {
      final String idKelasMahasiswa = user.profilMahasiswa?.idKelas ?? '';
      final List<Map<String, dynamic>> mongoTasks = await _taskService
          .getTasksForMahasiswa(user.id, idKelasMahasiswa);

      List<String> mongoIds = [];
      for (var item in mongoTasks) {
        final task = TaskModel.fromMongo(item);
        mongoIds.add(task.id);

        if (!task.isPersonal) {
          final localTask = _taskBox.get(task.id);
          if (localTask != null) {
            task.status = localTask.status; 
          }
        }
        await _taskBox.put(task.id, task);
      }

      final localIds = _taskBox.keys.cast<String>().toList();
      for (var id in localIds) {
        if (!mongoIds.contains(id)) {
          await _taskBox.delete(id);
        }
      }
      
      notifyListeners();
    } catch (e) {
      print("ERROR SINKRONISASI TUGAS: $e");
    }
  }

  // 2. TAMBAH TUGAS PERSONAL
  Future<void> addPersonalTask({
    required String userId,
    required String namaTugas,
    String? matkul,
    required DateTime deadline,
  }) async {
    final newId = ObjectId().toHexString();
    
    final newTask = TaskModel(
      id: newId,
      idUser: userId,
      namaTugas: namaTugas,
      deskripsi: null, 
      idMk: null,
      namaMkSnapshot: matkul,
      deadline: deadline,
      status: 'BELUM',
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Simpan ke Lokal
    await _taskBox.put(newTask.id, newTask);
    notifyListeners();

    // Sync ke MongoDB
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);
    if (!isOffline) {
      bool success = await _taskService.createTask(newTask);
      if (success) {
        newTask.isSynced = true;
        await newTask.save(); 
      }
    }
  }

  // 3. UBAH STATUS (Selesai / Belum)
  Future<void> toggleStatus(TaskModel task) async {
    final newStatus = task.status == 'BELUM' ? 'SELESAI' : 'BELUM';

    // ⚡ Optimistic UI: Langsung ubah di layar
    task.status = newStatus;
    task.updatedAt = DateTime.now();
    await task.save();
    notifyListeners();

    // ☁️ Update ke MongoDB (Hanya tugas personal)
    if (task.isPersonal) {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);

      if (isOffline) {
        // 🔥 Jika Offline, masukkan ke Antrean!
        final queueBox = Hive.box('student_action_queue');
        await queueBox.add({
          'action': 'update_task_status',
          'task_id': task.id,
          'status': newStatus,
        });
        print("Tugas tersimpan di antrean offline.");
        return;
      }

      // Jika Online, eksekusi langsung
      try {
        await _taskService.updateTaskStatus(task.id, newStatus);
      } catch (e) {
        print("Gagal update status tugas: $e");
      }
    }
  }

  // 4. HAPUS TUGAS PERSONAL
  Future<void> deleteTask(TaskModel task) async {
    if (!task.isPersonal) return;

    final taskId = task.id;

    await task.delete();
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);

    if (!isOffline) {
      await _taskService.deleteTask(taskId);
    }
  }

  // 5. UPDATE / EDIT TUGAS PERSONAL
  Future<void> updatePersonalTask({
    required TaskModel task,
    required String namaTugas,
    String? matkul,
    required DateTime deadline,
  }) async {
    if (!task.isPersonal) return;

    // Update Lokal
    task.namaTugas = namaTugas;
    task.namaMkSnapshot = matkul;
    task.deadline = deadline;
    task.updatedAt = DateTime.now();
    task.isSynced = false;
    
    await task.save();
    notifyListeners();

    // Sync ke MongoDB
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);
    if (!isOffline) {
      bool success = await _taskService.updateTask(task);
      if (success) {
        task.isSynced = true;
        await task.save();
      }
    }
  }

  Future<void> syncOfflineTaskActions() async {
    final queueBox = Hive.box('student_action_queue');
    if (queueBox.isEmpty) return;

    print("🔄 Menjalankan sinkronisasi aksi TUGAS offline...");

    final keys = queueBox.keys.toList();
    for (var key in keys) {
      final item = queueBox.get(key);
      
      // Ambil aksi yang khusus untuk Tugas
      if (item['action'] == 'update_task_status') {
        try {
          await _taskService.updateTaskStatus(item['task_id'], item['status']);
          await queueBox.delete(key); // Hapus dari antrean jika sukses
        } catch (e) {
          print("Gagal sync antrean tugas: $e");
        }
      }
    }
  }
}
