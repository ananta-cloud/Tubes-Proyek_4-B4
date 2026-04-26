import 'package:kampus_ku_mobile/core/network/api_client.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      // Konsisten menggunakan ApiClient seperti ScheduleService
      final res = await ApiClient.get("/announcements");
      
      // Jika response dari Laravel dibungkus dalam key 'data'
      final List<dynamic> list = res['data'] ?? res; 

      return list.map((item) => AnnouncementModel.fromJson(item)).toList();
    } catch (e) {
      print("Error AnnouncementService: $e");
      rethrow;
    }
  }
}