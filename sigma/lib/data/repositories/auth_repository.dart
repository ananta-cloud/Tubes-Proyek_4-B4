import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/schedule_local_model.dart';
import '../models/announcement_model.dart';
import 'dart:convert';
import '../../core/network/mongo_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:sigma/data/models/pengajaran_model.dart';

class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ===============================================
  // 1. FUNGSI LOGIN (UPDATE: Ambil Data Relasi Mahasiswa & Kelas)
  // ===============================================
  Future<UserModel?> login(String email, String password) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isPhysicalOffline = (connectivityResult as List).contains(
      ConnectivityResult.none,
    );

    if (isPhysicalOffline) {
      debugPrint("LOGIN ERROR: Perangkat tidak terhubung ke internet.");
      return null; 
    }

    if (MongoDatabase.isOffline) {
      debugPrint("Koneksi terputus. Mencoba menyambungkan kembali ke MongoDB...");
      try {
        await MongoDatabase.connect();
      } catch (e) {
        debugPrint("LOGIN ERROR: Database MongoDB gagal dijangkau -> $e");
        return null;
      }
    }

    try {
      if (!MongoDatabase.db.isConnected) {
        print("Mencoba menyambung ulang ke MongoDB...");
        await MongoDatabase.db.open();
      }

      // 1. Cari user di collection 'users'
      final user = await MongoDatabase.usersCollection.findOne({
        "email": email,
      });
      if (user == null) return null;

      // 2. Cek Password
      final hashedPassword = user["password"];
      final isValid = BCrypt.checkpw(password, hashedPassword);
      if (!isValid) return null;

      // 3. Siapkan variabel
      Map<String, dynamic>? profilLengkap;
      // Gunakan nama bawaan jika ada, jika tidak, pakai "Pengguna Tanpa Nama"
      String safeNama = user["nama"]?.toString() ?? "Pengguna Tanpa Nama"; 

      // 4. Jika ia MAHASISWA, ambil data relasinya!
      if (user["role"] == "MAHASISWA") {
        final profilMahasiswa = await MongoDatabase.mahasiswaCollection.findOne({
          "user_id": user["_id"], // Relasi Mahasiswa pakai user_id
        });

        if (profilMahasiswa != null) {
          // Ambil nama mahasiswa jika ada
          if (profilMahasiswa["nama"] != null) {
            safeNama = profilMahasiswa["nama"].toString();
          }

          if (profilMahasiswa["id_kelas"] != null) {
            final dataKelas = await MongoDatabase.kelasCollection.findOne({
              "_id": profilMahasiswa["id_kelas"],
            });
            profilMahasiswa["kelas"] = dataKelas;
          }
          profilLengkap = profilMahasiswa; 
        }
      } 
      // 5. 🔥 JIKA IA DOSEN, AMBIL NAMANYA DARI KOLEKSI DOSEN
      else if (user["role"] == "DOSEN" || user["role"] == "MANAJEMEN") {
        final profilDosen = await MongoDatabase.db.collection('dosen').findOne({
          "email": user["email"], // Relasi Dosen di database Anda pakai email
        });

        if (profilDosen != null && profilDosen["nama_dosen"] != null) {
           safeNama = profilDosen["nama_dosen"].toString(); // Timpa dengan "Santi Sundari"
        }
      }

      // 6. Simpan ke Secure Storage untuk Offline/Auto-Login
      MahasiswaModel? modelMahasiswa;
      if (user["role"] == "MAHASISWA" && profilLengkap != null) {
        modelMahasiswa = MahasiswaModel.fromJson(profilLengkap);
      }

      final String safeId = (user["_id"] is ObjectId) ? (user["_id"] as ObjectId).toHexString() : user["_id"].toString();
      final String safeEmail = user["email"]?.toString() ?? "";
      final String safeRole = user["role"]?.toString() ?? "MAHASISWA";

      await _storage.write(key: "user_id", value: safeId);
      await _storage.write(key: "user_nama", value: safeNama); // Nama sekarang pasti benar!
      await _storage.write(key: "user_role", value: safeRole);
      await _storage.write(key: "user_email", value: safeEmail);
      
      if (modelMahasiswa != null) {
        await _storage.write(key: "user_profil", value: jsonEncode(modelMahasiswa.toJson()));
      }

      // 7. Kembalikan UserModel
      return UserModel(
        id: safeId,
        nama: safeNama,
        email: safeEmail,
        role: safeRole,
        profilMahasiswa: modelMahasiswa,
      );
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }

  // ===============================================
  // 2. FUNGSI CEK STATUS LOGIN (Bypass Login)
  // ===============================================
  Future<UserModel?> checkLoginStatus() async {
    try {
      final userDataString = await _storage.read(key: "user_data");

      if (userDataString != null && userDataString.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        return UserModel.fromJson(userMap);
      }
    } catch (e) {
      debugPrint("AUTO LOGIN ERROR: $e");
    }
    return null;
  }

  // ===============================================
  // 3. FUNGSI AUTO-LOGIN OFFLINE
  // ===============================================
  Future<UserModel?> checkAutoLogin() async {
    try {
      final userId = await _storage.read(key: "user_id");
      if (userId == null) return null; // Belum login

      final nama = await _storage.read(key: "user_nama") ?? "Mahasiswa";
      final role = await _storage.read(key: "user_role") ?? "MAHASISWA";
      final email = await _storage.read(key: "user_email") ?? "";

      // Ambil dan Decode kembali profil yang tadi disimpan sebagai JSON String
      final profilString = await _storage.read(key: "user_profil");
      Map<String, dynamic>? profilMap;
      if (profilString != null && profilString.isNotEmpty) {
        profilMap = jsonDecode(profilString);
      }

      return UserModel(
        id: userId,
        nama: nama,
        email: email,
        role: role,
        profilMahasiswa: (role == 'MAHASISWA' && profilMap != null)
            ? MahasiswaModel.fromJson(profilMap)
            : null,
      );
    } catch (e) {
      print("AUTO-LOGIN ERROR: $e");
      return null;
    }
  }

  // ===============================================
  // 4. FUNGSI LOGOUT
  // ===============================================
  Future<void> logout() async {
    // Bersihkan semua kunci sesi dari brankas
    await _storage.delete(key: "user_id");
    await _storage.delete(key: "user_nama");
    await _storage.delete(key: "user_role");
    await _storage.delete(key: "user_email");
    await _storage.delete(key: "user_profil");
    await _storage.delete(key: "user_data");

    // Bersihkan data Hive
    await Hive.box<ScheduleLocalModel>('schedules').clear();
    await Hive.box<AnnouncementModel>('announcements').clear();
    await Hive.box<PengajaranModel>('pengajaran').clear();
    if (Hive.isBoxOpen('bookmarks')) {
      await Hive.box<AnnouncementModel>('bookmarks').clear();
    }
  }

  // ===============================================
  // 5. FUNGSI GANTI PASSWORD (TETAP)
  // ===============================================
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      String cleanUserId = userId
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      final user = await MongoDatabase.usersCollection.findOne({
        "_id": ObjectId.fromHexString(cleanUserId),
      });

      if (user == null) return false;

      final currentHashedPassword = user["password"];
      final isOldPasswordCorrect = BCrypt.checkpw(
        oldPassword,
        currentHashedPassword,
      );

      if (!isOldPasswordCorrect) {
        throw Exception("Password lama salah");
      }

      final newHashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

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
