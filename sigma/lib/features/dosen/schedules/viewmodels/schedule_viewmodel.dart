import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sigma/data/models/schedule_local_model.dart';
import 'package:sigma/data/services/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService service;
  ScheduleController(this.service);

  List<ScheduleLocalModel> schedules = [];
  List<ScheduleLocalModel> dosenSchedules = [];
  bool isLoading = false;
  String? errorMsg;

  // Untuk mahasiswa — sync by idJurusan
  Future<void> syncSchedules({String idJurusan = '12345'}) async {
    isLoading = true;
    notifyListeners();

    final box = Hive.box<ScheduleLocalModel>('schedules');

    try {
      final list = await service.getSchedules(idJurusan: idJurusan);
      await box.clear();
      for (var item in list) {
        final s = ScheduleLocalModel.fromJson(item);
        await box.put(s.id, s);
      }
      schedules = box.values.toList();
    } catch (e) {
      errorMsg = e.toString();
      schedules = box.values.toList();
    }

    isLoading = false;
    notifyListeners();
  }

  // Untuk dosen — filter by kode_dosen
  Future<void> syncDosenSchedules(String kodeDosen) async {
    isLoading = true;
    notifyListeners();

    try {
      final list = await service.getSchedulesByKodeDosen(kodeDosen);
      dosenSchedules = list.map((e) => ScheduleLocalModel.fromJson(e)).toList();
    } catch (e) {
      errorMsg = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    errorMsg = null;
    notifyListeners();
  }
}
