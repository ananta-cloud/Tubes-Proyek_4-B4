import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmSenderService {
  static const String _projectId = "sigma-52c03";

  // Fungsi untuk mendapatkan token akses sementara dari Google
  static Future<String> _getAccessToken() async {
    
    final jsonString = await rootBundle.loadString('assets/service_account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);

    // Meminta izin khusus untuk menggunakan Firebase Messaging
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    
    final AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);
    final String accessToken = client.credentials.accessToken.data;
    
    client.close();
    return accessToken;
  }

  // Fungsi utama untuk menembak notifikasi ke token tertentu
  static Future<void> sendNotificationToAll({
    required String judul,
    required String isi,
  }) async {
    try {
      final String serverToken = await _getAccessToken();
      final String fcmEndpoint = 
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final Map<String, dynamic> body = {
        "message": {
          "topic": "pengumuman_kampus",
          "notification": {
            "title": judul,
            "body": isi,
          }
        }
      };

      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("Sukses siaran notifikasi ke semua mahasiswa!");
      } else {
        print("Gagal siaran. Error: ${response.body}");
      }
    } catch (e) {
      print("Terjadi kesalahan sistem saat mengirim: $e");
    }
  }
}