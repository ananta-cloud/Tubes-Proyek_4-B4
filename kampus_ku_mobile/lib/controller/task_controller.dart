import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId; // Import ini untuk buat ID
import '../data/models/task_model.dart';
import '../data/services/task_service.dart';

class TaskController extends ChangeNotifier {
  List<TaskModel> tasks = [];
  final String currentUserId = "69e8635da4502d54d13682e5"; 
  final TaskService _taskService = TaskService();

  TaskController() {
    loadTasks();
    syncToServer();
  }

  void loadTasks() {
    final box = Hive.box<TaskModel>('tasks');
    tasks = box.values.toList();
    
    tasks.sort((a, b) {
      if (a.status == b.status) return a.deadline.compareTo(b.deadline);
      return a.status == 'SELESAI' ? 1 : -1;
    });
    notifyListeners();
  }

  // ==========================================
  // SYNC SERVER (SEKARANG LANGSUNG KE MONGO)
  // ==========================================
  Future<void> syncToServer() async {
    final box = Hive.box<TaskModel>('tasks');
    final unsyncedTasks = box.values.where((t) => !t.isSynced).toList();

    for (var task in unsyncedTasks) {
      // Langsung dorong data ke MongoDB
      bool success = await _taskService.upsertTask(task);
      
      if (success) {
        task.isSynced = true; // Tandai sukses
        await task.save();    // Simpan status sukses ke Hive
      }
    }
    loadTasks();
  }

  Future<void> addTask({required String nama, String? matkul, required DateTime deadline}) async {
    final box = Hive.box<TaskModel>('tasks');
    final now = DateTime.now();
    
    final newTask = TaskModel(
      // GENERATE OBJECT ID LANGSUNG DARI FLUTTER! Sangat jenius untuk Offline-First
      id: ObjectId().toHexString(), 
      idUser: currentUserId,
      namaTugas: nama,
      namaMkSnapshot: matkul,
      deadline: deadline,
      status: 'BELUM',
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    await box.put(newTask.id, newTask);
    loadTasks();
    syncToServer(); 
  }

  Future<void> updateTask({required TaskModel task, required String nama, String? matkul, required DateTime deadline}) async {
    task.namaTugas = nama;
    task.namaMkSnapshot = matkul;
    task.deadline = deadline;
    task.updatedAt = DateTime.now();
    task.isSynced = false;
    
    await task.save();
    loadTasks();
    syncToServer(); 
  }

  Future<void> deleteTask(TaskModel task) async {
    final taskId = task.id;
    await task.delete(); // Hapus di Hive Lokal
    loadTasks();
    await _taskService.deleteTask(taskId); // Hapus di MongoDB
  }

  Future<void> toggleStatus(TaskModel task) async {
    task.status = (task.status == 'SELESAI') ? 'BELUM' : 'SELESAI';
    task.updatedAt = DateTime.now();
    task.isSynced = false;
    await task.save();
    loadTasks();
    syncToServer();
  }
}