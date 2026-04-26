import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = "http://127.0.0.1:8000/api";
  static const _storage = FlutterSecureStorage();

  //  POST (UNTUK LOGIN)
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  //  GET (UNTUK API DENGAN TOKEN)
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await _storage.read(key: "token");

    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await _storage.read(key: "token");

    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }
}
