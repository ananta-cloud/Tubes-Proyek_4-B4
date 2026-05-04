import 'package:mongo_dart/mongo_dart.dart';
import 'package:sigma/core/network/mongo_database.dart';

class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules({String? idJurusan}) async {
    try {
      final selector = idJurusan != null && idJurusan.isNotEmpty
          ? where
                .eq('id_jurusan', ObjectId.parse(idJurusan))
                .eq('status', 'PUBLISHED')
          : where.eq('status', 'PUBLISHED');

      final data = await MongoDatabase.schedulesCollection
          .find(selector)
          .toList();
      return data;
    } catch (e) {
      print("Error in ScheduleService: $e");
      return [];
    }
  }

  // khusus dosen, filter by kode_dosen
  Future<List<Map<String, dynamic>>> getSchedulesByKodeDosen(
    String kodeDosen,
  ) async {
    try {
      final data = await MongoDatabase.schedulesCollection
          .find(
            where.eq('status', 'PUBLISHED').raw({
              'kode_dosen': {
                r'$elemMatch': {r'$eq': kodeDosen},
              },
            }),
          )
          .toList();
      return data;
    } catch (e) {
      print("Error getSchedulesByKodeDosen: $e");
      return [];
    }
  }

  // cek ruangan tersedia
  Future<List<String>> getRuanganTersedia({
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? excludeScheduleId,
  }) async {
    try {
      final allRuangan = await MongoDatabase.schedulesCollection.distinct(
        'ruangan',
      );
      final semua = List<String>.from(allRuangan['values'] ?? []);

      final selector = where.eq('hari', hari).ne('status', 'DRAFT').raw({
        'jam_mulai': {r'$lt': jamSelesai},
        'jam_selesai': {r'$gt': jamMulai},
      });

      if (excludeScheduleId != null) {
        selector.ne('_id', ObjectId.parse(excludeScheduleId));
      }

      final bentrok = await MongoDatabase.schedulesCollection
          .find(selector)
          .toList();
      final terpakai = bentrok
          .map((s) => s['ruangan']?.toString() ?? '')
          .toSet();

      return semua.where((r) => !terpakai.contains(r)).toList()..sort();
    } catch (e) {
      print("Error getRuanganTersedia: $e");
      return [];
    }
  }
}
