import 'package:flutter/material.dart';
import 'package:kampus_ku_mobile/data/repositories/announcement_repository.dart';
import 'package:kampus_ku_mobile/data/models/announcement_model.dart';
import 'package:kampus_ku_mobile/data/services/announcement_service.dart';

class AnnouncementController extends ChangeNotifier {
  final AnnouncementRepository repository;
  final AnnouncementService service = AnnouncementService();

  AnnouncementController({required this.repository}) {
    // Saat controller dipanggil, langsung muat data
    loadAnnouncements();
    syncDataFromApi(); 
  }

  // STATE yang akan dibaca oleh UI
  List<AnnouncementModel> announcements = [];
  String selectedFilter = 'Semua';
  final List<String> filters = ['Semua', 'Jurusan', 'Umum'];

  // Fungsi mengubah filter
  void setFilter(String filter) {
    selectedFilter = filter;
    loadAnnouncements();
  }

  // Logika memuat data berdasarkan filter aktif
  void loadAnnouncements() {
    if (selectedFilter == 'Jurusan') {
      announcements = repository.getAnnouncementsByCategory('PRODI');
    } else if (selectedFilter == 'Umum') {
      announcements = repository.getAnnouncementsByCategory('UMUM');
    } else {
      announcements = repository.getAllAnnouncements();
    }
    
    // Beri tahu UI bahwa data berubah dan harus dirender ulang
    notifyListeners(); 
  }

  // Simulasi sinkronisasi data dari Backend Laravel
  Future<void> syncDataFromApi() async {
    // 1. Ambil data terbaru dari kurir (API)
    final List<AnnouncementModel> remoteData = await service.fetchAnnouncements();
    
    if (remoteData.isNotEmpty) {
      // 2. Simpan ke laci lokal (Hive)
      await repository.saveAnnouncements(remoteData);
      
      // 3. Muat ulang data dari Hive ke UI
      loadAnnouncements();
    }
  }
}