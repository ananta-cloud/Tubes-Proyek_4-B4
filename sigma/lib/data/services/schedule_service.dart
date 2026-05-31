import 'package:sigma/core/network/mongo_database.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Service layer untuk operasi jadwal langsung ke MongoDB.
/// Dipakai oleh SchedulingController (Tim Penjadwalan) dan ScheduleViewModel.
class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules([String filter = '']) async {
    try {
      // Selalu ambil yang statusnya PUBLISHED
      SelectorBuilder selector = where.eq('status', 'PUBLISHED');

      if (filter.isNotEmpty) {
        // 1. Cek apakah ini ID Mahasiswa / ID Kelas (ObjectId / Hex 24 Karakter)
        if (filter.length == 24 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(filter)) {
          selector = selector.eq('id_kelas', ObjectId.parse(filter));
          
          // 🔥 TAMBAHAN: Opsional jika Anda punya parameter semester yang dikirim
          // selector = selector.eq('semester', 'GENAP'); // Contoh memfilter khusus genap
        } 
        // 2. Pencarian untuk Dosen
        else {
          selector = where.raw({
            r'$and': [
              {'status': 'PUBLISHED'},
              {
                r'$or': [
                  {'kelas': {r'$regex': filter, r'$options': 'i'}},
                  {'nama_dosen': {r'$regex': filter, r'$options': 'i'}},
                ]
              }
            ]
          });
        }
      }

      final data = await MongoDatabase.runSafe(() => 
          MongoDatabase.schedulesCollection.find(selector).toList()
      );
      
      return data;
    } catch (e) {
      print("Error in ScheduleService (getSchedules): $e");
      return [];
    }
  }

  // Khusus dosen, filter by kode_dosen
  Future<List<Map<String, dynamic>>> getSchedulesByKodeDosen(
    String kodeDosen,
  ) async {
    try {
      // 🔥 BUNGKUS DENGAN RUNSAFE
      final data = await MongoDatabase.runSafe(() => 
        MongoDatabase.schedulesCollection
            .find(
              where.eq('status', 'PUBLISHED').raw({
                'kode_dosen': {
                  r'$elemMatch': {r'$eq': kodeDosen},
                },
              }),
            )
            .toList()
      );
      return data;
    } catch (e) {
      print("Error getSchedulesByKodeDosen: $e");
      return [];
    }
  }

  // Cek ruangan tersedia
  Future<List<String>> getRuanganTersedia({
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? excludeScheduleId,
  }) async {
    try {
      // 🔥 BUNGKUS DENGAN RUNSAFE
      final allRuangan = await MongoDatabase.runSafe(() => 
         MongoDatabase.schedulesCollection.distinct('ruangan')
      );
      
      final semua = List<String>.from(allRuangan['values'] ?? []);

      final selector = where.eq('hari', hari).ne('status', 'DRAFT').raw({
        'jam_mulai': {r'$lt': jamSelesai},
        'jam_selesai': {r'$gt': jamMulai},
      });

      if (excludeScheduleId != null && excludeScheduleId.isNotEmpty) {
        selector.ne('_id', ObjectId.parse(excludeScheduleId));
      }

      // 🔥 BUNGKUS DENGAN RUNSAFE
      final bentrok = await MongoDatabase.runSafe(() => 
          MongoDatabase.schedulesCollection.find(selector).toList()
      );
          
      final terpakai = bentrok
          .map((s) => s['ruangan']?.toString() ?? '')
          .toSet();

      return semua.where((r) => r.isNotEmpty && !terpakai.contains(r)).toList()..sort();
    } catch (e) {
      print("Error getRuanganTersedia: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSchedulesMhs([String? kelasMahasiswa]) async {
    try {
      // 1. Jika nama kelas kosong atau null, jangan lakukan query yang berat
      if (kelasMahasiswa == null || kelasMahasiswa.trim().isEmpty) {
        print("WARNING: getSchedulesMhs dipanggil tanpa nama kelas.");
        return [];
      }

      // 2. Bersihkan nama kelas dari spasi berlebih
      final String safeKelas = kelasMahasiswa.trim();

      // 3. Gunakan SelectorBuilder yang lebih aman
      final selector = where
          .eq('status', 'PUBLISHED')
          // Menggunakan match (regex) agar lebih fleksibel (misal: "D3-A" cocok dengan "D3-A Teknik Informatika")
          .match('kelas', safeKelas, caseInsensitive: true);

      final data = await MongoDatabase.runSafe(
        () => MongoDatabase.schedulesCollection.find(selector).toList(),
      );

      print("MONGO SCHEDULE (Kelas: $safeKelas): Ditemukan ${data.length} jadwal");
      return data;
    } catch (e) {
      print("ERROR getSchedulesMhs: $e");
      return [];
    }
  }
}