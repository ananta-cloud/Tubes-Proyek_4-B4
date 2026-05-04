import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sigma/features/admin_tu/announcements/models/announcement_model.dart';

class AnnouncementDetailViewModel extends ChangeNotifier {
  late final Box<AnnouncementModel> _bookmarkBox;

  bool _isBookmarked = false;
  bool get isBookmarked => _isBookmarked;

  AnnouncementDetailViewModel() {
    _bookmarkBox = Hive.box<AnnouncementModel>('bookmarks');
  }

  /// Cek status awal saat halaman dibuka
  void checkBookmarkStatus(String id) {
    _isBookmarked = _bookmarkBox.containsKey(id);
    notifyListeners();
  }

  /// Toggle status bookmark dan kembalikan status terbarunya
  /// agar View bisa menampilkan SnackBar yang sesuai.
  bool toggleBookmark(AnnouncementModel announcement) {
    _isBookmarked = !_isBookmarked;
    notifyListeners();

    if (_isBookmarked) {
      _bookmarkBox.put(announcement.id, announcement);
    } else {
      _bookmarkBox.delete(announcement.id);
    }

    return _isBookmarked;
  }

  // ================= HELPER METHODS =================

  String formatAudience(String audience) {
    return audience.replaceAll('_', ' ');
  }

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
}
