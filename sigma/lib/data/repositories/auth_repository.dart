import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../models/pengajaran_model.dart';
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

      // 1. Cek Akun di Tabel Users
      final user = await MongoDatabase.usersCollection.findOne({
        "email": email,
      });
      if (user == null) return null;

      // 2. Cek Password
      final hashedPassword = user["password"];
      final isValid = BCrypt.checkpw(password, hashedPassword);
      if (!isValid) return null;

      // 3. Persiapan Variabel Aman (Default/Fallback)
      final String cleanId = (user["_id"] as ObjectId).toHexString();
      final String role = user["role"]?.toString() ?? "MAHASISWA";

      String namaPengguna = "Pengguna Tanpa Nama";
      String? kelasPengguna;
      String? idJurusan;
      String? kodeDosenAktif; // 🔥 Tambahan: Menampung kode dosen

      // =========================================================
      // 4. AMBIL DATA NAMA & KELAS DARI TABEL SPESIFIK (MHS / DOSEN)
      // =========================================================
      if (role == 'MAHASISWA') {
        final mhs = await MongoDatabase.db.collection('mahasiswa').findOne({
          "email": user["email"],
        });
        if (mhs != null) {
          // Ambil nama dari tabel mahasiswa
          namaPengguna = mhs["nama"]?.toString() ?? namaPengguna;

          // Ambil nama kelas jika ID kelas tersedia
          if (mhs["id_kelas"] != null) {
            final kls = await MongoDatabase.kelasCollection.findOne({
              "_id": mhs["id_kelas"],
            });
            if (kls != null) {
              kelasPengguna = kls["nama_kelas"]?.toString();
            }
          }
        }
      } else if (role == 'DOSEN') {
        final dosen = await MongoDatabase.dosenCollection.findOne({
          "email": user["email"],
        });
        if (dosen != null) {
          namaPengguna = dosen["nama_dosen"]?.toString() ?? namaPengguna;
          kodeDosenAktif = dosen["kode_dosen"]?.toString();
        }
      }

      // 5. Simpan ke Brankas Lokal (Secure Storage)
      await _storage.write(key: "user_id", value: cleanId);
      await _storage.write(key: "user_nama", value: namaPengguna);
      await _storage.write(key: "user_role", value: role);
      await _storage.write(
        key: "user_email",
        value: user["email"]?.toString() ?? "",
      );

      // Simpan kelas jika dia mahasiswa
      if (kelasPengguna != null) {
        await _storage.write(key: "user_kelas", value: kelasPengguna);
      }

      // 🔥 Simpan kode dosen jika dia dosen
      if (kodeDosenAktif != null) {
        await _storage.write(key: "user_kode_dosen", value: kodeDosenAktif);
      }

      // 6. Kembalikan Model dengan Aman
      return UserModel(
        id: cleanId,
        nama: namaPengguna,
        email: user["email"]?.toString() ?? "",
        role: role,
        idJurusan: idJurusan,
        kelas: kelasPengguna,
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
    await Hive.box<PengajaranModel>('pengajaran').clear();
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
