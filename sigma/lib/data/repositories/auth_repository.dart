import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/schedule_model.dart';
import '../models/announcement_model.dart';
import 'dart:convert';
import '../../core/network/mongo_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

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

      final hashedPassword = user["password"];
      final isValid = BCrypt.checkpw(password, hashedPassword);
      if (!isValid) return null;

      // 2. Siapkan wadah untuk Profil Akademik
      Map<String, dynamic>? profilLengkap;

      // 3. Jika ia MAHASISWA, ambil data relasinya!
      if (user["role"] == "MAHASISWA") {
        // 🔥 PERBAIKAN: Cari berdasarkan email dari tabel users, bukan user_id!
        final profilMahasiswa = await MongoDatabase.mahasiswaCollection.findOne({
          "email": user["email"], 
        });

        if (profilMahasiswa != null) {
          // 3A. Ambil Data Kelas
          if (profilMahasiswa["id_kelas"] != null) {
            var searchIdKelas = profilMahasiswa["id_kelas"];
            if (searchIdKelas is String && searchIdKelas.length == 24) {
              searchIdKelas = ObjectId.fromHexString(searchIdKelas);
            }
            final dataKelas = await MongoDatabase.kelasCollection.findOne({
              "_id": searchIdKelas,
            });
            profilMahasiswa["kelas"] = dataKelas;
          }

          // 3B. Ambil Data Prodi (Terdapat di profilMahasiswa atau Kelas)
          // Kode kueri prodi Anda yang kemarin ditaruh di sini tetap sama dan aman
          var searchIdProdi = profilMahasiswa["id_prodi"] ?? (profilMahasiswa["kelas"] != null ? profilMahasiswa["kelas"]["id_prodi"] : null);
          if (searchIdProdi != null) {
            if (searchIdProdi is String && searchIdProdi.length == 24) {
              searchIdProdi = ObjectId.fromHexString(searchIdProdi);
            }
            final dataProdi = await MongoDatabase.prodiCollection.findOne({
              "_id": searchIdProdi
            });
            if (dataProdi != null) {
              if (profilMahasiswa["kelas"] != null) {
                profilMahasiswa["kelas"]["nama_prodi"] = dataProdi["nama_prodi"] ?? dataProdi["nama"];
              } else {
                profilMahasiswa["kelas"] = {"nama_prodi": dataProdi["nama_prodi"] ?? dataProdi["nama"]};
              }
            }
          }
          
          profilLengkap = profilMahasiswa;
          print("✅ PROFIL MAHASISWA DITEMUKAN VIA EMAIL: ${profilLengkap['nama']}");
        } else {
          print("❌ WARNING: Profil mahasiswa TIDAK DITEMUKAN untuk email: ${user["email"]}");
        }
      }

      // 4. Saring Data Mentah ke Model
      MahasiswaModel? modelMahasiswa;
      if (user["role"] == "MAHASISWA" && profilLengkap != null) {
        modelMahasiswa = MahasiswaModel.fromJson(profilLengkap);
      }

      // 🔥 PERBAIKAN NAMA: Prioritaskan nama dari koleksi MAHASISWA!
      final String safeId = (user["_id"] is ObjectId) ? (user["_id"] as ObjectId).toHexString() : user["_id"].toString();
      
      final String namaDariProfil = profilLengkap?["nama"]?.toString() ?? "";
      final String namaDariUser = user["nama"]?.toString() ?? "";
      
      // Jika profil mahasiswa punya nama, pakai itu. Jika kosong, baru pakai dari users.
      final String safeNama = namaDariProfil.isNotEmpty ? namaDariProfil : (namaDariUser.isNotEmpty ? namaDariUser : "Mahasiswa");
      
      final String safeEmail = user["email"]?.toString() ?? "";
      final String safeRole = user["role"]?.toString() ?? "MAHASISWA";

      // 5. Simpan ke Secure Storage
      await _storage.write(key: "user_id", value: safeId);
      await _storage.write(key: "user_nama", value: safeNama);
      await _storage.write(key: "user_role", value: safeRole);
      await _storage.write(key: "user_email", value: safeEmail);
      
      if (modelMahasiswa != null) {
        await _storage.write(key: "user_profil", value: jsonEncode(modelMahasiswa.toJson()));
      }

      // 6. Kembalikan UserModel
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
    await Hive.box<ScheduleModel>('schedules').clear();
    await Hive.box<AnnouncementModel>('announcements').clear();
    if (Hive.isBoxOpen('bookmarks')) {
      await Hive.box<AnnouncementModel>('bookmarks').clear();
    }
  }

  // ===============================================
  // 5. FUNGSI GANTI PASSWORD (TETAP)
  // ===============================================
  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    try {
      String cleanUserId = userId.replaceAll('ObjectId("', '').replaceAll('")', '');

      final user = await MongoDatabase.usersCollection.findOne({
        "_id": ObjectId.fromHexString(cleanUserId),
      });

      if (user == null) return false;

      final currentHashedPassword = user["password"];
      final isOldPasswordCorrect = BCrypt.checkpw(oldPassword, currentHashedPassword);

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