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
    isOffline = MongoDatabase.isOffline;
    debugPrint('DEBUG loadRequests isOffline=$isOffline');

    try {
      requests = await service.getRequests(
        idJurusan: idJurusan,
        status: filterStatus == 'SEMUA' ? null : filterStatus,
      );
      // Jika berhasil dari Mongo, isOffline = false
      isOffline = MongoDatabase.isOffline;
      await _loadStats(idJurusan);
    } catch (e) {
      isOffline = true;
      debugPrint('DEBUG loadRequests catch isOffline=$isOffline');

      errorMsg = e.toString();
      await _loadStats(idJurusan);
    }

    _setLoading(false);
  }

  Future<void> _loadStats(String idJurusan) async {
    try {
      if (filterStatus == 'SEMUA') {
        countPending = requests
            .where((r) => r.status.toUpperCase() == 'PENDING')
            .length;
        countApproved = requests
            .where((r) => r.status.toUpperCase() == 'APPROVED')
            .length;
        countRejected = requests
            .where((r) => r.status.toUpperCase() == 'REJECTED')
            .length;
      } else {
        final stats = await service.getStats(idJurusan);
        countPending = stats['pending'] ?? 0;
        countApproved = stats['approved'] ?? 0;
        countRejected = stats['rejected'] ?? 0;
      }
    } catch (_) {
      countPending = requests
          .where((r) => r.status.toUpperCase() == 'PENDING')
          .length;
      countApproved = requests
          .where((r) => r.status.toUpperCase() == 'APPROVED')
          .length;
      countRejected = requests
          .where((r) => r.status.toUpperCase() == 'REJECTED')
          .length;
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
  // SYNC (dipanggil dari _ConnectivityListener)
  // ─────────────────────────────────────────────
  Future<void> onConnectionRestored() async {
    isSyncing = true;
    isOffline = false; // ← set false duluan
    notifyListeners();

    try {
      await MongoDatabase.ensureConnected();
      await Future.delayed(const Duration(milliseconds: 1500)); // ← tambah

      final synced = await service.flushQueue();
      if (_lastIdJurusan != null) {
        await loadRequests(_lastIdJurusan!);
      }
      if (synced > 0) {
        justSynced = true;
      }
    } catch (e) {
      debugPrint('onConnectionRestored ERROR: $e');
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
