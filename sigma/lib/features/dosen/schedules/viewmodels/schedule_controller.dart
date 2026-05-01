import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../data/models/schedule_local_model.dart';
import '../../../../data/services/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService service;

  ScheduleController(this.service);

  List<ScheduleLocalModel> schedules = [];

  bool isLoading = false;
  String? errorMsg;

  Future<void> syncSchedules() async {
    isLoading = true;
    notifyListeners();

    final box = Hive.box<ScheduleLocalModel>('schedules');

    try {
      //  Ambil langsung dari Mongo
      final List<Map<String, dynamic>> list = await service.getSchedules(
        idJurusan: '12345',
      );

      print("MONGO DATA: ${list.length}");

      //  Clear cache lama
      await box.clear();

      //  Mapping Mongo → Model
      for (var item in list) {
        final schedule = ScheduleLocalModel(
          id: item['_id'].toString(), // ObjectId → String
          namaMk: item['nama_mk'] ?? '-',
          hari: item['hari'] ?? '-',
          jamMulai: item['jam_mulai'] ?? '-',
          jamSelesai: item['jam_selesai'] ?? '-',
          ruangan: item['ruangan'] ?? '-',
          dosen: item['nama_dosen'] ?? '-',
        );

        await box.put(schedule.id, schedule);
      }

      //  Load ke state
      schedules = box.values.toList();

      print("SYNC SUCCESS: ${schedules.length} schedules loaded");
    } catch (e) {
      print("ERROR MONGO SYNC: $e");

      //  fallback ke cache lokal
      schedules = box.values.toList();
      print("FALLBACK HIVE: ${schedules.length}");
    }

    isLoading = false;
    notifyListeners();
  }
}
