import 'package:mongo_dart/mongo_dart.dart';
import '../models/schedule_request_model.dart';
import 'package:sigma/core/network/mongo_database.dart';

class DosenRequestService {
  DbCollection get _schCol => MongoDatabase.db.collection('schedules');
  DbCollection get _reqCol => MongoDatabase.db.collection('schedule_requests');

  // ─────────────────────────────────────────────
  // JADWAL MILIK DOSEN
  // ─────────────────────────────────────────────

  /// Ambil semua jadwal yang diampu dosen ini (by kode_dosen).
  Future<List<Map<String, dynamic>>> getMySchedules(String kodeDosen) async {
    final results = await _schCol
        .find(where.raw({'kode_dosen': kodeDosen}))
        .toList();
    print('SCHEDULES FOUND: ${results.length}');
    return results;
  }

  // ─────────────────────────────────────────────
  // CEK RUANGAN KOSONG
  // ─────────────────────────────────────────────

  /// Daftar semua ruangan unik yang pernah ada di collection schedules.
  Future<List<String>> getAllRuangan() async {
    final results = await _schCol.distinct('ruangan');
    return List<String>.from(results['values'] ?? []);
  }

  /// Cek ruangan mana saja yang TERPAKAI pada tanggal + jam tertentu.
  /// Return list ruangan yang KOSONG (tersedia).
  Future<List<String>> getRuanganTersedia({
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? excludeScheduleId,
  }) async {
    final allRuangan = await getAllRuangan();
    print('ALL RUANGAN: $allRuangan');
    print('CEK: hari=$hari mulai=$jamMulai selesai=$jamSelesai');

    final filter = <String, dynamic>{
      'hari': hari,
      'status': {r'$ne': 'DRAFT'},
      'jam_mulai': {r'$lt': jamSelesai},
      'jam_selesai': {r'$gt': jamMulai},
    };

    if (excludeScheduleId != null) {
      filter['_id'] = {r'$ne': ObjectId.parse(excludeScheduleId)};
    }

    final bentrok = await _schCol.find(where.raw(filter)).toList();
    print('BENTROK: ${bentrok.length} - ${bentrok.map((s) => s['ruangan'])}');

    final ruanganTerpakai = bentrok
        .map((s) => s['ruangan']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toSet();

    final tersedia =
        allRuangan.where((r) => !ruanganTerpakai.contains(r)).toList()..sort();

    print('TERSEDIA: $tersedia');
    return tersedia;
  }
  // ─────────────────────────────────────────────
  // SUBMIT REQUEST
  // ─────────────────────────────────────────────

  Future<bool> submitRequest({
    required String idSchedule,
    required String idDosen,
    required String namaDosen,
    required String tipeRequest,
    required Map<String, dynamic> detailPerubahan,
    required String alasan,
    bool isLate = false,
    String? idPeriodeRevisi,
  }) async {
    try {
      await _reqCol.insertOne({
        'id_schedule': ObjectId.parse(idSchedule),
        'id_dosen': ObjectId.parse(idDosen),
        'nama_dosen': namaDosen,
        'tipe_request': tipeRequest,
        'detail_perubahan': detailPerubahan,
        'alasan': alasan,
        'status': 'PENDING',
        'is_late': isLate,
        'id_periode_revisi': idPeriodeRevisi != null
            ? ObjectId.parse(idPeriodeRevisi)
            : null,
        'catatan_admin': null,
        'id_processor': null,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('Error submitRequest: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // RIWAYAT REQUEST DOSEN
  // ─────────────────────────────────────────────

  Future<List<ScheduleRequestModel>> getMyRequests(String idDosen) async {
    final requests = await _reqCol
        .find(
          where
              .eq('id_dosen', ObjectId.parse(idDosen))
              .sortBy('created_at', descending: true),
        )
        .toList();

    // Embed data jadwal
    final List<ScheduleRequestModel> result = [];
    for (final req in requests) {
      Map<String, dynamic>? jadwal;
      if (req['id_schedule'] != null) {
        jadwal = await _schCol.findOne(
          where.id(
            req['id_schedule'] is ObjectId
                ? req['id_schedule']
                : ObjectId.parse(req['id_schedule'].toString()),
          ),
        );
      }
      result.add(ScheduleRequestModel.fromJson(req, jadwal: jadwal));
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // CANCEL REQUEST (hanya jika PENDING)
  // ─────────────────────────────────────────────

  Future<bool> cancelRequest(String requestId) async {
    try {
      await _reqCol.deleteOne(
        where.id(ObjectId.parse(requestId)).eq('status', 'PENDING'),
      );
      return true;
    } catch (e) {
      print('Error cancelRequest: $e');
      return false;
    }
  }
}
