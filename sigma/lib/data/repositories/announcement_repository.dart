import 'package:hive/hive.dart';
import '../../../../data/models/announcement_model.dart';

class AnnouncementRepository {
  // Membuka koneksi ke Box Hive
  final Box<AnnouncementModel> _box = Hive.box<AnnouncementModel>('announcements');

  // Mengambil semua data & diurutkan dari yang terbaru
  List<AnnouncementModel> getAllAnnouncements() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Mengambil data berdasarkan kategori (UMUM / PRODI)
  List<AnnouncementModel> getAnnouncementsByCategory(String targetAudience) {
    final list = _box.values.where((a) => a.targetAudience == targetAudience).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Fungsi untuk menyimpan data baru dari API ke Hive (Upsert)
  Future<void> saveAnnouncements(List<AnnouncementModel> newAnnouncements) async {
    for (var item in newAnnouncements) {
      await _box.put(item.id, item); // Gunakan id sebagai key agar tidak duplikat
    }
  }
}