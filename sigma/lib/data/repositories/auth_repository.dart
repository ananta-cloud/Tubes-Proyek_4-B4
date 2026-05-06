import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../../core/network/mongo_database.dart';
import 'package:hive/hive.dart';

class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel?> login(String email, String password) async {
    // Cek apakah aplikasi dalam mode offline
    if (MongoDatabase.isOffline) {
      debugPrint("LOGIN ERROR: Aplikasi dalam mode offline");
      return null;
    }

    try {
      //  1. CARI USER BERDASARKAN EMAIL SAJA
      final user = await MongoDatabase.usersCollection.findOne({
        "email": email,
      });

      debugPrint("USER FOUND: $user");

      if (user == null) return null;

      //  2. AMBIL HASH PASSWORD
      final hashedPassword = user["password"];

      //  3. COMPARE PASSWORD
      final isValid = BCrypt.checkpw(password, hashedPassword);

      if (!isValid) return null;

      //  4. LOGIN SUCCESS
      await _storage.write(key: "user_id", value: user["_id"].toString());

      return UserModel(
        id: user["_id"].toString(),
        nama: user["nama"],
        email: user["email"],
        role: user["role"],
      );
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: "token");
      await _storage.delete(key: "user_id");
    } catch (e) {
      debugPrint("LOGOUT STORAGE ERROR: $e");
    }

    final boxesToClear = ['schedules', 'announcements', 'bookmarks'];
    for (final boxName in boxesToClear) {
      if (Hive.isBoxOpen(boxName)) {
        try {
          await Hive.box(boxName).clear();
        } catch (e) {
          debugPrint("LOGOUT HIVE CLEAR ERROR ($boxName): $e");
        }
      }
    }
  }
}
