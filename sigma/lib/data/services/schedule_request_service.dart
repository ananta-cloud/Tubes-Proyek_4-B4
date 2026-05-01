import 'package:mongo_dart/mongo_dart.dart';
import 'package:kampus_ku_mobile/core/network/mongo_database.dart';
import '../models/schedule_request_model.dart';

class ScheduleRequestService {
  DbCollection get _reqCol => MongoDatabase.db.collection('schedule_requests');
  DbCollection get _schCol => MongoDatabase.db.collection('schedules');

  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────

  /// Ambil semua request untuk jadwal milik jurusan [idJurusan].
  /// Filter opsional: status (PENDING | APPROVED | REJECTED)
  Future<List<ScheduleRequestModel>> getRequests({
    required String idJurusan,
    String? status,
  }) async {
    // Ambil semua id schedule milik jurusan ini
    final schedules = await _schCol
        .find(where.eq('id_jurusan', ObjectId.parse(idJurusan)))
        .toList();

    final scheduleIds = schedules.map((s) => s['_id']).toList();

    if (scheduleIds.isEmpty) return [];

    // Build query requests
    final selector = where.oneFrom('id_schedule', scheduleIds);
    if (status != null && status != 'SEMUA') {
      selector.eq('status', status);
    }
    selector.sortBy('created_at', descending: true);

    final requests = await _reqCol.find(selector).toList();

    // Map jadwal ke map untuk lookup O(1)
    final scheduleMap = {for (var s in schedules) s['_id'].toString(): s};

    return requests.map((r) {
      final jadwal = scheduleMap[r['id_schedule']?.toString()];
      return ScheduleRequestModel.fromJson(r, jadwal: jadwal);
    }).toList();
  }

  /// Ambil satu request by id, sekalian embed data jadwalnya.
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

  /// Hitung stats untuk header cards.
  Future<Map<String, int>> getStats(String idJurusan) async {
    final schedules = await _schCol
        .find(where.eq('id_jurusan', ObjectId.parse(idJurusan)))
        .toList();
    final ids = schedules.map((s) => s['_id']).toList();
    if (ids.isEmpty) return {'pending': 0, 'approved': 0, 'rejected': 0};

    final pending = await _reqCol.count(
      where.oneFrom('id_schedule', ids).eq('status', 'PENDING'),
    );
    final approved = await _reqCol.count(
      where.oneFrom('id_schedule', ids).eq('status', 'APPROVED'),
    );
    final rejected = await _reqCol.count(
      where.oneFrom('id_schedule', ids).eq('status', 'REJECTED'),
    );

    return {'pending': pending, 'approved': approved, 'rejected': rejected};
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
    try {
      // Update status request
      await _reqCol.updateOne(
        where.id(ObjectId.parse(requestId)),
        modify
            .set('status', 'APPROVED')
            .set('catatan_admin', catatanAdmin ?? 'Disetujui.')
            .set('id_processor', ObjectId.parse(processorId))
            .set('updated_at', DateTime.now()),
      );

      // Terapkan perubahan ke jadwal
      final detail = request.detailPerubahan;
      final updateFields = <String, dynamic>{
        'updated_at': DateTime.now(),
        'status': 'DRAFT', // reset ke DRAFT setelah perubahan
      };
      if (detail.hariBaru != null) updateFields['hari'] = detail.hariBaru;
      if (detail.jamMulaiBaru != null)
        updateFields['jam_mulai'] = detail.jamMulaiBaru;
      if (detail.jamSelesaiBaru != null)
        updateFields['jam_selesai'] = detail.jamSelesaiBaru;
      if (detail.ruanganBaru != null)
        updateFields['ruangan'] = detail.ruanganBaru;

      final modifier = modify;
      updateFields.forEach((k, v) => modifier.set(k, v));

      await _schCol.updateOne(
        where.id(ObjectId.parse(request.idSchedule)),
        modifier,
      );

      return true;
    } catch (e) {
      print('Error approveRequest: $e');
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
    try {
      await _reqCol.updateOne(
        where.id(ObjectId.parse(requestId)),
        modify
            .set('status', 'REJECTED')
            .set('catatan_admin', catatanAdmin)
            .set('id_processor', ObjectId.parse(processorId))
            .set('updated_at', DateTime.now()),
      );
      return true;
    } catch (e) {
      print('Error rejectRequest: $e');
      return false;
    }
  }
}
