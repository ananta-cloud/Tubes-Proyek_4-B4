import 'package:flutter/material.dart';
import 'package:sigma/data/services/schedule_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  List<Map<String, dynamic>> schedules = [];
  bool isLoading = false;

  Future<void> fetchSchedules() async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await _service.getSchedules();
      schedules = data;

      print("✅ SCHEDULE LOADED: ${schedules.length}");
    } catch (e) {
      print("❌ ERROR SCHEDULE: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}
