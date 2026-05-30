import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/network/mongo_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DosenCacheService
//
//  Menyimpan kode_dosen → nama_dosen ke Hive box 'dosen_cache' (Box<Map>).
//  Struktur tiap entry: key = kode_dosen, value = {'nama_dosen': '...'}
//
//  Dipanggil:
//    • Saat app online pertama kali  → DosenCacheService.warmUp()
//    • Saat koneksi pulih            → DosenCacheService.warmUp() lagi
//      (sudah terintegrasi di _ConnectivityListener via MongoDatabase.connect)
//
//  Parser (ScheduleExcelParser) hanya baca dari box ini — tidak perlu tahu
//  dari mana data asalnya.
// ─────────────────────────────────────────────────────────────────────────────
class DosenCacheService {
  DosenCacheService._();

  static const _kBox = 'dosen_cache';

  // ── Pastikan box sudah terbuka ─────────────────────────────────────────────
  // Panggil ini di main.dart setelah Hive.initFlutter(), sebelum runApp.
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_kBox)) {
      await Hive.openBox<Map>(_kBox);
    }
  }

  // ── Isi / refresh cache dari MongoDB ──────────────────────────────────────
  // Aman dipanggil berulang — hanya update yang berubah, tidak hapus semua.
  static Future<void> warmUp() async {
    try {
      final box = Hive.box<Map>(_kBox);

      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.dosenCollection.find().toList(),
      );

      final toSave = <String, Map>{};
      for (final d in docs) {
        final kode = d['kode_dosen']?.toString() ?? '';
        final nama = d['nama_dosen']?.toString() ?? '';
        if (kode.isNotEmpty && nama.isNotEmpty) {
          toSave[kode] = {'nama_dosen': nama};
        }
      }

      await box.putAll(toSave);
      debugPrint(' DosenCacheService.warmUp: ${toSave.length} dosen di-cache');
    } catch (e) {
      // Offline atau koneksi gagal — cache yang sudah ada tetap terpakai
      debugPrint(' DosenCacheService.warmUp gagal (offline?): $e');
    }
  }

  // ── Lookup satu kode (opsional, untuk kebutuhan lain) ─────────────────────
  static String? getNama(String kodeDosen) {
    if (!Hive.isBoxOpen(_kBox)) return null;
    final raw = Hive.box<Map>(_kBox).get(kodeDosen);
    return raw?['nama_dosen']?.toString();
  }

  // ── Lookup batch kode → nama ───────────────────────────────────────────────
  static Map<String, String> getAll(Set<String> kodes) {
    final result = <String, String>{};
    if (!Hive.isBoxOpen(_kBox)) return result;
    final box = Hive.box<Map>(_kBox);
    for (final kode in kodes) {
      final nama = box.get(kode)?['nama_dosen']?.toString();
      if (nama != null && nama.isNotEmpty) result[kode] = nama;
    }
    return result;
  }
}
//new