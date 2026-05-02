import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
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
        print("🔄 Mencoba menyambung ulang ke MongoDB...");
        await MongoDatabase.db.open(); 
      }

      //  1. CARI USER BERDASARKAN EMAIL SAJA
      final user = await MongoDatabase.usersCollection.findOne({
        "email": email,
      });

      print("USER FOUND: $user");

      if (user == null) return null;

      //  2. AMBIL HASH PASSWORD
      final hashedPassword = user["password"];

      //  3. COMPARE PASSWORD
      final isValid = BCrypt.checkpw(password, hashedPassword);

      if (!isValid) return null;

      //  4. LOGIN SUCCESS
      await _storage.write(key: "user_id", value: user["_id"].toHexString());

      

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

  Future<UserModel?> checkAutoLogin() async {
    try {

      
      final userId = await _storage.read(key: "user_id");
      if (userId == null) return null; // Jika belum pernah login

      if (!MongoDatabase.db.isConnected) {
        await MongoDatabase.db.open();
      }

      // Cari user berdasarkan ID yang tersimpan di storage
      final user = await MongoDatabase.usersCollection.findOne(
        where.id(ObjectId.fromHexString(userId))
      );
      
      if (user == null) return null;

      return UserModel(
        id: user["_id"].toHexString(),
        nama: user["nama"],
        email: user["email"],
        role: user["role"],
      );
    } catch (e) {
      print("AUTO-LOGIN ERROR: $e");
      return null;
    }
  }

  Future<void> logout() async {
    // 1. Hapus Kunci Sesi
    await _storage.delete(key: "user_id"); 
    
    // 2. Bersihkan data lokal dengan menyebutkan tipe datanya (Generic Type)
    await Hive.box<ScheduleLocalModel>('schedules').clear();
    await Hive.box<AnnouncementModel>('announcements').clear();
    if (Hive.isBoxOpen('bookmarks')) {
      await Hive.box<AnnouncementModel>('bookmarks').clear(); 
    }
  }
}
