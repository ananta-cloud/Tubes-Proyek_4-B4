import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../models/schedule_local_model.dart';
import '../models/announcement_model.dart';
import 'dart:convert';
import '../../core/network/mongo_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';


class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ===============================================
  // 1. FUNGSI LOGIN (UPDATE: Simpan Profil ke Lokal)
  // ===============================================
  Future<UserModel?> login(String email, String password) async {
    // 1. CEK INTERNET FISIK HP TERLEBIH DAHULU
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isPhysicalOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

    if (isPhysicalOffline) {
      debugPrint("LOGIN ERROR: Perangkat tidak terhubung ke internet.");
      return null; // Tolak login jika memang HP tidak ada koneksi
    }

    // 2. JIKA HP ONLINE TAPI MONGODB TERPUTUS, PAKSA SAMBUNG ULANG!
    if (MongoDatabase.isOffline) {
      debugPrint(
        "🔄 Koneksi terputus. Mencoba menyambungkan kembali ke MongoDB...",
      );
      try {
        await MongoDatabase.connect();
      } catch (e) {
        debugPrint("LOGIN ERROR: Database MongoDB gagal dijangkau -> $e");
        return null;
      }
    }

    // ==========================================
    // Sisa kode login Anda tetap sama seperti sebelumnya
    // ==========================================
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

      if (user["kelas"] != null) {
        await _storage.write(key: "user_kelas", value: user["kelas"]);
      }

      return UserModel(
        id: user["_id"].oid,
        nama: user["nama"],
        email: user["email"],
        role: user["role"] ?? "MAHASISWA",
        idJurusan: user["id_jurusan"]?.toString(),
        kelas: user["kelas"],
      );
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }

  // FUNGSI AUTO-LOGIN YANG BARU: SUPER CEPAT & 100% OFFLINE
  // ===============================================
  // 2. FUNGSI CEK STATUS LOGIN (UNTUK BYPASS LOGIN)
  // ===============================================
  Future<UserModel?> checkLoginStatus() async {
    try {
      // Membaca data user yang tersimpan di HP
      final userDataString = await _storage.read(key: "user_data");

      if (userDataString != null && userDataString.isNotEmpty) {
        // Decode JSON kembali menjadi UserModel
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        return UserModel(
          id: userMap["id"],
          nama: userMap["nama"],
          email: userMap["email"],
          role: userMap["role"],
          idJurusan: userMap["id_jurusan"],
        );
      }
    } catch (e) {
      debugPrint("AUTO LOGIN ERROR: $e");
    }
    return null; // Mengembalikan null jika belum login
  }

  // ===============================================
  // 3. FUNGSI LOGOUT (UPDATE: Hapus user_data)
  // ===============================================
  Future<UserModel?> checkAutoLogin() async {
    try {
      final userId = await _storage.read(key: "user_id");
      if (userId == null) return null; // Belum login

      // Langsung baca dari brankas lokal tanpa butuh internet!
      final nama = await _storage.read(key: "user_nama") ?? "Mahasiswa";
      final role = await _storage.read(key: "user_role") ?? "MAHASISWA";
      final email = await _storage.read(key: "user_email") ?? "";
      final kelas = await _storage.read(key: "user_kelas");

      return UserModel(
        id: userId, 
        nama: nama, 
        email: email, 
        role: role, 
        kelas: kelas,
      );

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
    await _storage.delete(key: "user_kelas");

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
