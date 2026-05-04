import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sigma/data/models/schedule_local_model.dart';
import 'package:sigma/data/services/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService service;

  ScheduleController(this.service);

  List<ScheduleLocalModel> schedules = [];
  bool isLoading = false;
  String? errorMsg;

  Future<void> syncSchedules({String idJurusan = '12345'}) async {
    isLoading = true;
    notifyListeners();

    final box = Hive.box<ScheduleLocalModel>('schedules');

    try {
      // Ambil data dari Service dengan parameter idJurusan
      final List<Map<String, dynamic>> list = await service.getSchedules(
        idJurusan: idJurusan,
      );

      // Clear cache lama di Hive
      await box.clear();

      // Mapping Mongo Map -> Model menggunakan factory yang sudah kita perbaiki
      for (var item in list) {
        final schedule = ScheduleLocalModel.fromJson(item);
        await box.put(schedule.id, schedule);
      }

      schedules = box.values.toList();
    } catch (e) {
      print("ERROR SYNC: $e");
      errorMsg = e.toString();
      // Fallback ke data offline
      schedules = box.values.toList();
    }

    isLoading = false;
    notifyListeners();
  }
}
