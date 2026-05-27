import 'package:mongo_dart/mongo_dart.dart';
import '../../core/network/mongo_database.dart';
import '../models/task_model.dart';

class TaskService {
  ObjectId _safeObjectId(String id) {
    String cleanId = id
        .replaceAll('ObjectId("', '')
        .replaceAll('")', '')
        .replaceAll("'", "")
        .trim();
    return ObjectId.fromHexString(cleanId);
  }

  // Tarik Semua Tugas milik Mahasiswa (Tugas Dosen + Tugas Personal)
  Future<List<Map<String, dynamic>>> getTasksByUser(String userId) async {
    try {
      final data = await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection
            .find(where.eq('id_user', _safeObjectId(userId)))
            .toList(),
      );
      return data;
    } catch (e) {
      print(" Error Get Tasks (Mongo): $e");
      return [];
    }
  }

  // Simpan Tugas Personal Baru ke MongoDB
  Future<bool> createTask(TaskModel task) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.insert({
          '_id': _safeObjectId(task.id),
          'id_user': _safeObjectId(task.idUser),
          'nama_tugas': task.namaTugas,
          'deskripsi': task.deskripsi,
          'id_mk': task.idMk, // Berisi null untuk tugas personal
          'nama_mk_snapshot': task.namaMkSnapshot,
          'deadline': task.deadline,
          'status': task.status,
          'is_synced': true,
          'created_at': task.createdAt,
          'updated_at': task.updatedAt,
          'lampiran': task.lampiran,
        }),
      );
      print("✅ SUKSES MENGIRIM TUGAS BARU KE MONGODB!");
      return true;
    } catch (e) {
      print(" Error Create Task (Mongo): $e");
      return false;
    }
  }

  // Update Status Tugas (Bisa untuk semua jenis tugas)
  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.update(
          where.eq('_id', _safeObjectId(taskId)),
          modify.set('status', status).set('updated_at', DateTime.now()),
        ),
      );
      print("✅ SUKSES UPDATE STATUS TUGAS DI MONGODB!");
      return true;
    } catch (e) {
      print(" Error Update Task Status (Mongo): $e");
      return false;
    }
  }

  // Hapus Tugas (Khusus Tugas Personal)
  Future<bool> deleteTask(String taskId) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.remove(
          where.eq('_id', _safeObjectId(taskId)),
        ),
      );
      print("SUKSES MENGHAPUS TUGAS DARI MONGODB!");
      return true;
    } catch (e) {
      print(" Error Delete Task (Mongo): $e");
      return false;
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.update(
          where.eq('_id', _safeObjectId(task.id)),
          modify
              .set('nama_tugas', task.namaTugas)
              .set('nama_mk_snapshot', task.namaMkSnapshot)
              .set('deadline', task.deadline)
              .set('lampiran', task.lampiran)
              .set('updated_at', DateTime.now()),
        ),
      );
      print("✅ SUKSES MENGEDIT TUGAS DI MONGODB!");
      return true;
    } catch (e) {
      print(" Error Update Task (Mongo): $e");
      return false;
    }
  }

  // Menarik Tugas Personal + Tugas Dosen untuk Mahasiswa
  Future<List<Map<String, dynamic>>> getTasksForMahasiswa(
    String userId,
    String? kelas,
  ) async {
    try {
      final personalTasks = await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection
            .find(where.eq('id_user', _safeObjectId(userId)))
            .toList(),
      );

      // Ambil tugas Dosen berdasarkan Kelas Mahasiswa
      List<Map<String, dynamic>> dosenTasks = [];
      if (kelas != null && kelas.isNotEmpty) {
        // dosenTasks = await MongoDatabase.runSafe(
        //   () => MongoDatabase.tasksCollection
        //       .find(where.match('nama_mk_snapshot', '.*\\($kelas\\).*', caseInsensitive: true))
        //       .toList(),
        // );
        dosenTasks = await MongoDatabase.runSafe(
          () => MongoDatabase.tasksCollection
              .find(
                where.match(
                  'nama_mk_snapshot',
                  '.*$kelas.*',
                  caseInsensitive: true,
                ),
              )
              .toList(),
        );
        print(
          "📚 [TaskService] Tugas dari Dosen untuk kelas $kelas: ${dosenTasks.length}",
        );
      }

      return [...personalTasks, ...dosenTasks];
    } catch (e) {
      print(" Error Get Tasks For Mahasiswa (Mongo): $e");
      return [];
    }
  }
}
