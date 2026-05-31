import 'package:mongo_dart/mongo_dart.dart';
import '../../core/network/mongo_database.dart';
import '../models/task_model.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class TaskService {
  // 🔥 FIX 1: Fungsi pembersih ID yang jauh lebih aman menggunakan Regex
  ObjectId _safeObjectId(String id) {
    try {
      final match = RegExp(r'[a-fA-F0-9]{24}').firstMatch(id.toString());
      if (match != null) {
        return ObjectId.fromHexString(match.group(0)!);
      }
      return ObjectId(); // Fallback darurat
    } catch (e) {
      return ObjectId();
    }
  }

  // 1. Tarik Semua Tugas milik Mahasiswa (Tugas Dosen + Tugas Personal)
  Future<List<Map<String, dynamic>>> getTasksByUser(String userId) async {
    try {
      final data = await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection
            .find(where.eq('id_user', _safeObjectId(userId)))
            .toList(),
      );
      return data;
    } catch (e) {
      print("❌ Error Get Tasks (Mongo): $e");
      return [];
    }
  }

  // 2. Simpan Tugas Baru ke MongoDB
  Future<bool> createTask(TaskModel task) async {
    try {
      final doc = task.toJson();

      // INTERCEPTOR: Paksa cari nama asli dari tabel master mata_kuliah!
      if (task.kodeMk != null && task.kodeMk!.isNotEmpty) {
        final masterMk = await MongoDatabase.runSafe(
          () => MongoDatabase.db.collection('mata_kuliah').findOne(
            where.eq('kode_mk', task.kodeMk!.trim()),
          ),
        );

        // Jika ketemu, timpa nama_mk_snapshot yang kotor dengan nama asli
        if (masterMk != null && masterMk['nama_mk'] != null) {
          String namaAsli = masterMk['nama_mk'].toString();
          doc['nama_mk_snapshot'] = namaAsli;

          // Perbaiki juga data di layar HP (Hive) agar langsung berubah
          task.namaMkSnapshot = namaAsli;
          if (task.isInBox) {
            await task.save();
          }
        }
      }

      doc['is_synced'] = true;
      
      if (doc['target_kelas'] is List) {
        doc['target_kelas'] = (doc['target_kelas'] as List)
            .where((id) => id != null && id.toString().trim().isNotEmpty)
            .map((id) => _safeObjectId(id.toString()))
            .toList();
      }

      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.insert(doc),
      );
      print("✅ SUKSES MENGIRIM TUGAS BARU KE MONGODB!");
      return true;
    } catch (e) {
      print("❌ Error Create Task (Mongo): $e");
      return false;
    }
  }

  // 3. Update Status Tugas
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
      print("❌ Error Update Task Status (Mongo): $e");
      return false;
    }
  }

  // 4. Hapus Tugas
  Future<bool> deleteTask(String taskId) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.remove(
          where.eq('_id', _safeObjectId(taskId)),
        ),
      );
      print("✅ SUKSES MENGHAPUS TUGAS DARI MONGODB!");
      return true;
    } catch (e) {
      print("❌ Error Delete Task (Mongo): $e");
      return false;
    }
  }

  // 5. Update Keseluruhan Tugas (Edit Tugas Dosen)
  Future<bool> updateTask(TaskModel task) async {
    try {
      String finalNamaMk = task.namaMkSnapshot ?? '';

      // INTERCEPTOR: Paksa cari nama asli dari tabel master mata_kuliah!
      if (task.kodeMk != null && task.kodeMk!.isNotEmpty) {
        final masterMk = await MongoDatabase.runSafe(
          () => MongoDatabase.db.collection('mata_kuliah').findOne(
            where.eq('kode_mk', task.kodeMk!.trim())
          )
        );
        
        if (masterMk != null && masterMk['nama_mk'] != null) {
          finalNamaMk = masterMk['nama_mk'].toString();
          
          task.namaMkSnapshot = finalNamaMk;
          if (task.isInBox) {
            await task.save();
          }
        }
      }

      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.update(
          where.eq('_id', _safeObjectId(task.id)),
          modify
              .set('nama_tugas', task.namaTugas)
              .set('deskripsi', task.deskripsi)
              .set('kode_mk', task.kodeMk) 
              .set('nama_mk_snapshot', finalNamaMk)
              .set('deadline', task.deadline)
              .set('lampiran', task.lampiran)
              .set(
                'target_kelas', 
                task.targetKelas
                    ?.where((id) => id.trim().isNotEmpty)
                    .map((id) => _safeObjectId(id))
                    .toList() ?? []
              )
              .set('nama_dosen', task.namaDosen)
              .set('updated_at', DateTime.now()),
        ),
      );
      print("✅ SUKSES MENGEDIT TUGAS DI MONGODB!");
      return true;
    } catch (e) {
      print("🔥 Error Update Task (Mongo): $e");
      return false;
    }
  }

  // 6. Menarik Tugas untuk Mahasiswa
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
      
      List<Map<String, dynamic>> dosenTasks = [];

      if (kelas != null && kelas.isNotEmpty) {
        String namaKelasSaja = kelas.split('-')[0].trim(); 

        final kelasDoc = await MongoDatabase.runSafe(
          () => MongoDatabase.kelasCollection.findOne(
            where.eq('nama_kelas', namaKelasSaja),
          ),
        );

        if (kelasDoc != null) {
          final idKelasObj = kelasDoc['_id'];
          dosenTasks = await MongoDatabase.runSafe(
            () => MongoDatabase.tasksCollection
                .find(where.eq('target_kelas', idKelasObj))
                .toList(),
          );
        } else {
          // Fallback regex pencarian nama kelas
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
        }
      }

      // 🔥 FIX 2: Mencegah duplikasi data (Misal tugas kelas juga masuk ke personal)
      final allTasks = [...personalTasks, ...dosenTasks];
      final Map<String, Map<String, dynamic>> uniqueTasks = {};
      
      for (var t in allTasks) {
        uniqueTasks[t['_id'].toString()] = t;
      }

      print("📚 [TaskService] Total tugas unik untuk Mahasiswa: ${uniqueTasks.length}");
      return uniqueTasks.values.toList();
      
    } catch (e) {
      print("❌ Error Get Tasks For Mahasiswa (Mongo): $e");
      return [];
    }
  }

  // 7. Upload Lampiran File
  Future<String?> uploadFileToServer(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://api.sigma.com/api/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['url']; // Return URL publik
      }
    } catch (e) {
      print("Error uploading: $e");
    }
    return null;
  }
}