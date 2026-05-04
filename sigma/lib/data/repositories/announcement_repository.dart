import 'package:hive/hive.dart';
// Sesuaikan path import ini jika berbeda di komputer Anda
<<<<<<< HEAD
import 'package:sigma/data/models/announcement_model.dart'; 

class AnnouncementRepository {
  // Membuka koneksi ke Box Hive menggunakan model yang baru
  final Box<AnnouncementModel> _box = Hive.box<AnnouncementModel>('announcements');
=======
import 'package:sigma/features/admin_tu/announcements/models/announcement_model.dart';

class AnnouncementRepository {
  // Membuka koneksi ke Box Hive menggunakan model yang baru
  final Box<AnnouncementModel> _box = Hive.box<AnnouncementModel>(
    'announcements',
  );
>>>>>>> nazriel

  // Mengambil semua data & diurutkan dari yang terbaru (Descending)
  List<AnnouncementModel> getAllAnnouncements() {
    final list = _box.values.toList();
    // Menggunakan variabel 'tanggal' untuk sorting
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Mengambil data berdasarkan target audience (UMUM / DOSEN / MAHASISWA, dll)
  List<AnnouncementModel> getAnnouncementsByCategory(String targetAudience) {
<<<<<<< HEAD
    final list = _box.values.where((a) => a.targetAudience == targetAudience).toList();
=======
    final list = _box.values
        .where((a) => a.targetAudience == targetAudience)
        .toList();
>>>>>>> nazriel
    // Menggunakan variabel 'tanggal' untuk sorting
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Fungsi untuk menyimpan data baru dari API ke Hive (Upsert)
<<<<<<< HEAD
  Future<void> saveAnnouncements(List<AnnouncementModel> newAnnouncements) async {
    for (var item in newAnnouncements) {
      await _box.put(item.id, item); // Gunakan id sebagai key agar tidak duplikat/tertimpa
    }
  }
  
=======
  Future<void> saveAnnouncements(
    List<AnnouncementModel> newAnnouncements,
  ) async {
    for (var item in newAnnouncements) {
      await _box.put(
        item.id,
        item,
      ); // Gunakan id sebagai key agar tidak duplikat/tertimpa
    }
  }

>>>>>>> nazriel
  // (Opsional) Fungsi tambahan jika Anda ingin menghapus semua data lama sebelum sinkronisasi baru
  Future<void> clearAll() async {
    await _box.clear();
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> nazriel
