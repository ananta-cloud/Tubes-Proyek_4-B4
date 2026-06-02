import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:sigma/core/network/mongo_database.dart';
import '../models/schedule_request_model.dart';

class ScheduleRequestService {
  DbCollection get _reqCol => MongoDatabase.db.collection('schedule_requests');
  DbCollection get _schCol => MongoDatabase.db.collection('schedules');

  static const _cacheBox = 'tpj_requests_cache';
  static const _queueBox = 'tpj_action_queue';

  // ── Cache helpers ──────────────────────────────────────
  static Future<void> openBoxes() async {
    if (!Hive.isBoxOpen(_cacheBox)) await Hive.openBox<Map>(_cacheBox);
    if (!Hive.isBoxOpen(_queueBox)) await Hive.openBox<Map>(_queueBox);
  }

  void _saveCache(
    String idJurusan,
    String status,
    List<ScheduleRequestModel> items,
  ) {
    final box = Hive.box<Map>(_cacheBox);
    final key = '${idJurusan}_$status';
    box.put(key, {
      'data': items.map((r) => _modelToMap(r)).toList(),
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  List<ScheduleRequestModel> _loadCache(String idJurusan, String status) {
    final box = Hive.box<Map>(_cacheBox);
    final key = '${idJurusan}_$status';
    final raw = box.get(key);
    if (raw == null) return [];
    final list = (raw['data'] as List?) ?? [];
    return list.map((m) {
      final map = Map<String, dynamic>.from(m as Map);
      return ScheduleRequestModel.fromJson(map, jadwal: map);
    }).toList();
  }

  Map<String, dynamic> _modelToMap(ScheduleRequestModel r) => {
    '_id': r.id,
    'id_schedule': r.idSchedule,
    'id_dosen': r.idDosen,
    'nama_dosen': r.namaDosen,
    'tipe_request': r.tipeRequest,
    'detail_perubahan': r.detailPerubahan.toJson(),
    'alasan': r.alasan,
    'status': r.status,
    'offline_id': r.offlineId,
    'catatan_admin': r.catatanAdmin,
    'id_processor': r.idProcessor,
    'is_late': r.isLate,
    'created_at': r.createdAt?.toIso8601String(),
    'updated_at': r.updatedAt?.toIso8601String(),
    'nama_matkul': r.namaMk,
    'nama_mk': r.namaMk,
    'kode_mk': r.kodeMk,
    'hari': r.hariJadwal,
    'jam_mulai': r.jamMulaiJadwal,
    'jam_selesai': r.jamSelesaiJadwal,
    'ruangan': r.ruanganJadwal,
    'kelas': r.kelas,
  };

  // ── Queue helpers ──────────────────────────────────────
  void _enqueueAction(Map<String, dynamic> action) {
    final box = Hive.box<Map>(_queueBox);
    box.add(action);
  }

  List<Map<String, dynamic>> _getQueue() {
    final box = Hive.box<Map>(_queueBox);
    return box.values.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> _clearQueue() async {
    await Hive.box<Map>(_queueBox).clear();
  }

  String _cleanObjectId(String id) {
    return id
        .replaceAll('ObjectId("', '')
        .replaceAll('")', '')
        .replaceAll('ObjectId(', '')
        .replaceAll(')', '')
        .trim();
  }

  Future<void> Function() onEnsureConnected = MongoDatabase.ensureConnected;

  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────
  Future<List<ScheduleRequestModel>> getRequests({
    required String idJurusan,
    String? status,
  }) async {
    final statusKey = status ?? 'SEMUA';

    try {
      await onEnsureConnected();
    } catch (_) {
      return _loadCache(idJurusan, statusKey);
    }

    if (MongoDatabase.isOffline) {
      return _loadCache(idJurusan, statusKey);
    }

    try {
      final cleanId = idJurusan
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      final dosenList = await MongoDatabase.db
          .collection('dosen')
          .find(where.eq('id_jurusan', ObjectId.fromHexString(cleanId)))
          .toList();
      if (dosenList.isEmpty) return _loadCache(idJurusan, statusKey);

      final kodeDosens = dosenList
          .map((d) => d['kode_dosen']?.toString())
          .where((k) => k != null)
          .toList();

      final dosenIds = dosenList
          .map((d) => d['_id'])
          .whereType<ObjectId>()
          .toList();

      if (dosenIds.isEmpty) {
        return [];
      }
      final schedules = await _schCol
          .find(where.oneFrom('kode_dosen', kodeDosens))
          .toList();

      final scheduleMap = {for (var s in schedules) s['_id'].toString(): s};

      SelectorBuilder selector = where.oneFrom('id_dosen', dosenIds);

      if (status != null && status != 'SEMUA') {
        selector.eq('status', status);
      }

      selector.sortBy('created_at', descending: true);

      final requests = await _reqCol.find(selector).toList();

      final result = requests.map((r) {
        final jadwal = scheduleMap[r['id_schedule']?.toString()];
        return ScheduleRequestModel.fromJson(r, jadwal: jadwal);
      }).toList();

      _saveCache(idJurusan, statusKey, result);
      return result;
    } catch (e) {
      print('getRequests ERROR: $e');
      return _loadCache(idJurusan, statusKey);
    }
  }

  Future<ScheduleRequestModel?> getRequestById(String id) async {
    final req = await _reqCol.findOne(where.id(ObjectId.parse(id)));
    if (req == null) return null;
    final jadwal = await _schCol.findOne(
      where.id(
        req['id_schedule'] is ObjectId
            ? req['id_schedule']
            : ObjectId.parse(req['id_schedule'].toString()),
      ),
    );
    return ScheduleRequestModel.fromJson(req, jadwal: jadwal);
  }

  // pake query terpisah per status
  Future<Map<String, int>> getStats(String idJurusan) async {
    try {
      if (MongoDatabase.isOffline) {
        return {'pending': 0, 'approved': 0, 'rejected': 0};
      }

      final cleanId = idJurusan
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      final dosenList = await MongoDatabase.db
          .collection('dosen')
          .find(where.eq('id_jurusan', ObjectId.fromHexString(cleanId)))
          .toList();
      if (dosenList.isEmpty)
        return {'pending': 0, 'approved': 0, 'rejected': 0};

      final kodeDosens = dosenList
          .map((d) => d['kode_dosen']?.toString())
          .where((k) => k != null)
          .toList();

      final schedules = await _schCol
          .find(where.oneFrom('kode_dosen', kodeDosens))
          .toList();
      if (schedules.isEmpty)
        return {'pending': 0, 'approved': 0, 'rejected': 0};

      final dosenIds = dosenList.map((d) => d['_id'] as ObjectId).toList();

      final pending = await _reqCol.count(
        where.oneFrom('id_dosen', dosenIds).eq('status', 'PENDING'),
      );

      final approved = await _reqCol.count(
        where.oneFrom('id_dosen', dosenIds).eq('status', 'APPROVED'),
      );

      final rejected = await _reqCol.count(
        where.oneFrom('id_dosen', dosenIds).eq('status', 'REJECTED'),
      );
      return {'pending': pending, 'approved': approved, 'rejected': rejected};
    } catch (e) {
      print('getStats ERROR: $e');
      return {'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  // ─────────────────────────────────────────────
  // APPROVE
  // ─────────────────────────────────────────────
  Future<bool> approveRequest({
    required String requestId,
    required String processorId,
    String? catatanAdmin,
    required ScheduleRequestModel request,
  }) async {
    if (MongoDatabase.isOffline) {
      _enqueueAction({
        'type': 'APPROVE',
        'requestId': requestId,
        'processorId': processorId,
        'catatanAdmin': catatanAdmin,
        'requestJson': _modelToMap(request),
        'queuedAt': DateTime.now().toIso8601String(),
      });
      return true;
    }
    return _doApprove(
      requestId: requestId,
      processorId: processorId,
      catatanAdmin: catatanAdmin,
      request: request,
    );
  }

  Future<bool> _doApprove({
    required String requestId,
    required String processorId,
    String? catatanAdmin,
    required ScheduleRequestModel request,
  }) async {
    try {
      await MongoDatabase.ensureConnected();

      final reqId = ObjectId.fromHexString(_cleanObjectId(requestId));

      final procId = ObjectId.fromHexString(_cleanObjectId(processorId));

      final schId = ObjectId.fromHexString(_cleanObjectId(request.idSchedule));

      final updateReq = await _reqCol.updateOne(
        where.id(reqId),
        modify
            .set('status', 'APPROVED')
            .set('catatan_admin', catatanAdmin ?? 'Disetujui')
            .set('id_processor', procId)
            .set('updated_at', DateTime.now()),
      );

      if (!updateReq.isSuccess) {
        print('Approve request gagal');
        return false;
      }

      final detail = request.detailPerubahan;

      final modifier = modify
          .set('updated_at', DateTime.now())
          .set('status', 'PUBLISHED');

      if (detail.hariBaru != null) {
        modifier.set('hari', detail.hariBaru);
      }

      if (detail.jamMulaiBaru != null) {
        modifier.set('jam_mulai', detail.jamMulaiBaru);
      }

      if (detail.jamSelesaiBaru != null) {
        modifier.set('jam_selesai', detail.jamSelesaiBaru);
      }

      if (detail.ruanganBaru != null) {
        modifier.set('ruangan', detail.ruanganBaru);
      }

      final updateSchedule = await _schCol.updateOne(where.id(schId), modifier);

      return updateSchedule.isSuccess;
    } catch (e, s) {
      print('_doApprove ERROR');
      print(e.toString());
      print(s.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // REJECT
  // ─────────────────────────────────────────────
  Future<bool> rejectRequest({
    required String requestId,
    required String processorId,
    required String catatanAdmin,
  }) async {
    if (MongoDatabase.isOffline) {
      _enqueueAction({
        'type': 'REJECT',
        'requestId': requestId,
        'processorId': processorId,
        'catatanAdmin': catatanAdmin,
        'queuedAt': DateTime.now().toIso8601String(),
      });
      return true;
    }
    return _doReject(
      requestId: requestId,
      processorId: processorId,
      catatanAdmin: catatanAdmin,
    );
  }

  Future<bool> _doReject({
    required String requestId,
    required String processorId,
    required String catatanAdmin,
  }) async {
    try {
      await MongoDatabase.ensureConnected();

      final reqId = ObjectId.fromHexString(_cleanObjectId(requestId));

      final procId = ObjectId.fromHexString(_cleanObjectId(processorId));

      final result = await _reqCol.updateOne(
        where.id(reqId),
        modify
            .set('status', 'REJECTED')
            .set('catatan_admin', catatanAdmin)
            .set('id_processor', procId)
            .set('updated_at', DateTime.now()),
      );

      return result.isSuccess;
    } catch (e, s) {
      print('_doReject ERROR');
      print(e.toString());
      print(s.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // SYNC QUEUE
  // ─────────────────────────────────────────────
  Future<int> flushQueue() async {
    final queue = _getQueue();
    if (queue.isEmpty) return 0;

    int synced = 0;
    for (final action in queue) {
      try {
        bool ok = false;
        if (action['type'] == 'APPROVE') {
          final req = ScheduleRequestModel.fromJson(
            Map<String, dynamic>.from(action['requestJson']),
            jadwal: Map<String, dynamic>.from(action['requestJson']),
          );
          ok = await _doApprove(
            requestId: action['requestId'],
            processorId: action['processorId'],
            catatanAdmin: action['catatanAdmin'],
            request: req,
          );
        } else if (action['type'] == 'REJECT') {
          ok = await _doReject(
            requestId: action['requestId'],
            processorId: action['processorId'],
            catatanAdmin: action['catatanAdmin'],
          );
        }
        if (ok) synced++;
      } catch (_) {}
    }

    await _clearQueue();
    return synced;
  }

  Future<void> clearCache(String idJurusan, String status) async {
    final box = Hive.box<Map>(_cacheBox);
    box.delete('${idJurusan}_$status');
  }
}
