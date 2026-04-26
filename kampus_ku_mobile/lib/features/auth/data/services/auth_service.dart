import 'package:kampus_ku_mobile/core/network/api_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await ApiClient.post("/auth/login", {
      "email": email,
      "password": password,
    });
  }
}
