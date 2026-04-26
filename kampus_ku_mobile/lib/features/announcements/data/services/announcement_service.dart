import 'package:kampus_ku_mobile/core/network/api_client.dart';

class AnnouncementService {
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final res = await ApiClient.get("/announcements");

    // Gunakan pengecekan null sederhana berjaga-jaga jika 'data' kosong
    if (res['data'] == null) return [];

    return List<Map<String, dynamic>>.from(res['data']);
  }
}
