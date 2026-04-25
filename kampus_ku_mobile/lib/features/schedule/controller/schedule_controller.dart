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
    await box.clear();
    //  OFFLINE MODE
    if (connectivityResult == ConnectivityResult.none) {
      schedules = box.values.toList();
      isLoading = false;
      notifyListeners();
      print("OFFLINE MODE");
      return;
    }

    //  ONLINE MODE
    try {
      final List list = await service.getSchedules();

      await box.clear();

      for (var item in list) {
        final schedule = ScheduleLocalModel(
          id: item['id'] ?? item['_id'].toString(),
          namaMk: item['nama_mk'],
          hari: item['hari'],
          jamMulai: item['jam_mulai'],
          jamSelesai: item['jam_selesai'],
          ruangan: item['ruangan'],
          dosen: item['nama_dosen'],
        );

        await box.put(schedule.id, schedule);
      }

      schedules = box.values.toList();

      print("SYNC SUCCESS: ${schedules.length} data");
    } catch (e) {
      print("ERROR SYNC: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}
