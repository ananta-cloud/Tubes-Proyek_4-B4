import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

// Pastikan path import ini sesuai dengan proyek Anda
import 'package:kampus_ku_mobile/data/models/announcement_model.dart';
import 'package:kampus_ku_mobile/data/services/announcement_service.dart';

class AnnouncementController extends ChangeNotifier {
  final AnnouncementService service;

  List<AnnouncementModel> announcements = [];
  bool isLoading = false;

  // ================= FILTER STATE =================
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
    syncAnnouncements(); // Sinkronisasi otomatis saat controller pertama kali diinisialisasi
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

    // Pengecekan koneksi mendukung connectivity_plus versi terbaru (List)
    bool isOffline = false;
    if (connectivityResult is List) {
      isOffline = connectivityResult.contains(ConnectivityResult.none);
    } else {
      isOffline = (connectivityResult == ConnectivityResult.none);
    }

    // ================= OFFLINE MODE =================
    if (isOffline) {
      print("📡 OFFLINE MODE - Memuat data dari Hive");
      _loadFromLocal();
      isLoading = false;
      notifyListeners();
      return;
    }

    // ================= ONLINE MODE =================
    try {
      final List<Map<String, dynamic>> list = await service.getAnnouncements();
      print("🌐 DATA ANNOUNCEMENT FROM API: ${list.length}");

      // Clear data Hive lama HANYA jika berhasil menarik data dari API
      await box.clear();

      for (var item in list) {
        final announcement = AnnouncementModel.fromJson(item);
        await box.put(announcement.id, announcement);
      }
      print("✅ SYNC SUCCESS: Data berhasil disimpan ke Hive");

      // Setelah berhasil simpan, muat ulang ke UI melewati fungsi filter
      _loadFromLocal();

    } catch (e) {
      print("❌ ERROR SYNC ANNOUNCEMENTS: $e");
      print("🔄 FALLBACK TO HIVE");
      // Fallback: Jika API mati/error (500), tetap tampilkan data lama dari Hive
      _loadFromLocal(); 
    }

    isLoading = false;
    notifyListeners();
  }

  // ================= HELPER METHODS =================

  /// Memuat data dari Hive, mengurutkan dari yang terbaru, dan menerapkan filter aktif
  void _loadFromLocal() {
    final box = Hive.box<AnnouncementModel>('announcements');
    List<AnnouncementModel> all = box.values.toList();

    // Urutkan dari yang terbaru ke terlama (Descending)
    // Asumsi properti model Anda bernama 'tanggal'
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

  /// Helper opsional untuk otomatis menandai pengumuman penting
  bool _checkIfImportant(dynamic item) {
    String kategori = (item['target_audience'] ?? item['kategori'] ?? '').toString().toLowerCase();
    String judul = (item['judul'] ?? '').toString().toLowerCase();
    
    return kategori.contains('penting') || kategori.contains('dosen') || judul.contains('wajib');
  }
}