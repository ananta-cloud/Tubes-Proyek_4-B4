import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../../core/network/mongo_database.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

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
      await _storage.write(key: "user_id", value: user["_id"].toHexString());

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

  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    try {
      // --- PERBAIKAN DI SINI ---
      // Bersihkan string userId dari format bawaan mongo_dart ObjectId("...")
      // agar menyisakan 24 karakter hex murni.
      String cleanUserId = userId.replaceAll('ObjectId("', '').replaceAll('")', '');

      // 1. Cari user di MongoDB berdasarkan ID yang sudah dibersihkan
      final user = await MongoDatabase.usersCollection.findOne({
        "_id": ObjectId.fromHexString(cleanUserId),
      });

      if (user == null) return false;

      // 2. Verifikasi apakah password lama benar
      final currentHashedPassword = user["password"];
      final isOldPasswordCorrect = BCrypt.checkpw(oldPassword, currentHashedPassword);

      if (!isOldPasswordCorrect) {
        throw Exception("Password lama salah");
      }

      // 3. Hash password baru sebelum disimpan
      final newHashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // 4. Update ke MongoDB menggunakan ID yang sudah dibersihkan
      final result = await MongoDatabase.usersCollection.updateOne(
        where.id(ObjectId.fromHexString(cleanUserId)),
        modify
            .set("password", newHashedPassword)
            .set("updated_at", DateTime.now()),
      );

      return result.isSuccess;
    } catch (e) {
      debugPrint("CHANGE PASSWORD ERROR: $e");
      rethrow; 
    }
  }
}
