<<<<<<< HEAD
import 'package:sigma/core/network/api_client.dart'; 
=======
import 'package:sigma/core/network/mongo_database.dart';
>>>>>>> nazriel

class AnnouncementService {
  
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
<<<<<<< HEAD
      // Memanggil endpoint API (pastikan base URL di ApiClient sudah benar)
      final res = await ApiClient.get("/announcements");
      
      // Jika response dari server ternyata error (misal token kedaluwarsa atau server mati)
      if (res['status'] == 'error' || res['success'] == false) {
        throw Exception(res['message'] ?? 'Gagal mengambil data pengumuman'); 
      }
      
      // Jika data kosong
      if (res['data'] == null) return [];
      
      // Mengembalikan List of Map (JSON) untuk diproses oleh AnnouncementController
      return List<Map<String, dynamic>>.from(res['data']);

    } catch (e) {
      print("❌ Error AnnouncementService: $e");
      rethrow; // Lempar error ke Controller agar memicu mode Fallback (Offline)
=======
      // Langsung ambil dari koleksi MongoDB, tidak perlu HTTP/API Laravel
      final announcements = await MongoDatabase.announcementsCollection.find().toList();
      return announcements;
    } catch (e) {
      print("❌ Error AnnouncementService (Mongo): $e");
      rethrow; 
>>>>>>> nazriel
    }
  }
}