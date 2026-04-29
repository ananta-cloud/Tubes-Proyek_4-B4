import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../data/models/schedule_local_model.dart';
import '../data/services/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService service;

  ScheduleController(this.service);

  List<ScheduleLocalModel> schedules = [];

  bool isLoading = false;
  String? errorMsg;

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
}
