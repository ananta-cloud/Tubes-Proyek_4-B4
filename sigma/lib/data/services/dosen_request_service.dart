import 'package:mongo_dart/mongo_dart.dart' hide Box;
import '../models/schedule_request_model.dart';
import 'package:sigma/core/network/mongo_database.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DosenRequestService {
  DbCollection get _schCol => MongoDatabase.db.collection('schedules');
  DbCollection get _reqCol => MongoDatabase.db.collection('schedule_requests');
  final Box _scheduleCache = Hive.box('schedule_cache');

  bool _allSchedulesCached = false;

  Future<bool> _isOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return !connectivity.contains(ConnectivityResult.none);
  }

  // ─────────────────────────────────────────────
  // JADWAL MILIK DOSEN
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMySchedules(String kodeDosen) async {
    try {
      if (!await _isOnline()) {
        final cached = _scheduleCache.get('my_schedules_$kodeDosen');
        return cached != null ? List<Map<String, dynamic>>.from(cached) : [];
      }

      await MongoDatabase.ensureConnected();

      // Cache semua jadwal sekali per sesi (untuk cek ruangan offline)
      if (!_allSchedulesCached) {
        final allSchedules = await _schCol.find().toList();
        final allSanitized = allSchedules.map(_sanitizeDoc).toList();
        await _scheduleCache.put('all_schedules', allSanitized);
        _allSchedulesCached = true;
      }

      final results = await _schCol
          .find(where.raw({'kode_dosen': kodeDosen}))
          .toList();

      final sanitized = results.map(_sanitizeDoc).toList();
      await _scheduleCache.put('my_schedules_$kodeDosen', sanitized);
      return sanitized;
    } catch (e) {
      print('Error getMySchedules: $e');
      // cache kalau ada error
      final cached = _scheduleCache.get('my_schedules_$kodeDosen');
      return cached != null ? List<Map<String, dynamic>>.from(cached) : [];
    }
  }

  // ─────────────────────────────────────────────
  // CEK RUANGAN KOSONG
  // ─────────────────────────────────────────────

  Future<List<String>> getAllRuangan() async {
    final results = await _schCol.distinct('ruangan');
    return List<String>.from(results['values'] ?? []);
  }

  Future<List<String>> getRuanganTersedia({
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? excludeScheduleId,
  }) async {
    if (!await _isOnline()) {
      return _getRuanganTersediaOffline(
        hari: hari,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        excludeScheduleId: excludeScheduleId,
      );
    }

    try {
      await MongoDatabase.ensureConnected();

      final allRuangan = await getAllRuangan();
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
        return mulaiDoc.compareTo(jamSelesai) < 0 &&
            selesaiDoc.compareTo(jamMulai) > 0;
      }).toList();

      print('BENTROK count: ${bentrok.length}');

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
      print('ERROR getRuanganTersedia: $e');
      // kalkulasi offline
      return _getRuanganTersediaOffline(
        hari: hari,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        excludeScheduleId: excludeScheduleId,
      );
    }
  }

  List<String> _getRuanganTersediaOffline({
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? excludeScheduleId,
  }) {
    final cached = _scheduleCache.get('all_schedules');
    if (cached == null) return [];

    final allSchedules = List<Map<String, dynamic>>.from(cached);

    final allRuangan = allSchedules
        .map((s) => s['ruangan']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();

    final bentrok = allSchedules.where((doc) {
      if (doc['hari']?.toString() != hari) return false;
      if (doc['status']?.toString() == 'DRAFT') return false;
      if (excludeScheduleId != null &&
          doc['_id']?.toString() == excludeScheduleId)
        return false;

      final mulaiDoc = doc['jam_mulai']?.toString() ?? '';
      final selesaiDoc = doc['jam_selesai']?.toString() ?? '';
      return mulaiDoc.compareTo(jamSelesai) < 0 &&
          selesaiDoc.compareTo(jamMulai) > 0;
    }).toSet();

    final ruanganTerpakai = bentrok
        .map((s) => s['ruangan']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toSet();

    return allRuangan.where((r) => !ruanganTerpakai.contains(r)).toList()
      ..sort();
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
    required String? offlineId,
  }) async {
    try {
      await MongoDatabase.ensureConnected();

      ObjectId toObjectId(String id) {
        final cleanId = id.replaceAll('ObjectId("', '').replaceAll('")', '');
        return ObjectId.fromHexString(cleanId);
      }

      if (offlineId != null) {
        final existing = await _reqCol.findOne(
          where.eq('offline_id', offlineId),
        );
        if (existing != null) {
          print(
            'Request dengan offlineId $offlineId sudah ada, skip duplikasi.',
          );
          return true;
        }
      }

      await _reqCol.insertOne({
        'offline_id': offlineId,
        'id_schedule': toObjectId(idSchedule),
        'id_dosen': toObjectId(idDosen),
        'nama_dosen': namaDosen,
        'tipe_request': tipeRequest,
        'detail_perubahan': detailPerubahan,
        'alasan': alasan,
        'status': 'PENDING',
        'is_late': isLate,
        'id_periode_revisi': idPeriodeRevisi != null
            ? toObjectId(idPeriodeRevisi)
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
      if (!await _isOnline()) {
        return _getMyRequestsFromCache(idDosen);
      }

      await MongoDatabase.ensureConnected();

      final cleanId = idDosen.replaceAll('ObjectId("', '').replaceAll('")', '');

      final requests = await _reqCol
          .find(
            where
                .eq('id_dosen', ObjectId.fromHexString(cleanId))
                .sortBy('created_at', descending: true),
          )
          .toList();

      final List<ScheduleRequestModel> result = [];
      final List<Map<String, dynamic>> rawForCache = [];

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

        final model = ScheduleRequestModel.fromJson(req, jadwal: jadwal);
        result.add(model);

        // Simpan ke cache
        rawForCache.add({
          '_id': model.id,
          'id_schedule': model.idSchedule,
          'id_dosen': model.idDosen,
          'nama_dosen': model.namaDosen,
          'tipe_request': model.tipeRequest,
          'detail_perubahan': model.detailPerubahan.toJson(),
          'alasan': model.alasan,
          'status': model.status,
          'offline_id': model.offlineId,
          'catatan_admin': model.catatanAdmin,
          'id_processor': model.idProcessor,
          'is_late': model.isLate,
          'created_at': model.createdAt?.toIso8601String(),
          'updated_at': model.updatedAt?.toIso8601String(),
          // Data jadwal embed
          'nama_mk': model.namaMk,
          'kode_mk': model.kodeMk,
          'hari': model.hariJadwal,
          'jam_mulai': model.jamMulaiJadwal,
          'jam_selesai': model.jamSelesaiJadwal,
          'ruangan': model.ruanganJadwal,
          'kelas': model.kelas,
        });
      }

      await _scheduleCache.put('my_requests_$idDosen', rawForCache);
      return result;
    } catch (e) {
      print('Error getMyRequests: $e');
      return _getMyRequestsFromCache(idDosen);
    }
  }

  List<ScheduleRequestModel> _getMyRequestsFromCache(String idDosen) {
    final cached = _scheduleCache.get('my_requests_$idDosen');
    if (cached == null) return [];

    return List<Map<String, dynamic>>.from(cached).map((e) {
      // Pisahkan data jadwal dari data request
      final jadwal = {
        'nama_mk': e['nama_mk'],
        'kode_mk': e['kode_mk'],
        'hari': e['hari'],
        'jam_mulai': e['jam_mulai'],
        'jam_selesai': e['jam_selesai'],
        'ruangan': e['ruangan'],
        'kelas': e['kelas'],
      };
      return ScheduleRequestModel.fromJson(e, jadwal: jadwal);
    }).toList();
  }

  // ─────────────────────────────────────────────
  // CANCEL REQUEST (hanya jika PENDING)
  // ─────────────────────────────────────────────

  Future<bool> cancelRequest(String requestId) async {
    try {
      await MongoDatabase.ensureConnected();

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

  // ─────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────

  Map<String, dynamic> _sanitizeDoc(Map<String, dynamic> doc) {
    return doc.map((k, v) {
      if (v is ObjectId) return MapEntry(k, v.toHexString());
      if (v is DateTime) return MapEntry(k, v.toIso8601String());
      return MapEntry(k, v);
    });
  }
}
