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

  // Helper untuk membersihkan ObjectId menjadi String
  String? _extractId(dynamic field) {
    if (field == null) return null;
    if (field is ObjectId) return field.toHexString();
    if (field is Map && field.containsKey('\$oid')) return field['\$oid'];
    return field.toString().replaceAll('ObjectId("', '').replaceAll('")', '').trim();
  }

  // ===============================================
  // 1. FUNGSI LOGIN DENGAN PEMISAHAN PROFIL
  // ===============================================
  Future<UserModel?> login(String email, String password) async {
    // 1. CEK INTERNET FISIK HP TERLEBIH DAHULU
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isPhysicalOffline = (connectivityResult as List).contains(ConnectivityResult.none);

    if (isPhysicalOffline) {
      debugPrint("LOGIN ERROR: Perangkat tidak terhubung ke internet.");
      return null;
    }

    // 2. KONEKSI MONGODB
    if (MongoDatabase.isOffline) {
      debugPrint("🔄 Mencoba menyambungkan kembali ke MongoDB...");
      try {
        await MongoDatabase.connect();
      } catch (e) {
        debugPrint("LOGIN ERROR: Database MongoDB gagal dijangkau -> $e");
        return null;
      }
    }

    try {
      // 3. CARI USER DI KOLEKSI 'users' (Hanya Otentikasi)
      final user = await MongoDatabase.usersCollection.findOne({"email": email});
      if (user == null) return null;

      final hashedPassword = user["password"];
      final isValid = BCrypt.checkpw(password, hashedPassword);
      if (!isValid) return null;

      // 4. PARSING DATA DASAR
      String cleanId = _extractId(user["_id"]) ?? "";
      String role = user["role"]?.toString() ?? "MAHASISWA";
      
      String namaPengguna = "Pengguna";
      String? idJurusan;
      String? idProdi;
      String? targetKelas;

      // 5. AMBIL DATA PROFIL BERDASARKAN ROLE
      if (role == 'DOSEN') {
        final dosenDoc = await MongoDatabase.db.collection('dosen').findOne({'user_id': user["_id"]});
        if (dosenDoc != null) {
          namaPengguna = dosenDoc['nama_dosen'] ?? "Dosen";
          idJurusan = _extractId(dosenDoc['id_jurusan']);
        }
      } 
      else if (role == 'MAHASISWA') {
        final mhsDoc = await MongoDatabase.db.collection('mahasiswa').findOne({'user_id': user["_id"]});
        if (mhsDoc != null) {
          namaPengguna = mhsDoc['nama'] ?? "Mahasiswa";
          idProdi = _extractId(mhsDoc['id_prodi']);
          targetKelas = _extractId(mhsDoc['id_kelas']); 
        }
      } 
      else if (role == 'ADMIN_TU') {
        namaPengguna = user["nama"] ?? "Admin TU";
        idJurusan = _extractId(user["id_jurusan"]);
      }

      // 6. BENTUK MODEL USER LENGKAP
      final loggedInUser = UserModel(
        id: cleanId,
        nama: namaPengguna,
        email: user["email"],
        role: role,
        idJurusan: idJurusan,
        idProdi: idProdi,
        kelas: targetKelas,
      );

      // 7. SIMPAN KE STORAGE LOKAL (UNTUK OFFLINE & CHECK STATUS)
      await _storage.write(key: "user_id", value: cleanId);

      final userDataString = jsonEncode({
        "id": loggedInUser.id,
        "nama": loggedInUser.nama,
        "email": loggedInUser.email,
        "role": loggedInUser.role,
        "id_jurusan": loggedInUser.idJurusan,
        "id_prodi": loggedInUser.idProdi,
        "id_kelas": loggedInUser.idKelas,
      });
      await _storage.write(key: "user_data", value: userDataString);

      return loggedInUser;
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }

  // ===============================================
  // 2. FUNGSI CEK STATUS LOGIN (AUTO LOGIN)
  // ===============================================
  Future<UserModel?> checkLoginStatus() async {
    try {
      final userDataString = await _storage.read(key: "user_data");

      if (userDataString != null && userDataString.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        return UserModel(
          id: userMap["id"],
          nama: userMap["nama"],
          email: userMap["email"],
          role: userMap["role"],
          idJurusan: userMap["id_jurusan"],
          idProdi: userMap["id_prodi"],
          kelas: userMap["target_kelas"],
        );
      }
    } catch (e) {
      debugPrint("AUTO LOGIN ERROR: $e");
    }
    return null;
  }

  // ===============================================
  // 3. FUNGSI LOGOUT
  // ===============================================
  Future<void> logout() async {
    try {
      await _storage.delete(key: "token");
      await _storage.delete(key: "user_id");
      await _storage.delete(key: "user_data");
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
  // 4. FUNGSI GANTI PASSWORD (Hanya merubah di koleksi Users)
  // ===============================================
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      String cleanUserId = userId.replaceAll('ObjectId("', '').replaceAll('")', '');

      final user = await MongoDatabase.usersCollection.findOne({
        "_id": ObjectId.fromHexString(cleanUserId),
      });

      if (user == null) return false;

      final currentHashedPassword = user["password"];
      final isOldPasswordCorrect = BCrypt.checkpw(oldPassword, currentHashedPassword);

      if (!isOldPasswordCorrect) throw Exception("Password lama salah");

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