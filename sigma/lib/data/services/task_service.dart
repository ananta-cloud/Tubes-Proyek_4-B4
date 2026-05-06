import 'package:mongo_dart/mongo_dart.dart';
import '../../core/network/mongo_database.dart';
import '../models/task_model.dart';

class TaskService {
  
  // 🔥 HELPER SAKTI: Membersihkan ID dari teks aneh agar tidak crash
  ObjectId _safeObjectId(String id) {
    String cleanId = id.replaceAll('ObjectId("', '').replaceAll('")', '').replaceAll("'", "").trim();
    return ObjectId.fromHexString(cleanId);
  }

  // 1. Tarik Semua Tugas milik Mahasiswa (Tugas Dosen + Tugas Personal)
  Future<List<Map<String, dynamic>>> getTasksByUser(String userId) async {
    try {
      final data = await MongoDatabase.tasksCollection.find(
        where.eq('id_user', _safeObjectId(userId))
      ).toList();
      return data;
    } catch (e) {
      print("🔥 Error Get Tasks (Mongo): $e");
      return [];
    }
  }

  // 2. Simpan Tugas Personal Baru ke MongoDB
  Future<bool> createTask(TaskModel task) async {
    try {
      await MongoDatabase.tasksCollection.insert({
        '_id': _safeObjectId(task.id),
        'id_user': _safeObjectId(task.idUser),
        'nama_tugas': task.namaTugas,
        'deskripsi': task.deskripsi,
        'id_mk': task.idMk, // Ini akan berisi null untuk tugas personal
        'nama_mk_snapshot': task.namaMkSnapshot,
        'deadline': task.deadline,
        'status': task.status,
        'is_synced': true, // Wajib true agar lolos validasi MongoDB
        'created_at': task.createdAt,
        'updated_at': task.updatedAt,
      });
      print("✅ SUKSES MENGIRIM TUGAS BARU KE MONGODB!");
      return true;
    } catch (e) {
      print("🔥 Error Create Task (Mongo): $e");
      return false;
    }
  }

  // 3. Update Status Tugas (Bisa untuk semua jenis tugas)
  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      await MongoDatabase.tasksCollection.update(
        where.eq('_id', _safeObjectId(taskId)),
        modify.set('status', status).set('updated_at', DateTime.now()),
      );
      print("✅ SUKSES UPDATE STATUS TUGAS DI MONGODB!");
      return true;
    } catch (e) {
      print("🔥 Error Update Task Status (Mongo): $e");
      return false;
    }
  }

  // 4. Hapus Tugas (Khusus Tugas Personal)
  Future<bool> deleteTask(String taskId) async {
    try {
      await MongoDatabase.tasksCollection.remove(
        where.eq('_id', _safeObjectId(taskId))
      );
      print("🗑️ SUKSES MENGHAPUS TUGAS DARI MONGODB!");
      return true;
    } catch (e) {
      print("🔥 Error Delete Task (Mongo): $e");
      return false;
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    try {
      await MongoDatabase.tasksCollection.update(
        where.eq('_id', _safeObjectId(task.id)),
        modify
          .set('nama_tugas', task.namaTugas)
          .set('nama_mk_snapshot', task.namaMkSnapshot)
          .set('deadline', task.deadline)
          .set('updated_at', DateTime.now()),
      );
      print("✅ SUKSES MENGEDIT TUGAS DI MONGODB!");
      return true;
    } catch (e) {
      print("🔥 Error Update Task (Mongo): $e");
      return false;
    }
  }
}