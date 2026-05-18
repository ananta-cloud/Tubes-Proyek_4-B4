import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/announcement_model.dart';

class AnnouncementViewModel extends ChangeNotifier {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  int get thisMonthCount {
    final now = DateTime.now();
    return _announcements
        .where(
          (a) => a.createdAt.year == now.year && a.createdAt.month == now.month,
        )
        .length;
  }

  // Placeholder — nanti bisa dihitung dari koleksi terpisah (read_receipts)
  int get totalRead => 0;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    notifyListeners();
    try {
      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.announcementsCollection.find().toList(),
      );
      _announcements = docs.map((d) => AnnouncementModel.fromMongo(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ AnnouncementViewModel.fetchAnnouncements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAnnouncement({
    required String judul,
    required String isi,
    required String kategori,
    required String target,
    String idPublisher = '',
    String namaPublisher = 'Ibu Admin TU',
    String rolePublisher = 'ADMIN_TU',
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final doc = {
        '_id': ObjectId(),
        'judul': judul,
        'isi': isi,
        'kategori': [kategori],
        'target_audience': target,
        'id_publisher': idPublisher.isNotEmpty
            ? ObjectId.fromHexString(idPublisher)
            : ObjectId(),
        'nama_publisher': namaPublisher,
        'role_publisher': rolePublisher,
        'tingkat_kepentingan': 'BIASA',
        'created_at': now,
        'updated_at': now,
      };
      await MongoDatabase.runSafe(
        () => MongoDatabase.announcementsCollection.insertOne(doc),
      );
      await fetchAnnouncements(); // refresh list
    } catch (e) {
      debugPrint('❌ AnnouncementViewModel.createAnnouncement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
