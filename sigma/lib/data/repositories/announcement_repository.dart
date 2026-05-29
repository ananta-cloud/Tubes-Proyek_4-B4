import 'package:hive/hive.dart';
import 'package:sigma/data/models/announcement_model.dart';

class AnnouncementRepository {
  final Box<AnnouncementModel> _box = Hive.box<AnnouncementModel>(
    'announcements',
  );

  // Mengambil semua data & diurutkan dari yang terbaru (Descending)
  List<AnnouncementModel> getAllAnnouncements() {
    final list = _box.values.toList();
    // Menggunakan variabel 'tanggal' untuk sorting
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Mengambil data berdasarkan target audience (UMUM / DOSEN / MAHASISWA, dll)
  List<AnnouncementModel> getAnnouncementsByCategory(String targetAudience) {
    final list = _box.values
        .where((a) => a.targetAudience == targetAudience)
        .toList();
    // Menggunakan variabel 'tanggal' untuk sorting
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Fungsi untuk menyimpan data baru dari API ke Hive
  Future<void> saveAnnouncements(
    List<AnnouncementModel> newAnnouncements,
  ) async {
    for (var item in newAnnouncements) {
      await _box.put(item.id, item);
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
