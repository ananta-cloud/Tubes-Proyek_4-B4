import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../data/models/schedule_local_model.dart';
import '../data/services/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService service;

  List<ScheduleLocalModel> schedules = [];
  bool isLoading = false;

  ScheduleController(this.service);

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
      final List<Map<String, dynamic>> list = await service.getSchedules();

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

  // Fungsi untuk Input Jadwal Baru
  Future<bool> createSchedule(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();

    try {
      // Panggil service untuk POST ke Laravel
      await service.postSchedule(data);

      // Setelah berhasil simpan, sinkronisasi ulang agar data lokal terupdate
      await syncSchedules();
      return true;
    } catch (e) {
      print("Error Create Schedule: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk Update Jadwal (Edit)
  Future<bool> updateSchedule(String id, Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();

    try {
      await service.putSchedule(id, data);
      await syncSchedules();
      return true;
    } catch (e) {
      print("Error Update Schedule: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk Finalisasi (DRAFT -> FINAL)
  Future<bool> finalizeSchedule(String id) async {
    try {
      await service.patchFinalize(id);
      await syncSchedules();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk Approve Request Perubahan dari Dosen
  Future<bool> approveRequest(String requestId, String? catatan) async {
    try {
      await service.patchApproveRequest(requestId, catatan);
      await syncSchedules(); // Sinkron karena jadwal asli ikut berubah
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk Reject Request
  Future<bool> rejectRequest(String requestId, String alasan) async {
    try {
      await service.patchRejectRequest(requestId, alasan);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool checkCollision(ScheduleLocalModel newJadwal) {}
}
