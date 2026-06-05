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
  // 1. FUNGSI LOGIN
  // ===============================================
  Future<UserModel?> login(String email, String password) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isPhysicalOffline = (connectivityResult as List).contains(
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
        debugPrint("Mencoba menyambung ulang ke MongoDB...");
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

  // Ambil dan susun profil mahasiswa beserta relasi kelas & prodi
  Future<MahasiswaModel?> _fetchProfilMahasiswa(String email) async {
    final profil = await MongoDatabase.mahasiswaCollection.findOne({
      "email": email,
    });
    if (profil == null) {
      debugPrint(
        "WARNING: Profil mahasiswa tidak ditemukan untuk email: $email",
      );
      return null;
    }

    // Ambil data kelas
    if (profil["id_kelas"] != null) {
      var idKelas = profil["id_kelas"];
      if (idKelas is String && idKelas.length == 24) {
        idKelas = ObjectId.fromHexString(idKelas);
      }
      final dataKelas = await MongoDatabase.kelasCollection.findOne({
        "_id": idKelas,
      });
      profil["kelas"] = dataKelas;
    }

    // Ambil data prodi
    var idProdi = profil["id_prodi"] ?? profil["kelas"]?["id_prodi"];
    if (idProdi != null) {
      if (idProdi is String && idProdi.length == 24) {
        idProdi = ObjectId.fromHexString(idProdi);
      }
      final dataProdi = await MongoDatabase.prodiCollection.findOne({
        "_id": idProdi,
      });
      if (dataProdi != null) {
        final namaProdi = dataProdi["nama_prodi"] ?? dataProdi["nama"];
        if (profil["kelas"] != null) {
          profil["kelas"]["nama_prodi"] = namaProdi;
        } else {
          profil["kelas"] = {"nama_prodi": namaProdi};
        }
      }
    }

    debugPrint("✅ PROFIL MAHASISWA DITEMUKAN: ${profil['nama']}");
    return MahasiswaModel.fromJson(profil);
  }

  // Ambil dan simpan data dosen
  Future<void> _fetchAndSaveDosen(dynamic userId) async {
    final dosenDoc = await MongoDatabase.dosenCollection.findOne({
      "user_id": userId,
    });
    if (dosenDoc == null) return;

    await _storage.write(
      key: "dosen_id",
      value: (dosenDoc["_id"] as ObjectId).toHexString(),
    );
    await _storage.write(
      key: "dosen_kode",
      value: dosenDoc["kode_dosen"]?.toString() ?? '',
    );
    await _storage.write(
      key: "dosen_nama",
      value: dosenDoc["nama_dosen"]?.toString() ?? '',
    );
  }

  // Ambil dan simpan data tim penjadwalan
  Future<void> _fetchAndSaveTPJ(dynamic userId) async {
    final tpjDoc = await MongoDatabase.timPenjadwalanCollection.findOne({
      "user_id": userId,
    });
    if (tpjDoc == null) return;

    await _storage.write(
      key: "tpj_nama",
      value: tpjDoc["nama"]?.toString() ?? '',
    );
  }

  Future<DosenModel?> getDosenByUserId(String userId) async {
    try {
      final userDoc = await MongoDatabase.usersCollection.findOne({
        "_id": ObjectId.fromHexString(userId),
      });
      if (userDoc == null) return null;

      final email = userDoc["email"]?.toString();
      if (email == null || email.isEmpty) return null;

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
      await MongoDatabase.ensureConnected();

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

  Future<void> _saveUserSession({
    required String id,
    required String nama,
    required String role,
    required String email,
    MahasiswaModel? mahasiswa,
  }) async {
    await _storage.write(key: "user_id", value: id);
    await _storage.write(key: "user_nama", value: nama);
    await _storage.write(key: "user_role", value: role);
    await _storage.write(key: "user_email", value: email);

    if (mahasiswa != null) {
      await _storage.write(
        key: "user_profil",
        value: jsonEncode(mahasiswa.toJson()),
      );
    }
  }

  // ===============================================
  // 2. CEK STATUS LOGIN (Bypass Login)
  // ===============================================
  Future<UserModel?> checkLoginStatus() async {
    try {
      final userDataString = await _storage.read(key: "user_data");
      if (userDataString != null && userDataString.isNotEmpty) {
        return UserModel.fromJson(jsonDecode(userDataString));
      }
    } catch (e) {
      debugPrint("AUTO LOGIN ERROR: $e");
    }
    return null;
  }

  // ===============================================
  // 3. AUTO-LOGIN OFFLINE
  // ===============================================
  Future<UserModel?> checkAutoLogin() async {
    try {
      final userId = await _storage.read(key: "user_id");
      if (userId == null) return null;

      final role = await _storage.read(key: "user_role") ?? "MAHASISWA";
      final email = await _storage.read(key: "user_email") ?? "";
      String nama = await _storage.read(key: "user_nama") ?? "Mahasiswa";

      if (role == 'DOSEN') {
        final dosenNama = await _storage.read(key: "dosen_nama");
        if (dosenNama != null && dosenNama.isNotEmpty) nama = dosenNama;
      } else if (role == 'TIM_PENJADWALAN') {
        final tpjNama = await _storage.read(key: "tpj_nama");
        if (tpjNama != null && tpjNama.isNotEmpty) nama = tpjNama;
      }

      MahasiswaModel? profilMahasiswa;
      if (role == 'MAHASISWA') {
        final profilString = await _storage.read(key: "user_profil");
        if (profilString != null && profilString.isNotEmpty) {
          profilMahasiswa = MahasiswaModel.fromJson(jsonDecode(profilString));
        }
      }

      return UserModel(
        id: userId,
        nama: nama,
        email: email,
        role: role,
        profilMahasiswa: profilMahasiswa,
      );
    } catch (e) {
      debugPrint("AUTO-LOGIN ERROR: $e");
      return null;
    }
  }

  // ===============================================
  // 4. LOGOUT
  // ===============================================
  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: "user_id"),
      _storage.delete(key: "user_nama"),
      _storage.delete(key: "user_role"),
      _storage.delete(key: "user_email"),
      _storage.delete(key: "user_profil"),
      _storage.delete(key: "user_data"),
      _storage.delete(key: "dosen_id"),
      _storage.delete(key: "dosen_kode"),
      _storage.delete(key: "dosen_nama"),
      _storage.delete(key: "tpj_nama"),
    ]);

    await Hive.box<ScheduleModel>('schedules').clear();
    await Hive.box<AnnouncementModel>('announcements').clear();
    await Hive.box<PengajaranModel>('pengajaran').clear();
    if (Hive.isBoxOpen('bookmarks')) {
      await Hive.box<AnnouncementModel>('bookmarks').clear();
    }
  }

  // ===============================================
  // 5. GANTI PASSWORD
  // ===============================================
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final cleanId = userId.replaceAll('ObjectId("', '').replaceAll('")', '');
      final objId = ObjectId.fromHexString(cleanId);

      final user = await MongoDatabase.usersCollection.findOne({"_id": objId});
      if (user == null) return false;

      if (!BCrypt.checkpw(oldPassword, user["password"] as String)) {
        throw Exception("Password lama salah");
      }

      final result = await MongoDatabase.usersCollection.updateOne(
        where.id(objId),
        modify
            .set("password", BCrypt.hashpw(newPassword, BCrypt.gensalt()))
            .set("updated_at", DateTime.now()),
      );

      return result.isSuccess;
    } catch (e) {
      debugPrint("CHANGE PASSWORD ERROR: $e");
      rethrow;
    }
  }
}
