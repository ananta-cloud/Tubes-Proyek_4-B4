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

    try {
      var selector = where.eq('hari', hari).ne('status', 'DRAFT');

      if (excludeScheduleId != null) {
        final cleanId = excludeScheduleId
            .replaceAll('ObjectId("', '')
            .replaceAll('")', '');

        selector = selector.ne('_id', ObjectId.fromHexString(cleanId));
      }

      final semuaHariIni = await _schCol.find(selector).toList();

      final bentrok = semuaHariIni.where((doc) {
        final mulaiDoc = doc['jam_mulai']?.toString() ?? '';
        final selesaiDoc = doc['jam_selesai']?.toString() ?? '';
        // Overlap: mulaiDoc < jamSelesai AND selesaiDoc > jamMulai
        return mulaiDoc.compareTo(jamSelesai) < 0 &&
            selesaiDoc.compareTo(jamMulai) > 0;
      }).toList();

      print('BENTROK count: ${bentrok.length}');
      for (final b in bentrok) {
        print(
          'BENTROK ITEM: ${b['hari']} ${b['jam_mulai']}-${b['jam_selesai']} ${b['ruangan']}',
        );
      }

      final ruanganTerpakai = bentrok
          .map((s) => s['ruangan']?.toString() ?? '')
          .where((r) => r.isNotEmpty)
          .toSet();

      final tersedia =
          allRuangan.where((r) => !ruanganTerpakai.contains(r)).toList()
            ..sort();

      print('TERSEDIA: $tersedia');
      return tersedia;
    } catch (e) {
      print('ERROR QUERY: $e');
      return [];
    }
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
      // Fungsi internal untuk konversi string ke ObjectId yang valid
      ObjectId _toObjectId(String id) {
        // Membersihkan string jika tidak sengaja terbawa format 'ObjectId("...")'
        final cleanId = id.replaceAll('ObjectId("', '').replaceAll('")', '');
        return ObjectId.fromHexString(cleanId);
      }

      await _reqCol.insertOne({
        'id_schedule': _toObjectId(idSchedule),
        'id_dosen': _toObjectId(idDosen),
        'nama_dosen': namaDosen,
        'tipe_request': tipeRequest,
        'detail_perubahan': detailPerubahan,
        'alasan': alasan,
        'status': 'PENDING',
        'is_late': isLate,
        'id_periode_revisi': idPeriodeRevisi != null
            ? _toObjectId(idPeriodeRevisi)
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
    try {
      final cleanId = idDosen.replaceAll('ObjectId("', '').replaceAll('")', '');

      final requests = await _reqCol
          .find(
            where
                .eq('id_dosen', ObjectId.fromHexString(cleanId))
                .sortBy('created_at', descending: true),
          )
          .toList();

      final List<ScheduleRequestModel> result = [];
      for (final req in requests) {
        Map<String, dynamic>? jadwal;
        if (req['id_schedule'] != null) {
          final schId = req['id_schedule'] is ObjectId
              ? req['id_schedule']
              : ObjectId.fromHexString(
                  req['id_schedule']
                      .toString()
                      .replaceAll('ObjectId("', '')
                      .replaceAll('")', ''),
                );

          jadwal = await _schCol.findOne(where.id(schId));
        }
        result.add(ScheduleRequestModel.fromJson(req, jadwal: jadwal));
      }
      return result;
    } catch (e) {
      print('Error getMyRequests: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // CANCEL REQUEST (hanya jika PENDING)
  // ─────────────────────────────────────────────

  Future<bool> cancelRequest(String requestId) async {
    try {
      final cleanId = requestId
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      await _reqCol.deleteOne(
        where.id(ObjectId.fromHexString(cleanId)).eq('status', 'PENDING'),
      );
      return true;
    } catch (e) {
      print('Error cancelRequest: $e');
      return false;
    }
  }
}
