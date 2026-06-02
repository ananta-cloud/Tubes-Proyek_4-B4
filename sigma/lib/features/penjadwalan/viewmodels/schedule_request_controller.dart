import 'package:flutter/material.dart';
import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/schedule_request_service.dart';

class ScheduleRequestController extends ChangeNotifier {
  final ScheduleRequestService service;
  ScheduleRequestController(this.service);

  List<ScheduleRequestModel> requests = [];
  bool isLoading = false;
  bool isOffline = MongoDatabase.isOffline;
  bool justSynced = false;
  String? errorMsg;
  bool isSyncing = false;

  int countPending = 0;
  int countApproved = 0;
  int countRejected = 0;

  String filterStatus = 'SEMUA';
  String? _lastIdJurusan;

  // ─────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────
  Future<void> loadRequests(String idJurusan) async {
    _lastIdJurusan = idJurusan;
    _setLoading(true);
    errorMsg = null;

    try {
      requests = await service.getRequests(
        idJurusan: idJurusan,
        status: filterStatus == 'SEMUA' ? null : filterStatus,
      );
      isOffline = MongoDatabase.isOffline;
      await _loadStats(idJurusan);
    } catch (e) {
      isOffline = true;
      errorMsg = e.toString();
      await _loadStats(idJurusan);
    }

    _setLoading(false);
  }

  Future<void> _loadStats(String idJurusan) async {
    try {
      final stats = await service.getStats(idJurusan);
      countPending = stats['pending'] ?? 0;
      countApproved = stats['approved'] ?? 0;
      countRejected = stats['rejected'] ?? 0;
    } catch (_) {
      //Hitung dari cache jika stats gagal
      countPending = requests.where((r) => r.status == 'PENDING').length;
      countApproved = requests.where((r) => r.status == 'APPROVED').length;
      countRejected = requests.where((r) => r.status == 'REJECTED').length;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // FILTER
  // ─────────────────────────────────────────────
  void setFilter(String status, String idJurusan) {
    filterStatus = status;
    loadRequests(idJurusan);
  }

  // ─────────────────────────────────────────────
  // APPROVE
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // REJECT
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // SYNC
  // ─────────────────────────────────────────────
  Future<void> onConnectionRestored() async {
    isSyncing = true;
    notifyListeners();

    try {
      await MongoDatabase.ensureConnected();

      isOffline = false;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      final synced = await service.flushQueue();
      if (synced > 0 && _lastIdJurusan != null) {
        await service.clearCache(_lastIdJurusan!, 'SEMUA');
      }
      if (_lastIdJurusan != null) {
        await loadRequests(_lastIdJurusan!);
      }
      if (synced > 0) {
        justSynced = true;
      }
    } catch (e) {
      debugPrint('onConnectionRestored ERROR: $e');
      isOffline = true;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  void clearSyncFlag() {
    justSynced = false;
    notifyListeners();
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  void setOffline(bool value) {
    if (isOffline == value) return;
    isOffline = value;
    notifyListeners();
  }
}
