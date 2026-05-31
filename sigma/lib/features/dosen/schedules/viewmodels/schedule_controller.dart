import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../data/models/schedule_local_model.dart';
import 'package:sigma/data/services/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService service;
  ScheduleController(this.service);

  List<ScheduleLocalModel> schedules = [];
  bool isLoading = false;
  String? errorMsg;
  
  bool _hasLoaded = false;

  Future<void> syncSchedules({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh && schedules.isNotEmpty) return;

    isLoading = true;
    notifyListeners();

    final box = Hive.box<ScheduleLocalModel>('schedules');

    try {
      final List<Map<String, dynamic>> list = await service.getSchedules();

      await box.clear();

      for (var item in list) {
        final schedule = ScheduleLocalModel(
          id: item['_id'].toString(), 
          namaMk: item['nama_mk'] ?? '-',
          hari: item['hari'] ?? '-',
          jamMulai: item['jam_mulai'] ?? '-',
          jamSelesai: item['jam_selesai'] ?? '-',
          ruangan: item['ruangan'] ?? '-',
          dosen: item['nama_dosen'] ?? '-',
        );
        await box.put(schedule.id, schedule);
      }

      schedules = box.values.toList();
      _hasLoaded = true; 
      
    } catch (e) {
      print("ERROR MONGO SYNC: $e");
      schedules = box.values.toList();
    }

    isLoading = false;
    notifyListeners();
  }
}