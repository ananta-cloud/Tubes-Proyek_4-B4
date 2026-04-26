import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../data/models/schedule_local_model.dart';
import '../data/services/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService service;

  ScheduleController(this.service);

  // ─── State ───────────────────────────────────────
  List<ScheduleLocalModel> schedules = [];
  List<ScheduleLocalModel> recentSchedules = [];

  bool isLoading = false;
  String? errorMsg;

  // Stats
  int countDraft = 0;
  int countFinal = 0;
  int countPublished = 0;
  int total = 0;
  int pendingRequests = 0;

  // Filter state
  String? filterHari;
  String? filterStatus;
  String? filterTipe;
  String searchQuery = '';

  // Collision result
  Map<String, dynamic>? collisionDetail;

  Future<void> syncSchedules() async {
    isLoading = true;
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<ScheduleLocalModel>('schedules');

    // ================= OFFLINE MODE =================
    if (connectivityResult == ConnectivityResult.none) {
      schedules = box.values.toList();

      isLoading = false;
      notifyListeners();

      print("OFFLINE MODE - Loaded ${schedules.length} data from Hive");
      return;
    }

    // ================= ONLINE MODE =================
    try {
      final List<Map<String, dynamic>> list = await service.getSchedules(
        idJurusan: '12345',
      );

      print("DATA FROM API: ${list.length}");

      // Clear hanya saat online
      await box.clear();

      for (var item in list) {
        final schedule = ScheduleLocalModel.fromJson(item);
        await box.put(schedule.id, schedule);
      }

      schedules = box.values.toList();

      print("SYNC SUCCESS: ${schedules.length} data saved to Hive");
    } catch (e) {
      print("ERROR SYNC: $e");

      // fallback ke data lokal jika API gagal
      schedules = box.values.toList();
      print("FALLBACK TO HIVE: ${schedules.length} data");
    }

    isLoading = false;
    notifyListeners();
  }

  // ================= KHUSUS TIM PENJADWALAN =================

  /// Load jadwal + stats. idJurusan dari user yang login.
  Future<void> loadSchedules(String idJurusan) async {
    _setLoading(true);
    collisionDetail = null;

    try {
      final raw = await service.getSchedules(
        idJurusan: idJurusan,
        hari: filterHari,
        status: filterStatus,
        tipe: filterTipe,
        search: searchQuery.isEmpty ? null : searchQuery,
      );

      schedules = raw.map((e) => ScheduleLocalModel.fromJson(e)).toList();

      // Simpan ke Hive sebagai cache
      final box = Hive.box<ScheduleLocalModel>('schedules');
      await box.clear();
      for (final s in schedules) {
        await box.put(s.id, s);
      }

      await _loadStats(idJurusan);
    } catch (e) {
      errorMsg = e.toString();
      // Fallback ke Hive
      final box = Hive.box<ScheduleLocalModel>('schedules');
      schedules = box.values.toList();
    }

    _setLoading(false);
  }

  /// Load data khusus dashboard (stats + 5 jadwal terbaru).
  Future<void> loadDashboard(String idJurusan) async {
    _setLoading(true);

    try {
      await _loadStats(idJurusan);

      final raw = await service.getRecentSchedules(idJurusan);
      recentSchedules = raw.map((e) => ScheduleLocalModel.fromJson(e)).toList();
    } catch (e) {
      errorMsg = e.toString();
    }

    _setLoading(false);
  }

  Future<void> _loadStats(String idJurusan) async {
    final stats = await service.getStatusCounts(idJurusan);
    countDraft = stats['draft'] ?? 0;
    countFinal = stats['final'] ?? 0;
    countPublished = stats['published'] ?? 0;
    total = stats['total'] ?? 0;
  }

  // ─────────────────────────────────────────────────
  // FILTER & SEARCH
  // ─────────────────────────────────────────────────

  void setFilter({String? hari, String? status, String? tipe}) {
    filterHari = hari;
    filterStatus = status;
    filterTipe = tipe;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void clearFilter() {
    filterHari = null;
    filterStatus = null;
    filterTipe = null;
    searchQuery = '';
    notifyListeners();
  }

  // ─────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────

  /// Return true jika berhasil, false jika collision.
  Future<bool> createSchedule({
    required String idJurusan,
    required String idProdi,
    required String idMk,
    required String namaMk,
    required String kodeMk,
    required String idPeriode,
    required String tipe,
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    required String ruangan,
    required String namaDosen,
  }) async {
    collisionDetail = null;

    // Cek collision dulu
    final conflict = await service.detectCollision(
      hari: hari,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      ruangan: ruangan,
      namaDosen: namaDosen,
      namaMk: namaMk,
    );

    if (conflict != null) {
      collisionDetail = conflict;
      notifyListeners();
      return false;
    }

    final success = await service.createSchedule({
      'id_mk': idMk,
      'nama_mk': namaMk,
      'kode_mk': kodeMk,
      'id_prodi': idProdi,
      'id_jurusan': idJurusan,
      'id_periode': idPeriode,
      'tipe': tipe,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'ruangan': ruangan,
      'nama_dosen': namaDosen,
    });

    if (success) await loadSchedules(idJurusan);
    return success;
  }

  // ─────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────

  Future<bool> updateSchedule({
    required String id,
    required String idJurusan,
    required String namaMk,
    required String tipe,
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    required String ruangan,
    required String namaDosen,
  }) async {
    collisionDetail = null;

    final conflict = await service.detectCollision(
      hari: hari,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      ruangan: ruangan,
      namaDosen: namaDosen,
      namaMk: namaMk,
      excludeId: id,
    );

    if (conflict != null) {
      collisionDetail = conflict;
      notifyListeners();
      return false;
    }

    final success = await service.updateSchedule(id, {
      'tipe': tipe,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'ruangan': ruangan,
      'nama_dosen': namaDosen,
    });

    if (success) await loadSchedules(idJurusan);
    return success;
  }

  // ─────────────────────────────────────────────────
  // FINALIZE
  // ─────────────────────────────────────────────────

  Future<bool> finalizeSchedule(String id, String idJurusan) async {
    final success = await service.finalizeSchedule(id);
    if (success) await loadSchedules(idJurusan);
    return success;
  }

  // ─────────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────────

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  void clearError() {
    errorMsg = null;
    notifyListeners();
  }

  void clearCollision() {
    collisionDetail = null;
    notifyListeners();
  }
}
