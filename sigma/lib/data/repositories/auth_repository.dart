import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
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

      //  4. BERSIHKAN ID SEBELUM DISIMPAN
      String cleanId = user["_id"] is ObjectId
          ? (user["_id"] as ObjectId).toHexString()
          : user["_id"]
                .toString()
                .replaceAll('ObjectId("', '')
                .replaceAll('")', '');

      // Buat objek user
      final loggedInUser = UserModel(
        id: cleanId,
        nama: user["nama"] ?? "User",
        email: user["email"],
        role: user["role"] ?? "MAHASISWA",
        idJurusan: user["id_jurusan"]?.toString(),
        idProdi: user["id_prodi"]?.toString(),
        kodeDosen: user["kode_dosen"]?.toString(), 
        kelas: user["kelas"]?.toString(),          
        angkatan: user["angkatan"]?.toString(),
        deviceToken: user["device_token"]?.toString(),
      );

      //  5. SIMPAN KE STORAGE LOKAL (UNTUK OFFLINE)
      await _storage.write(key: "user_id", value: cleanId);

      // Simpan data lengkap sebagai JSON String agar profil bisa di-load offline
      final userDataString = jsonEncode(loggedInUser.toJson());
      await _storage.write(key: "user_data", value: userDataString);

      return loggedInUser;
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }

  // ===============================================
  // 2. FUNGSI CEK STATUS LOGIN (UNTUK BYPASS LOGIN)
  // ===============================================
  Future<UserModel?> checkLoginStatus() async {
    try {
      // Membaca data user yang tersimpan di HP
      final userDataString = await _storage.read(key: "user_data");

      if (userDataString != null && userDataString.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        
        return UserModel.fromJson(userMap);
      }
    } catch (e) {
      debugPrint("AUTO LOGIN ERROR: $e");
    }
    return null; // Mengembalikan null jika belum login
  }

  // ===============================================
  // 3. FUNGSI LOGOUT (UPDATE: Hapus user_data)
  // ===============================================
  Future<void> logout() async {
    // 1. Hapus token dari secure storage
    await _storage.delete(key: "token");

    // 2. Bersihkan data lokal Hive (opsional tapi sangat disarankan)
    await Hive.box('schedules').clear();
    await Hive.box('announcements').clear();
    // await Hive.box('bookmarks').clear(); // Hapus komentar ini jika bookmark juga ingin di-reset
    try {
      await _storage.delete(key: "token");
      await _storage.delete(key: "user_id");
      await _storage.delete(
        key: "user_data",
      ); // Tambahan: Hapus memori user offline
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
