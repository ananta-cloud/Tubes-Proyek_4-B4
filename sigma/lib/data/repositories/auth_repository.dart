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
import 'package:sigma/data/models/pengajaran_model.dart';
import '../models/dosen_model.dart';
import '../models/tpj_model.dart';

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
      debugPrint(
        "Koneksi terputus. Mencoba menyambungkan kembali ke MongoDB...",
      );
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

      Map<String, dynamic>? profilLengkap;
      // Gunakan nama bawaan jika ada, jika tidak, pakai "Pengguna Tanpa Nama"
      String safeNama = user["nama"]?.toString() ?? "Pengguna Tanpa Nama"; 

      // 4. Jika ia MAHASISWA, ambil data relasinya!
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
      
      
      final String safeEmail = user["email"]?.toString() ?? "";
      final String safeRole = user["role"]?.toString() ?? "MAHASISWA";

      // 5. Simpan ke Secure Storage
      await _storage.write(key: "user_id", value: safeId);
      await _storage.write(key: "user_nama", value: safeNama); // Nama sekarang pasti benar!
      await _storage.write(key: "user_role", value: safeRole);
      await _storage.write(key: "user_email", value: safeEmail);
      
      if (modelMahasiswa != null) {
        await _storage.write(
          key: "user_profil",
          value: jsonEncode(modelMahasiswa.toJson()),
        );
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

  Future<DosenModel?> getDosenByUserId(String userId) async {
    try {
      // Ambil email dari collection users
      final userDoc = await MongoDatabase.usersCollection.findOne({
        "_id": ObjectId.fromHexString(userId),
      });
      if (userDoc == null) return null;

      final email = userDoc["email"]?.toString();
      if (email == null || email.isEmpty) return null;

      // Query dosen menggunakan email
      final doc = await MongoDatabase.dosenCollection.findOne({"email": email});
      if (doc == null) return null;
      return DosenModel.fromMongo(doc);
    } catch (e) {
      debugPrint("GET DOSEN ERROR: $e");
      return null;
    }
  }

  Future<TimPenjadwalanModel?> getTimPenjadwalanByUserId(String userId) async {
    try {
      final doc = await MongoDatabase.timPenjadwalanCollection.findOne({
        "user_id": ObjectId.fromHexString(userId),
      });
      if (doc == null) return null;
      return TimPenjadwalanModel.fromMongo(doc);
    } catch (e) {
      debugPrint("GET TIM PENJADWALAN ERROR: $e");
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
      print('DEBUG checkAutoLogin: userId=$userId');

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
      String resolvedNama = nama;
      if (role == 'DOSEN') {
        final dosenNama = await _storage.read(key: "dosen_nama");
        if (dosenNama != null && dosenNama.isNotEmpty) {
          resolvedNama = dosenNama;
        }
      }
      if (role == 'TIM_PENJADWALAN') {
        final tpjNama = await _storage.read(key: "tpj_nama");
        if (tpjNama != null && tpjNama.isNotEmpty) resolvedNama = tpjNama;
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
    await _storage.delete(key: "user_id");
    await _storage.delete(key: "user_nama");
    await _storage.delete(key: "user_role");
    await _storage.delete(key: "user_email");
    await _storage.delete(key: "user_profil");
    await _storage.delete(key: "user_data");

    await _storage.delete(key: "dosen_id");
    await _storage.delete(key: "dosen_kode");
    await _storage.delete(key: "dosen_nama");

    await _storage.delete(key: "tpj_nama");

    // Bersihkan data Hive
    await Hive.box<ScheduleModel>('schedules').clear();
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
