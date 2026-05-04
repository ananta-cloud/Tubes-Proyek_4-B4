<<<<<<< HEAD
import 'package:mongo_dart/mongo_dart.dart';
import 'package:sigma/core/network/mongo_database.dart';
import '../../../data/models/schedule_local_model.dart';

/// Service layer untuk operasi jadwal langsung ke MongoDB.
/// Dipakai oleh SchedulingController (Tim Penjadwalan).
class ScheduleService {
  DbCollection get _col => MongoDatabase.db.collection('schedules');

  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────

  /// Ambil semua jadwal berdasarkan id_jurusan user yang login.
  Future<List<Map<String, dynamic>>> getSchedules({
    required String idJurusan,
    String? hari,
    String? status,
    String? tipe,
    String? search,
  }) async {
    final selector = where.eq('id_jurusan', idJurusan);

    if (hari != null && hari.isNotEmpty) selector.eq('hari', hari);
    if (status != null && status.isNotEmpty) selector.eq('status', status);
    if (tipe != null && tipe.isNotEmpty) selector.eq('tipe', tipe);

    final result = await _col.find(selector).toList();

    // Filter search
    if (search != null && search.isNotEmpty) {
      selector.and(
        where.or(
          where
              .match('nama_mk', search, caseInsensitive: true)
              .or(where.match('nama_dosen', search, caseInsensitive: true))
              .or(where.match('ruangan', search, caseInsensitive: true)),
        ),
      );
    }

    return await _col.find(selector).toList();
  }

  /// Statistik count per status untuk jurusan tertentu.
  Future<Map<String, int>> getStatusCounts(String idJurusan) async {
    // final draft = await _col.count(
    //   where.eq('id_jurusan', idJurusan).eq('status', 'DRAFT'),
    // );
    // final finalStat = await _col.count(
    //   where.eq('id_jurusan', idJurusan).eq('status', 'FINAL'),
    // );
    // final published = await _col.count(
    //   where.eq('id_jurusan', idJurusan).eq('status', 'PUBLISHED'),
    // );

    // return {
    //   'draft': draft,
    //   'final': finalStat,
    //   'published': published,
    //   'total': draft + finalStat + published,
    // };

    final results = await Future.wait([
      _col.count(where.eq('id_jurusan', idJurusan).eq('status', 'DRAFT')),
      _col.count(where.eq('id_jurusan', idJurusan).eq('status', 'FINAL')),
      _col.count(where.eq('id_jurusan', idJurusan).eq('status', 'PUBLISHED')),
    ]);
    return {
      'draft': results[0],
      'final': results[1],
      'published': results[2],
      'total': results[0] + results[1] + results[2],
    };
  }

  /// Ambil 5 jadwal terbaru untuk dashboard.
  Future<List<Map<String, dynamic>>> getRecentSchedules(
    String idJurusan,
  ) async {
    return await _col
        .find(
          where
              .eq('id_jurusan', idJurusan)
              .sortBy('updated_at', descending: true)
              .limit(5),
        )
        .toList();
  }

  // // ─────────────────────────────────────────────
  // // CREATE
  // // ─────────────────────────────────────────────

  // Future<bool> createSchedule(Map<String, dynamic> data) async {
  //   try {
  //     final doc = {
  //       ...data,
  //       '_id': ObjectId(),
  //       'status': 'DRAFT',
  //       'created_at': DateTime.now(),
  //       'updated_at': DateTime.now(),
  //     };
  //     await _col.insertOne(doc);
  //     return true;
  //   } catch (e) {
  //     print('Error createSchedule: $e');
  //     return false;
  //   }
  // }

  // // ─────────────────────────────────────────────
  // // UPDATE
  // // ─────────────────────────────────────────────

  // Future<bool> updateSchedule(String id, Map<String, dynamic> data) async {
  //   try {
  //     await _col.updateOne(
  //       where.id(ObjectId.parse(id)),
  //       modify
  //           .set('tipe', data['tipe'])
  //           .set('hari', data['hari'])
  //           .set('jam_mulai', data['jam_mulai'])
  //           .set('jam_selesai', data['jam_selesai'])
  //           .set('ruangan', data['ruangan'])
  //           .set('nama_dosen', data['nama_dosen'])
  //           .set('status', 'DRAFT') // reset ke DRAFT setiap update
  //           .set('updated_at', DateTime.now()),
  //     );
  //     return true;
  //   } catch (e) {
  //     print('Error updateSchedule: $e');
  //     return false;
  //   }
  // }

  // Future<bool> finalizeSchedule(String id) async {
  //   try {
  //     await _col.updateOne(
  //       where.id(ObjectId.parse(id)).eq('status', 'DRAFT'),
  //       modify.set('status', 'FINAL').set('updated_at', DateTime.now()),
  //     );
  //     return true;
  //   } catch (e) {
  //     print('Error finalizeSchedule: $e');
  //     return false;
  //   }
  // }
=======
import '../../core/network/mongo_database.dart';

class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final data = await MongoDatabase.schedulesCollection.find({
      "status": "PUBLISHED", //  FILTER PENTING
    }).toList();

    print("MONGO SCHEDULE: ${data.length}");

    return data;
  }
>>>>>>> nazriel
}
