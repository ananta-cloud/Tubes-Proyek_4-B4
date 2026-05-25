import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sigma/data/models/schedule_local_model.dart';
import 'package:sigma/data/services/schedule_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  List<ScheduleLocalModel> schedules = [];
  bool isLoading = false;
  String? errorMessage;

  // Ambil dari Hive (cache lokal) dulu, lalu sync dari MongoDB
  Future<void> syncSchedules() async {
    // 1. Tampilkan data lokal dulu agar UI tidak kosong
    final box = Hive.box<ScheduleLocalModel>('schedules');
    schedules = box.values.toList();
    notifyListeners();

    // 2. Tarik data terbaru dari MongoDB
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final rawData = await _service.getSchedules();

      // 3. Simpan ke Hive (clear dulu agar tidak duplikat)
      await box.clear();
      for (final item in rawData) {
        final model = ScheduleLocalModel.fromJson(item);
        await box.put(model.id, model);
      }

      // 4. Update list dari Hive yang sudah diperbarui
      schedules = box.values.toList();
      print("SCHEDULE SYNCED: ${schedules.length} item");
    } catch (e) {
      print("ERROR SCHEDULE SYNC: $e");
      // Tetap pakai data lokal jika error
      schedules = box.values.toList();
    }

    isLoading = false;
    notifyListeners();
  }

  // Kelompokkan jadwal berdasarkan hari untuk tampilan
  Map<String, List<ScheduleLocalModel>> get scheduleByDay {
    final Map<String, List<ScheduleLocalModel>> grouped = {};
    for (final s in schedules) {
      grouped.putIfAbsent(s.hari, () => []).add(s);
    }
    // Urutkan berdasarkan urutan hari
    const urutanHari = [
      'SENIN',
      'SELASA',
      'RABU',
      'KAMIS',
      'JUMAT',
      'SABTU',
      'MINGGU',
    ];
    return Map.fromEntries(
      urutanHari
          .where((h) => grouped.containsKey(h))
          .map((h) => MapEntry(h, grouped[h]!)),
    );
  }

  // Jadwal untuk hari ini saja
  List<ScheduleLocalModel> get todaySchedules {
    const hariMap = {
      1: 'SENIN',
      2: 'SELASA',
      3: 'RABU',
      4: 'KAMIS',
      5: 'JUMAT',
      6: 'SABTU',
      7: 'MINGGU',
    };
    final hariIni = hariMap[DateTime.now().weekday] ?? '';
    return schedules.where((s) => s.hari == hariIni).toList();
  }
}
