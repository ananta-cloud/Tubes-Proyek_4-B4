import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../models/schedule_local_model.dart';
import '../models/announcement_model.dart';
import '../../core/network/mongo_database.dart';
import 'package:hive/hive.dart';


class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel?> login(String email, String password) async {
    try {
      if (!MongoDatabase.db.isConnected) {
        print("Mencoba menyambung ulang ke MongoDB...");
        await MongoDatabase.db.open(); 
      }

      final user = await MongoDatabase.usersCollection.findOne({"email": email});
      if (user == null) return null;

      final hashedPassword = user["password"];
      final isValid = BCrypt.checkpw(password, hashedPassword);
      if (!isValid) return null;

      await _storage.write(key: "user_id", value: user["_id"].toHexString());
      await _storage.write(key: "user_nama", value: user["nama"]);
      await _storage.write(key: "user_role", value: user["role"]);
      await _storage.write(key: "user_email", value: user["email"]);
      
      return UserModel(
        id: user["_id"].toHexString(),
        nama: user["nama"],
        email: user["email"],
        role: user["role"],
      );
    } catch (e) {
      print("LOGIN ERROR: $e");
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

      return UserModel(
        id: userId,
        nama: nama,
        email: email,
        role: role,
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
    
    // Bersihkan data Hive
    await Hive.box<ScheduleLocalModel>('schedules').clear();
    await Hive.box<AnnouncementModel>('announcements').clear();
    if (Hive.isBoxOpen('bookmarks')) {
      await Hive.box<AnnouncementModel>('bookmarks').clear(); 
    }
  }
}
