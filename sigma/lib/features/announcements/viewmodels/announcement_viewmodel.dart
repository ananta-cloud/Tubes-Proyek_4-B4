import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:sigma/data/models/announcement_model.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/data/services/announcement_service.dart';
import 'package:sigma/data/services/bookmark_service.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementService service;
  final BookmarkService _bookmarkService = BookmarkService();

  // State untuk daftar pengumuman
  List<AnnouncementModel> announcements = [];
  bool isLoading = false;
  String selectedFilter = 'SEMUA';
  final List<String> filters = [
    'SEMUA',
    'PENGABDIAN',
    'PENDIDIKAN',
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
  }

  // ==========================================
  // LOGIKA HALAMAN UTAMA (LIST)
  // ==========================================

  void setFilter(String filter) {
    selectedFilter = filter;
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
    isLoading = true;
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<AnnouncementModel>('announcements');

    bool isOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

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
      print("ERROR SINKRONISASI PENGUMUMAN: $e");
      _loadFromLocal();
    }

    isLoading = false;
    notifyListeners();
  }

  void _loadFromLocal() {
    final box = Hive.box<AnnouncementModel>('announcements');
    List<AnnouncementModel> all = box.values.toList();

    all.sort((a, b) {
      int weightA = _getPriorityWeight(a.tingkatKepentingan);
      int weightB = _getPriorityWeight(b.tingkatKepentingan);

      if (weightA != weightB) {
        return weightA.compareTo(weightB);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    if (selectedFilter != 'SEMUA') {
      announcements = all
          .where(
            (a) =>
                a.kategori.map((k) => k.toUpperCase()).contains(selectedFilter),
          )
          .toList();
    } else {
      announcements = all;
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
  Future<void> toggleBookmark(
    AnnouncementModel announcement,
    BuildContext context,
  ) async {
    final authVm = context.read<LoginViewModel>();
    final currentUserId = authVm.user?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login tidak valid. Silakan login ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isSaved = _bookmarkBox.containsKey(announcement.id);

    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Periksa koneksi internet Anda.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isSaved) {
      _bookmarkBox.delete(announcement.id);

      await _bookmarkService.removeBookmark(currentUserId, announcement.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dihapus dari Bookmark'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final clonedData = AnnouncementModel(
        id: announcement.id,
        judul: announcement.judul,
        isi: announcement.isi,
        targetAudience: announcement.targetAudience,
        idPublisher: announcement.idPublisher,
        namaPublisher: announcement.namaPublisher,
        rolePublisher: announcement.rolePublisher,
        idProdi: announcement.idProdi,
        idJurusan: announcement.idJurusan,
        targetAngkatan: announcement.targetAngkatan,
        kategori: announcement.kategori,
        tingkatKepentingan: announcement.tingkatKepentingan,
        createdAt: announcement.createdAt,
        updatedAt: announcement.updatedAt,
      );

      _bookmarkBox.put(announcement.id, clonedData);

      await _bookmarkService.saveBookmark(currentUserId, announcement);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disimpan ke Bookmark'),
          backgroundColor: Color(0xFFFF7A36),
          duration: Duration(seconds: 2),
        ),
      );
    }

    notifyListeners();
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
}
