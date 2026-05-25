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
      // 👉 2. Ambil nama kelas dari user yang sedang login
      final String namaKelas = user.profilMahasiswa?.kelas?.namaKelas ?? '';
      
      if (namaKelas.isEmpty) {
        throw Exception("Data kelas mahasiswa tidak ditemukan");
      }

      // 👉 3. Kirim nama kelas ke Service
      final rawData = await _service.getSchedules(namaKelas);

      await box.clear();
      for (final item in rawData) {
        final model = ScheduleModel.fromJson(item);
        await box.put(model.id, model);
      }

      schedules = box.values.toList();
      print("SCHEDULE SYNCED UNTUK KELAS $namaKelas: ${schedules.length} item");
    } catch (e) {
      print("ERROR SCHEDULE SYNC: $e");
      schedules = box.values.toList();
    }

    isLoading = false;
    notifyListeners();
  }

  // ==================================================
  // 1. Kelompokkan jadwal & Gabungkan blok jam (Merge)
  // ==================================================
  Map<String, List<ScheduleModel>> get scheduleByDay {
    final Map<String, List<ScheduleModel>> groupedRaw = {};
    
    // 1. Masukkan semua jadwal ke dalam kelompok harinya masing-masing
    for (final s in schedules) {
      groupedRaw.putIfAbsent(s.hari, () => []).add(s);
    }
    
    final Map<String, List<ScheduleModel>> mergedAndSorted = {};
    
    const urutanHari = [
      'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU',
    ];
    
    for (final h in urutanHari) {
      if (groupedRaw.containsKey(h)) {
        final listHariIni = groupedRaw[h]!;
        
        // 2. Urutkan berdasarkan jam mulai (cth: "07.00" lalu "08.40")
        // String compareTo berfungsi sempurna karena format jam Anda "HH.mm"
        listHariIni.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
        
        // 3. Proses Penggabungan (Merging)
        final List<ScheduleModel> mergedList = [];
        
        for (final item in listHariIni) {
          if (mergedList.isEmpty) {
            mergedList.add(item);
          } else {
            final lastItem = mergedList.last;
            
            // Jika nama matkul, ruangan, dan jenisnya (Teori/Praktik) sama persis
            if (lastItem.namaMatkul == item.namaMatkul && 
                lastItem.ruangan == item.ruangan &&
                lastItem.tePr == item.tePr) {
                  
              // Ganti item terakhir dengan data baru yang 'jamSelesai'-nya diperpanjang
              mergedList[mergedList.length - 1] = lastItem.copyWith(
                jamSelesai: item.jamSelesai
              );
            } else {
              // Jika matkul berbeda, tambahkan sebagai jadwal baru di bawahnya
              mergedList.add(item);
            }
          }
        }
        
        // Simpan hasil yang sudah rapi
        mergedAndSorted[h] = mergedList;
      }
    }
    
    return mergedAndSorted;
  }

  // ==================================================
  // 2. Jadwal Hari Ini (Diambil dari data yang sudah di-merge)
  // ==================================================
  List<ScheduleModel> get todaySchedules {
    const hariMap = {
      1: 'SENIN', 2: 'SELASA', 3: 'RABU', 4: 'KAMIS', 5: 'JUMAT', 6: 'SABTU', 7: 'MINGGU',
    };
    final hariIni = hariMap[DateTime.now().weekday] ?? '';
    
    // Karena kita panggil scheduleByDay, 'Hari Ini' otomatis ikut rapi & tergabung!
    return scheduleByDay[hariIni] ?? [];
  }
}
