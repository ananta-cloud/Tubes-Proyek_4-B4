import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import 'package:kampus_ku_mobile/features/announcements/data/models/announcement_local_model.dart';
import 'package:kampus_ku_mobile/features/announcements/data/services/announcement_service.dart';

class AnnouncementController extends ChangeNotifier {
  final AnnouncementService service;

  List<AnnouncementLocalModel> announcements = [];
  bool isLoading = false;

  AnnouncementController(this.service);

  Future<void> syncAnnouncements() async {
    isLoading = true;
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<AnnouncementLocalModel>('announcements');

    // ================= OFFLINE MODE =================
    bool isOffline = false;
    if (connectivityResult is List) {
      isOffline = connectivityResult.contains(ConnectivityResult.none);
    } else {
      isOffline = (connectivityResult == ConnectivityResult.none);
    }

    if (isOffline) {
      announcements = box.values.toList();
      isLoading = false;
      notifyListeners();

      print("📡 OFFLINE MODE - Loaded ${announcements.length} announcements from Hive");
      return;
    }

    // ================= ONLINE MODE =================
    try {
      final List<Map<String, dynamic>> list = await service.getAnnouncements();
      print("🌐 DATA ANNOUNCEMENT FROM API: ${list.length}");

      // Clear data Hive lama HANYA jika berhasil narik data dari API
      await box.clear();

      for (var item in list) {
        // Cukup panggil fromJson, lebih rapi dan bersih!
        final announcement = AnnouncementLocalModel.fromJson(item);
        await box.put(announcement.id, announcement);
      }

      // Update state ke UI
      announcements = box.values.toList();
      print("✅ SYNC SUCCESS: ${announcements.length} announcements saved to Hive");

    } catch (e) {
      print("❌ ERROR SYNC ANNOUNCEMENTS: $e");

      // Fallback: Jika API mati/error (500), tetap tampilkan data lama dari Hive
      announcements = box.values.toList();
      print("🔄 FALLBACK TO HIVE: ${announcements.length} announcements");
    }

    isLoading = false;
    notifyListeners();
  }

  // Helper opsional untuk otomatis menandai pengumuman penting
  bool _checkIfImportant(dynamic item) {
    String kategori = (item['target_audience'] ?? item['kategori'] ?? '').toString().toLowerCase();
    String judul = (item['judul'] ?? '').toString().toLowerCase();
    
    return kategori.contains('penting') || kategori.contains('dosen') || judul.contains('wajib');
  }
}