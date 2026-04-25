import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/announcement_model.dart';

class AnnouncementService {
  // Ganti IP ini dengan IP laptop kamu jika menggunakan HP fisik, 
  // atau 10.0.2.2 jika menggunakan Emulator Android
  final String baseUrl = "http://10.0.2.2:8000/api"; 

  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/announcements'));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => AnnouncementModel.fromJson(data)).toList();
      } else {
        throw Exception('Gagal memuat data dari server');
      }
    } catch (e) {
      print("Error Service: $e");
      return [];
    }
  }
}