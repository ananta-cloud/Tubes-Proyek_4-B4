import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../../core/network/mongo_database.dart';
import 'package:hive/hive.dart';

class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel?> login(String email, String password) async {
    try {
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
      await _storage.write(key: "user_id", value: user["_id"].toString());

      return UserModel.fromJson(user);
    } catch (e) {
      print("LOGIN ERROR: $e");
      return null;
    }
  }

  Future<void> logout() async {
    // 1. Hapus token dari secure storage
    await _storage.delete(key: "token");

    // 2. Bersihkan data lokal Hive (opsional tapi sangat disarankan)
    await Hive.box('schedules').clear();
    await Hive.box('announcements').clear();
    // await Hive.box('bookmarks').clear(); // Hapus komentar ini jika bookmark juga ingin di-reset
  }
}
