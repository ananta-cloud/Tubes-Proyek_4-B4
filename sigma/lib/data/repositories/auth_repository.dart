import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../models/schedule_local_model.dart';
import '../models/announcement_model.dart';
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
      if (!MongoDatabase.db.isConnected) {
        print("Mencoba menyambung ulang ke MongoDB...");
        await MongoDatabase.db.open();
      }

      final user = await MongoDatabase.usersCollection.findOne({
        "email": email,
      });
      if (user == null) return null;

      final hashedPassword = user["password"];
      final isValid = BCrypt.checkpw(password, hashedPassword);
      if (!isValid) return null;

      await _storage.write(key: "user_id", value: user["_id"].oid);
      await _storage.write(key: "user_nama", value: user["nama"]);
      await _storage.write(key: "user_role", value: user["role"]);
      await _storage.write(key: "user_email", value: user["email"]);

      return UserModel(
        id: user["_id"].oid,
        nama: user["nama"],
        email: user["email"],
        role: user["role"],
      );
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }

  // FUNGSI AUTO-LOGIN YANG BARU: SUPER CEPAT & 100% OFFLINE
  Future<UserModel?> checkAutoLogin() async {
    try {
      final userId = await _storage.read(key: "user_id");
      if (userId == null) return null; // Belum login

      // Langsung baca dari brankas lokal tanpa butuh internet!
      final nama = await _storage.read(key: "user_nama") ?? "Mahasiswa";
      final role = await _storage.read(key: "user_role") ?? "MAHASISWA";
      final email = await _storage.read(key: "user_email") ?? "";

      return UserModel(id: userId, nama: nama, email: email, role: role);
    } catch (e) {
      print("AUTO-LOGIN ERROR: $e");
      return null;
    }
  }

  Future<void> logout() async {
    // Bersihkan semua kunci sesi dari brankas
    await _storage.delete(key: "user_id");
    await _storage.delete(key: "user_nama");
    await _storage.delete(key: "user_role");
    await _storage.delete(key: "user_email");

    // Bersihkan data Hive
    await Hive.box<ScheduleLocalModel>('schedules').clear();
    await Hive.box<AnnouncementModel>('announcements').clear();
    if (Hive.isBoxOpen('bookmarks')) {
      await Hive.box<AnnouncementModel>('bookmarks').clear();
    }
  }

  // ===============================================
  // 4. FUNGSI GANTI PASSWORD
  // ===============================================
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // Bersihkan string userId dari format bawaan mongo_dart ObjectId("...")
      // agar menyisakan 24 karakter hex murni.
      String cleanUserId = userId
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      // 1. Cari user di MongoDB berdasarkan ID yang sudah dibersihkan
      final user = await MongoDatabase.usersCollection.findOne({
        "_id": ObjectId.fromHexString(cleanUserId),
      });

      if (user == null) return false;

      // 2. Verifikasi apakah password lama benar
      final currentHashedPassword = user["password"];
      final isOldPasswordCorrect = BCrypt.checkpw(
        oldPassword,
        currentHashedPassword,
      );

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
