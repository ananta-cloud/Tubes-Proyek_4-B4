import 'package:mongo_dart/mongo_dart.dart';
import '../models/schedule_request_model.dart';
import 'package:kampus_ku_mobile/core/network/mongo_database.dart';

class DosenRequestService {
  DbCollection get _schCol => MongoDatabase.db.collection('schedules');
  DbCollection get _reqCol => MongoDatabase.db.collection('schedule_requests');

  // ─────────────────────────────────────────────
  // JADWAL MILIK DOSEN
  // ─────────────────────────────────────────────

  /// Ambil semua jadwal yang diampu dosen ini (by kode_dosen).
  Future<List<Map<String, dynamic>>> getMySchedules(String kodeDosen) async {
    final results = await _schCol
        .find(
          where.eq('status', 'PUBLISHED').raw({
            'kode_dosen': {
              r'$elemMatch': {r'$eq': kodeDosen},
            },
          }),
        )
        .toList();
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
    String?
    excludeScheduleId, // jadwal yang sedang direquest (exclude dari cek)
  }) async {
    final allRuangan = await getAllRuangan();

    // Query jadwal yang bentrok di hari + jam tersebut
    final selector = where.eq('hari', hari).ne('status', 'DRAFT').raw({
      'jam_mulai': {r'$lt': jamSelesai},
      'jam_selesai': {r'$gt': jamMulai},
    });

    if (excludeScheduleId != null) {
      selector.ne('_id', ObjectId.parse(excludeScheduleId));
    }

    final bentrok = await _schCol.find(selector).toList();
    final ruanganTerpakai = bentrok
        .map((s) => s['ruangan']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toSet();

    // 3. Filter ruangan yang KOSONG
    final tersedia =
        allRuangan.where((r) => !ruanganTerpakai.contains(r)).toList()..sort();

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
