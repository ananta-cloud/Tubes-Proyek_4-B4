import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/data/services/announcement_service.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementService service;

  List<AnnouncementModel> announcements = [];
  bool isLoading = false;
  String selectedFilter = 'SEMUA';

  final List<String> filters = [
    'SEMUA', 'AKADEMIK', 'BEASISWA', 'LOMBA', 'UKM', 'KARIR', 
    'PKM', 'WIRAUSAHA', 'KONSELING', 'FASILITAS', 'LAINNYA',
  ];

  AnnouncementViewModel(this.service) {
    syncAnnouncements();
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    _loadFromLocal();
  }

  Future<void> syncAnnouncements() async {
    isLoading = true;
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<AnnouncementModel>('announcements');

    bool isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      _loadFromLocal();
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final List<Map<String, dynamic>> list = await service.getAnnouncements();
      await box.clear();
      for (var item in list) {
        final announcement = AnnouncementModel.fromMongo(item);
        await box.put(announcement.id, announcement);
      }
      _loadFromLocal();
    } catch (e) {
      print("🔥 ERROR SINKRONISASI PENGUMUMAN: $e");
      _loadFromLocal(); 
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
          .where((a) => a.kategori.map((k) => k.toUpperCase()).contains(selectedFilter))
          .toList();
    } else {
      announcements = all;
    }
    notifyListeners();
  }
}