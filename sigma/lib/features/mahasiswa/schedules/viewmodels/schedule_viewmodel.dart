import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sigma/data/models/schedule_model.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/services/schedule_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  List<ScheduleModel> schedules = [];
  bool isLoading = false;
  String? errorMessage;

  // Ambil dari Hive (cache lokal) dulu, lalu sync dari MongoDB
  Future<void> syncSchedules(UserModel user) async {
    final box = Hive.box<ScheduleModel>('schedules');
    schedules = box.values.toList();
    notifyListeners();

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      String queryParam = '';
      final role = user.role.toUpperCase();

      if (role == 'MAHASISWA') {
        queryParam = user.profilMahasiswa?.idKelas ?? user.profilMahasiswa?.kelas?.id ?? '';
        
        if (queryParam.isEmpty) {
          throw Exception("ID Kelas mahasiswa tidak ditemukan");
        }
      } else if (role == 'DOSEN') {
        queryParam = user.nama; 
      } else {
        return;
      }

      // 👉 Kirim query (ID Kelas / Nama Dosen) ke Service
      final rawData = await _service.getSchedules(queryParam);

      // 👉 Parse data DULU sebelum menghapus cache (Mencegah Blank jika jaringan error)
      final List<ScheduleModel> parsedSchedules = [];
      for (final item in rawData) {
        parsedSchedules.add(ScheduleModel.fromJson(item));
      }

      // Jika parsing aman 100%, baru hapus cache lama dan timpa dengan yang baru
      await box.clear();
      for (final model in parsedSchedules) {
        await box.put(model.id, model);
      }

      schedules = box.values.toList();
      print("✅ SCHEDULE SYNCED UNTUK ID/NAMA: $queryParam, TOTAL: ${schedules.length} item");
    } catch (e) {
      print("❌ ERROR SCHEDULE SYNC: $e");
      errorMessage = e.toString();
      schedules = box.values.toList(); // Tetap tampilkan data lokal jika gagal sync
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper untuk konversi waktu agar sorting presisi
  int _timeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final parts = timeStr.split(RegExp(r'[:.]'));
    if (parts.length >= 2) {
      return (int.tryParse(parts[0].trim()) ?? 0) * 60 + (int.tryParse(parts[1].trim()) ?? 0);
    }
    return 0;
  }

  // Kelompokkan jadwal & Gabungkan blok jam (Merge)
  Map<String, List<ScheduleModel>> get scheduleByDay {
    final Map<String, List<ScheduleModel>> groupedRaw = {};
    
    for (final s in schedules) {
      final hariClean = s.hari.trim().toUpperCase(); 
      groupedRaw.putIfAbsent(hariClean, () => []).add(s);
    }
    
    final Map<String, List<ScheduleModel>> mergedAndSorted = {};
    const urutanHari = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
    
    for (final h in urutanHari) {
      if (groupedRaw.containsKey(h)) {
        final listHariIni = groupedRaw[h]!;
        
        listHariIni.sort((a, b) => _timeToMinutes(a.jamMulai).compareTo(_timeToMinutes(b.jamMulai)));
        
        final List<ScheduleModel> mergedList = [];
        
        for (final item in listHariIni) {
          if (mergedList.isEmpty) {
            mergedList.add(item);
          } else {
            final lastItem = mergedList.last;
            
            if (lastItem.namaMatkul == item.namaMatkul && 
                lastItem.ruangan == item.ruangan &&
                lastItem.tePr == item.tePr) {
                  
              mergedList[mergedList.length - 1] = lastItem.copyWith(
                jamSelesai: item.jamSelesai
              );
            } else {
              mergedList.add(item);
            }
          }
        }
        mergedAndSorted[h] = mergedList;
      }
    }
    
    return mergedAndSorted;
  }

  // Jadwal Hari Ini
  List<ScheduleModel> get todaySchedules {
    const hariMap = {
      1: 'SENIN', 2: 'SELASA', 3: 'RABU', 4: 'KAMIS', 5: 'JUMAT', 6: 'SABTU', 7: 'MINGGU',
    };
    final hariIni = hariMap[DateTime.now().weekday] ?? '';
    return scheduleByDay[hariIni] ?? [];
  }
}