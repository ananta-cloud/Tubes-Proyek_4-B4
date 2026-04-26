import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../data/models/announcement_model.dart';
import '../data/services/announcement_service.dart';

class AnnouncementController extends ChangeNotifier {
  final AnnouncementService service;
  
  List<AnnouncementModel> announcements = [];
  bool isLoading = false;
  String selectedFilter = 'SEMUA';
  final List<String> filters = [
    'SEMUA',
    'AKADEMIK',
    'BEASISWA',
    'LOMBA',
    'UKM',
    'KARIR',
    'PKM',
    'WIRAUSAHA',
    'KONSELING',
    'FASILITAS',
    'LAINNYA',
  ];

  AnnouncementController(this.service) {
    syncAnnouncements(); // Sinkronisasi otomatis saat pertama kali dibuka
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    _loadFromLocal(); // Muat ulang data dari Hive dengan filter baru
  }

  Future<void> syncAnnouncements() async {
    isLoading = true;
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<AnnouncementModel>('announcements');

    // --- 1. JIKA OFFLINE ---
    if (connectivityResult == ConnectivityResult.none) {
      _loadFromLocal();
      isLoading = false;
      notifyListeners();
      return;
    }

    // --- 2. JIKA ONLINE ---
    try {
      final remoteData = await service.getAnnouncements();
      
      await box.clear(); // Bersihkan cache lama agar sinkron dengan server
      for (var item in remoteData) {
        await box.put(item.id, item); // Simpan ke laci lokal (Hive)
      }
      
      _loadFromLocal();
    } catch (e) {
      print("SYNC ERROR: $e");
      _loadFromLocal(); // Fallback ke data lokal jika API gagal
    }

    isLoading = false;
    notifyListeners();
  }

  void _loadFromLocal() {
    final box = Hive.box<AnnouncementModel>('announcements');
    List<AnnouncementModel> all = box.values.toList();

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (selectedFilter != 'SEMUA') {
      announcements = all
          .where((a) => a.kategori.contains(selectedFilter))
          .toList();
    } else {
      announcements = all;
    }

    notifyListeners();
  }
}