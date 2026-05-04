import 'package:flutter/material.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/schedule_request_service.dart';

class ScheduleRequestController extends ChangeNotifier {
  final ScheduleRequestService service;
  ScheduleRequestController(this.service);

  List<ScheduleRequestModel> requests = [];
  bool isLoading = false;
  String? errorMsg;

  int countPending = 0;
  int countApproved = 0;
  int countRejected = 0;

  // Filter
  String filterStatus = 'SEMUA';

  // ─────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────

  Future<void> loadRequests(String idJurusan) async {
    _setLoading(true);
    errorMsg = null;

    try {
      requests = await service.getRequests(
        idJurusan: idJurusan,
        status: filterStatus == 'SEMUA' ? null : filterStatus,
      );
      await _loadStats(idJurusan);
    } catch (e) {
      errorMsg = e.toString();
    }

    _setLoading(false);
  }

  Future<void> _loadStats(String idJurusan) async {
    final stats = await service.getStats(idJurusan);
    countPending = stats['pending'] ?? 0;
    countApproved = stats['approved'] ?? 0;
    countRejected = stats['rejected'] ?? 0;
  }

  // ─────────────────────────────────────────────────────
  // FILTER
  // ─────────────────────────────────────────────────────

  void setFilter(String status, String idJurusan) {
    filterStatus = status;
    loadRequests(idJurusan);
  }

  // ─────────────────────────────────────────────────────
  // APPROVE
  // ─────────────────────────────────────────────────────

  Future<bool> approve({
    required String requestId,
    required String processorId,
    required String idJurusan,
    required ScheduleRequestModel request,
    String? catatan,
  }) async {
    final ok = await service.approveRequest(
      requestId: requestId,
      processorId: processorId,
      catatanAdmin: catatan,
      request: request,
    );
    if (ok) await loadRequests(idJurusan);
    return ok;
  }

  // ─────────────────────────────────────────────────────
  // REJECT
  // ─────────────────────────────────────────────────────

  Future<bool> reject({
    required String requestId,
    required String processorId,
    required String idJurusan,
    required String catatan,
  }) async {
    final ok = await service.rejectRequest(
      requestId: requestId,
      processorId: processorId,
      catatanAdmin: catatan,
    );
    if (ok) await loadRequests(idJurusan);
    return ok;
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }
}
