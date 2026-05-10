import 'package:mongo_dart/mongo_dart.dart';
import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/announcement_model.dart';

class BookmarkService {
  
  ObjectId _safeObjectId(String id) {
    // Hilangkan karakter aneh agar murni sisa 24 digit Hex-nya saja
    String cleanId = id.replaceAll('ObjectId("', '').replaceAll('")', '').replaceAll("'", "").trim();
    return ObjectId.fromHexString(cleanId);
  }

  // 1. Simpan Bookmark ke MongoDB beserta Snapshot-nya
  Future<bool> saveBookmark(String userId, AnnouncementModel announcement) async {
    try {
      final collection = MongoDatabase.db.collection('bookmarks');
      
      final userObjId = _safeObjectId(userId);
      final annObjId = _safeObjectId(announcement.id);

      // Mencegah duplikasi data
      final existing = await collection.findOne(
        where.eq('id_user', userObjId).eq('id_announcement', annObjId)
      );

      if (existing == null) {
        await collection.insert({
          'id_user': userObjId,
          'id_announcement': annObjId,
          'announcement_snapshot': {
            'judul': announcement.judul,
            'isi': announcement.isi,
            'target_audience': announcement.targetAudience,
            'nama_publisher': announcement.namaPublisher,
            'kategori': announcement.kategori,
            'tingkat_kepentingan': announcement.tingkatKepentingan,
            'created_at': announcement.createdAt,
            'updated_at': announcement.updatedAt,
          },
          'bookmarked_at': DateTime.now(),
          'updated_at': DateTime.now(),
        });
        print("SUKSES MENGIRIM BOOKMARK KE MONGODB!");
      }
      return true;
    } catch (e) {
      print("Error Save Bookmark (Mongo): $e");
      return false;
    }
  }

  // 2. Hapus Bookmark dari MongoDB
  Future<bool> removeBookmark(String userId, String announcementId) async {
    try {
      final collection = MongoDatabase.db.collection('bookmarks');
      await collection.remove(
        where.eq('id_user', _safeObjectId(userId))
             .eq('id_announcement', _safeObjectId(announcementId))
      );
      print("SUKSES MENGHAPUS BOOKMARK DARI MONGODB!");
      return true;
    } catch (e) {
      print("Error Remove Bookmark (Mongo): $e");
      return false;
    }
  }

  // 3. Tarik semua Bookmark milik User dari MongoDB
  Future<List<Map<String, dynamic>>> getBookmarksByUser(String userId) async {
    try {
      final collection = MongoDatabase.db.collection('bookmarks');
      // Cari semua bookmark yang id_user-nya cocok dengan ID user yang sedang login
      final data = await collection.find(
        where.eq('id_user', _safeObjectId(userId))
      ).toList();
      
      return data;
    } catch (e) {
      print("🔥 Error Get Bookmarks (Mongo): $e");
      return [];
    }
  }
}