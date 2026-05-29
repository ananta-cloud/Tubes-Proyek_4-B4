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
      print("🔥 Error Get Tasks (Mongo): $e");
      return [];
    }
  }

  // 2. Simpan Tugas Baru ke MongoDB
  Future<bool> createTask(TaskModel task) async {
    try {
      final doc = task.toJson();

      // 🔥 INTERCEPTOR: Paksa cari nama asli dari tabel master mata_kuliah!
      if (task.kodeMk != null && task.kodeMk!.isNotEmpty) {
        final masterMk = await MongoDatabase.runSafe(
          () => MongoDatabase.db
              .collection('mata_kuliah')
              .findOne(
                where.eq(
                  'kode_mk',
                  task.kodeMk!.trim(),
                ), // Cari berdasarkan kode_mk
              ),
        );

        // Jika ketemu, timpa nama_mk_snapshot yang kotor dengan nama asli
        if (masterMk != null && masterMk['nama_mk'] != null) {
          String namaAsli = masterMk['nama_mk'].toString();
          doc['nama_mk_snapshot'] = namaAsli;

          // Perbaiki juga data di layar HP (Hive) agar langsung berubah tanpa perlu refresh
          task.namaMkSnapshot = namaAsli;
          if (task.isInBox) await task.save();
        }
      }

      doc['is_synced'] = true;

      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.insert(doc),
      );
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
      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.update(
          where.eq('_id', _safeObjectId(taskId)),
          modify.set('status', status).set('updated_at', DateTime.now()),
        ),
      );
      print("✅ SUKSES UPDATE STATUS TUGAS DI MONGODB!");
      return true;
    } catch (e) {
      print("🔥 Error Update Task Status (Mongo): $e");
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
      print("🗑️ SUKSES MENGHAPUS TUGAS DARI MONGODB!");
      return true;
    } catch (e) {
      print("🔥 Error Delete Task (Mongo): $e");
      return false;
    }
  }

  // 5. Update Keseluruhan Tugas (Edit Tugas Dosen)
  Future<bool> updateTask(TaskModel task) async {
    try {
      String finalNamaMk = task.namaMkSnapshot ?? '';

      // 🔥 INTERCEPTOR: Paksa cari nama asli dari tabel master mata_kuliah!
      if (task.kodeMk != null && task.kodeMk!.isNotEmpty) {
        final masterMk = await MongoDatabase.runSafe(
          () => MongoDatabase.db.collection('mata_kuliah').findOne(
            where.eq('kode_mk', task.kodeMk!.trim())
          )
        );
        
        if (masterMk != null && masterMk['nama_mk'] != null) {
          finalNamaMk = masterMk['nama_mk'].toString();
          
          // Perbaiki juga data di layar HP
          task.namaMkSnapshot = finalNamaMk;
          if (task.isInBox) await task.save();
        }
      }

      await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection.update(
          where.eq('_id', _safeObjectId(task.id)),
          modify
              .set('nama_tugas', task.namaTugas)
              .set('deskripsi', task.deskripsi)
              .set('kode_mk', task.kodeMk) 
              .set('nama_mk_snapshot', finalNamaMk) // Masukkan nama yang sudah bersih
              .set('deadline', task.deadline)
              .set('lampiran', task.lampiran)
              .set('target_kelas', task.targetKelas?.map((id) => _safeObjectId(id)).toList() ?? [])
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
      // 1. Ambil tugas personal (yang dibuat oleh Mahasiswa itu sendiri)
      final personalTasks = await MongoDatabase.runSafe(
        () => MongoDatabase.tasksCollection
            .find(where.eq('id_user', _safeObjectId(userId)))
            .toList(),
      );

      // 2. Ambil tugas dari Dosen berdasarkan Kelas Mahasiswa
      List<Map<String, dynamic>> dosenTasks = [];

      if (kelas != null && kelas.isNotEmpty) {
        // Karena sekarang 'target_kelas' berupa Array ObjectId,
        // kita cari ObjectId dari kelas si Mahasiswa ini terlebih dahulu.

        String namaKelasSaja = kelas
            .split('-')[0]
            .trim(); // Ambil "1B" dari "1B-D3"

        final kelasDoc = await MongoDatabase.runSafe(
          () => MongoDatabase.kelasCollection.findOne(
            where.eq('nama_kelas', namaKelasSaja),
          ),
        );

        if (kelasDoc != null) {
          // Cari tugas di mana ID kelas Mahasiswa terdapat di dalam Array target_kelas
          final idKelasObj = kelasDoc['_id'];
          dosenTasks = await MongoDatabase.runSafe(
            () => MongoDatabase.tasksCollection
                .find(where.eq('target_kelas', idKelasObj))
                .toList(),
          );
        } else {
          // Fallback (Jaga-jaga) jika data kelas tidak ketemu, gunakan pencarian snapshot lama
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
        print(
          "📚 [TaskService] Tugas dari Dosen untuk kelas $kelas: ${dosenTasks.length}",
        );
      }

      // Gabungkan keduanya
      return [...personalTasks, ...dosenTasks];
    } catch (e) {
      print("🔥 Error Get Tasks For Mahasiswa (Mongo): $e");
      return [];
    }
  }
}
