import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../auth/auth_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthService _service = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel?> login(String email, String password) async {
    final result = await _service.login(email, password);

    if (result["status"] == "success") {
      final data = result["data"];

      final token = data["token"];
      final userJson = data["user"];

      // ✅ SIMPAN TOKEN
      await _storage.write(key: "token", value: token);

      // ✅ RETURN USER
      return UserModel.fromJson(userJson);
    }

    return null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  Future<void> logout() async {
    await _storage.delete(key: "token");
  }
}
