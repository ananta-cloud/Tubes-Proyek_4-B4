import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:sigma/data/models/announcement_model.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/data/services/announcement_service.dart';
import 'package:sigma/data/services/bookmark_service.dart';
import 'package:sigma/data/services/notification_service.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementService service;
  final BookmarkService _bookmarkService = BookmarkService();
  StreamSubscription? _notifSubscription;

  String currentUserRole = 'SEMUA';

  void setUserRole(String role) {
    final newRole = role.toUpperCase();
    if (currentUserRole != newRole) {
      currentUserRole = newRole;
      _loadFromLocal();
    }
  }

  // State untuk daftar pengumuman
  List<AnnouncementModel> announcements = [];
  bool isLoading = false;
  String selectedFilter = 'SEMUA';
  final List<String> filters = [
    'SEMUA',
    'PENGABDIAN',
    'PENGAJARAN',
    'PENELITIAN',
    'UMUM',
  ];

  // Box untuk bookmark
  late final Box<AnnouncementModel> _bookmarkBox;

  AnnouncementViewModel(this.service) {
    _bookmarkBox = Hive.box<AnnouncementModel>(
      'bookmarks',
    ); // Buka box bookmark
    syncAnnouncements();

    _notifSubscription = NotificationService.onNewNotification.stream.listen((_) {
      debugPrint("🔄 Mendapat Sinyal FCM! Menarik data pengumuman terbaru...");
      
      // Saat ada notif masuk, panggil lagi fungsi ini secara diam-diam
      syncAnnouncements(); 
    });
  }

  // ==========================================
  // LOGIKA HALAMAN UTAMA (LIST)
  // ==========================================

  void setFilter(String filter) {
    // Normalisasi: Jika string kosong atau "Semua" (dari Dosen), jadikan 'SEMUA'
    if (filter.isEmpty || filter.toUpperCase() == 'SEMUA') {
      selectedFilter = 'SEMUA';
    } else {
      selectedFilter = filter;
    }
    _loadFromLocal();
  }

  // ==========================================
  // HELPER PRIORITAS PENGURUTAN
  // ==========================================
  int _getPriorityWeight(String tingkat) {
    switch (tingkat.toUpperCase()) {
      case 'SANGAT PENTING':
        return 1;
      case 'PENTING':
        return 2;
      case 'BIASA':
      default:
        return 3;
    }
  }

  Future<void> syncAnnouncements() async {
    // 1. TAMPILKAN DATA LOKAL DULU (Offline-First)
    _loadFromLocal(); 

    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);

    // Jika offline, berhenti di sini. Mahasiswa tetap bisa baca pengumuman lokal.
    if (isOffline) return; 

    // 2. Ambil data baru dari MongoDB di belakang layar (Silent Sync)
    try {
      // PERBAIKAN: Gunakan 'service' bawaan kelas ini
      final announcementsList = await service.getAnnouncements();

      // PERBAIKAN: Deklarasikan box secara eksplisit
      final box = Hive.box<AnnouncementModel>('announcements');
      
      // Update penyimpanan lokal
      await box.clear();
      for (var item in announcementsList) {
        final announcement = AnnouncementModel.fromMongo(item);
        await box.put(announcement.id, announcement);
      }

      // Panggil juga antrean offline jika ada sinyal
      syncOfflineActions();

      // Muat ulang layar secara halus dengan data yang baru datang
      _loadFromLocal(); 
    } catch (e) {
      print("🔥 ERROR SINKRONISASI PENGUMUMAN: $e");
    }
  }

  void _loadFromLocal() {
    final box = Hive.box<AnnouncementModel>('announcements');
    List<AnnouncementModel> all = box.values.toList();

    all = all.where((a) {
      // Gunakan trim() untuk membersihkan spasi tidak sengaja
      final target = a.targetAudience.trim().toUpperCase();
      final myRole = currentUserRole.trim().toUpperCase();

      // 1. Pengumuman global tampil untuk semua
      if (target == 'SEMUA' || target == 'PRODI_SEMUA') return true;

      // 2. Filter spesifik berdasarkan role
      if (myRole == 'MAHASISWA') {
        return target == 'MAHASISWA' || target == 'PRODI_MAHASISWA';
      } else if (myRole == 'DOSEN') {
        return target == 'DOSEN' || target == 'PRODI_DOSEN';
      }

      // 3. Jika Admin TU yang melihat, tampilkan semua
      return true;
    }).toList();

    all.sort((a, b) {
      int weightA = _getPriorityWeight(a.tingkatKepentingan);
      int weightB = _getPriorityWeight(b.tingkatKepentingan);

      if (weightA != weightB) {
        return weightA.compareTo(weightB);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    // LOGIKA FILTER DIPERBAIKI DI SINI
    if (selectedFilter == 'SEMUA') {
      announcements = all;
    } else if (selectedFilter == 'Informasi Umum') {
      // Filter khusus Dosen: Target audience tertentu ATAU tag kategori manual
      announcements = all.where((a) {
        return a.targetAudience == 'SEMUA' ||
            a.targetAudience == 'SEMUA_DOSEN' ||
            a.targetAudience == 'JURUSAN' ||
            a.kategori.map((k) => k.toUpperCase()).contains('INFORMASI UMUM');
      }).toList();
    } else {
      // Filter dinamis untuk kategori lainnya (Mahasiswa maupun Dosen)
      announcements = all.where((a) {
        // Mengubah tag kategori menjadi uppercase untuk dicocokkan (case-insensitive)
        return a.kategori
            .map((k) => k.toUpperCase())
            .contains(selectedFilter.toUpperCase());
      }).toList();
    }
    notifyListeners();
  }

  // ==========================================
  // LOGIKA HALAMAN DETAIL & BOOKMARK
  // ==========================================

  // Mengecek apakah pengumuman tertentu sudah dibookmark
  bool isBookmarked(String id) {
    return _bookmarkBox.containsKey(id);
  }

  // Menambah / menghapus bookmark (Lokal + Cloud)
  Future<void> toggleBookmark(AnnouncementModel announcement, BuildContext context) async {
    final authVm = context.read<LoginViewModel>();
    final currentUserId = authVm.user?.id;

    if (currentUserId == null) return; // Cegah jika belum login

    // 1. OPTIMISTIC UI: Langsung ubah di lokal!
    final isBookmarked = _bookmarkBox.containsKey(announcement.id);
    
    if (isBookmarked) {
      await _bookmarkBox.delete(announcement.id);
    } else {
      // 🔥 PERBAIKAN: Gandakan (Clone) objek sebelum dimasukkan ke Box lain
      // Kita manfaatkan toJson dan fromJson yang sudah kita buat sebelumnya
      final announcementClone = AnnouncementModel.fromJson(announcement.toJson());
      
      await _bookmarkBox.put(announcement.id, announcementClone);
    }
    notifyListeners(); // Refresh layar seketika!

    // 2. Cek Koneksi Internet
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(ConnectivityResult.none);

    if (isOffline) {
      // 3. Masukkan ke Antrean jika Offline
      final queueBox = Hive.box('student_action_queue');
      await queueBox.add({
        'action': isBookmarked ? 'remove_bookmark' : 'add_bookmark',
        'user_id': currentUserId,
        'announcement': announcement.toJson(), 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline: Bookmark disimpan sementara.')),
      );
      return;
    }

    // 4. Jika Online, kirim langsung ke MongoDB
    try {
      if (isBookmarked) {
        await _bookmarkService.removeBookmark(currentUserId, announcement.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark dihapus')),
        );
      } else {
        await _bookmarkService.saveBookmark(currentUserId, announcement);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark berhasil disimpan!')),
        );
      }
    } catch (e) {
      print("Bookmark Error: $e");
    }
  }

  // Helper Format Teks
  String formatAudience(String audience) {
    return audience.replaceAll('_', ' ');
  }

  // Helper Format Tanggal
  String formatDate(DateTime dt) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  // Sinkronisasi Tarik Bookmark dari Cloud (saat baru buka app/login)
  Future<void> syncBookmarks(String currentUserId) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

    if (isOffline) return;

    try {
      final List<Map<String, dynamic>> mongoBookmarks = await _bookmarkService
          .getBookmarksByUser(currentUserId);

      await _bookmarkBox.clear();

      for (var item in mongoBookmarks) {
        if (item['announcement_snapshot'] != null) {
          final snapshot =
              item['announcement_snapshot'] as Map<String, dynamic>;

          snapshot['_id'] = item['id_announcement'];

          final announcement = AnnouncementModel.fromMongo(snapshot);
          await _bookmarkBox.put(announcement.id, announcement);
        }
      }
      notifyListeners();
      print("SUKSES MENARIK ${mongoBookmarks.length} BOOKMARK DARI CLOUD!");
    } catch (e) {
      print("ERROR SINKRONISASI BOOKMARK: $e");
    }
  }

  // Fungsi ini dipanggil saat HP kembali Online
  Future<void> syncOfflineActions() async {
    final queueBox = Hive.box('student_action_queue');
    if (queueBox.isEmpty) return; 

    print("🔄 Menjalankan sinkronisasi aksi offline mahasiswa (Bookmark)...");

    final keys = queueBox.keys.toList();
    for (var key in keys) {
      final item = queueBox.get(key);
      if (item == null) continue; // Keamanan tambahan

      final action = item['action'];
      
      if (action == 'add_bookmark' || action == 'remove_bookmark') {
        final userId = item['user_id'];
        final annData = item['announcement'];

        // Pastikan annData tidak Null sebelum diubah jadi JSON
        if (annData != null) {
          final announcement = AnnouncementModel.fromJson(Map<String, dynamic>.from(annData));

          try {
            if (action == 'add_bookmark') {
              await _bookmarkService.saveBookmark(userId, announcement);
            } else if (action == 'remove_bookmark') {
              await _bookmarkService.removeBookmark(userId, announcement.id);
            }
            
            // Hapus dari antrean hanya jika berhasil
            await queueBox.delete(key); 
          } catch (e) {
            print("Gagal sync antrean bookmark: $e");
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _notifSubscription?.cancel(); // Matikan pendengar saat ViewModel dihancurkan
    super.dispose();
  }
}
