import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../../../../data/models/task_model.dart';
import '../../../../../data/services/task_service.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  // Pastikan nama kotaknya 'tasks' sesuai dengan yang ada di main.dart
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');

  List<TaskModel> get tasks {
    final list = _taskBox.values.toList();
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  // 1. SINKRONISASI (Tarik Tugas dari Cloud saat Buka Aplikasi)
  Future<void> syncTasks(String currentUserId) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

    if (isOffline)
      return; // Jika offline, abaikan. Biarkan UI pakai data lokal.

    try {
      // Jemput data segar dari MongoDB
      final List<Map<String, dynamic>> mongoTasks = await _taskService
          .getTasksByUser(currentUserId);

      // Bersihkan data Hive lama agar tidak ada tugas hantu yang sudah dihapus dari device lain
      await _taskBox.clear();

      // Masukkan data segar ke Hive
      for (var item in mongoTasks) {
        final task = TaskModel.fromMongo(item);
        await _taskBox.put(task.id, task);
      }
      notifyListeners();
    } catch (e) {
      print("🔥 ERROR SINKRONISASI TUGAS: $e");
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
      idMk: null, // Null menandakan ini Tugas Personal!
      namaMkSnapshot: matkul, // Kita gunakan ini sebagai label
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

    // ⚡ UPDATE LOKAL DULU
    task.status = newStatus;
    task.updatedAt = DateTime.now();
    await task.save();
    notifyListeners();

    // ☁️ UPDATE KE MONGODB
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);

    if (!isOffline) {
      await _taskService.updateTaskStatus(task.id, newStatus);
    }
  }

  // 4. HAPUS TUGAS PERSONAL
  Future<void> deleteTask(TaskModel task) async {
    // 🛡️ KEAMANAN: Pastikan yang dihapus BUKAN tugas dari dosen
    if (!task.isPersonal) return;

    final taskId = task.id; // Simpan ID sebelum dihapus dari lokal

    // ⚡ HAPUS DARI LOKAL
    await task.delete();
    notifyListeners();

    // ☁️ HAPUS DARI MONGODB
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
    if (!task.isPersonal) return; // Hanya boleh edit tugas personal

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
}
