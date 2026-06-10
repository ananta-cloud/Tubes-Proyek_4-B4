import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmSenderService {
  static const String _projectId = "sigma-52c03";

  static Future<String> _getAccessToken() async {
    final jsonString = await rootBundle.loadString(
      'assets/service_account.json',
    );
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final AuthClient client = await clientViaServiceAccount(
      accountCredentials,
      scopes,
    );
    final String accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  }

  /// Mengirim notifikasi dinamis
  /// [module] = 'pengumuman', 'task', atau 'jadwal'
  /// [targetAudience] = 'semua', 'mahasiswa', 'dosen', 'tim_penjadwalan', atau 'admin_tu'
  static Future<void> sendNotificationToTarget({
    required String judul,
    required String isi,
    required String module,
    required String targetAudience,
    String tingkatKepentingan = 'BIASA',
  }) async {
    print("LOG_NOTIF: Memulai pengiriman ke $targetAudience...");
    try {
      final String serverToken = await _getAccessToken();
      final String fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      String targetTopic = '${module.toLowerCase()}_${targetAudience.toLowerCase()}';

      // 1. PERBAIKAN: Tentukan Channel ID dari sisi Server
      String channelId = 'channel_biasa_1';
      if (tingkatKepentingan == 'PENTING') {
        channelId = 'channel_penting_1';
      } else if (tingkatKepentingan == 'SANGAT PENTING' ||
          tingkatKepentingan == 'SANGAT_PENTING') {
        channelId = 'channel_sangat_penting_1';
      }

      // 2. PERBAIKAN: Tambahkan blok "android" di payload JSON
      final Map<String, dynamic> body = {
        "message": {
          "topic": targetTopic,
          "notification": {"title": judul, "body": isi},
          "android": {
            "notification": {"channel_id": channelId},
          },
          "data": {"tipe": tingkatKepentingan, "module": module},
        },
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
        print(" Sukses menembak notifikasi ke topik: $targetTopic");
      } else {
        print("Gagal siaran ke $targetTopic. Error: ${response.body}");
      }
    } catch (e) {
      print("Terjadi kesalahan FcmSenderService: $e");
    }
  }
}
