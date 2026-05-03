import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDatabase {
  static late Db db;
  static late DbCollection tasksCollection;
  static late DbCollection announcementsCollection;
  static late DbCollection usersCollection;
  static late DbCollection schedulesCollection;

  static Future<void> connect() async {
    try {
      final mongoUrl = dotenv.env['MONGO_URL'] ?? '';
      if (mongoUrl.isEmpty)
        throw Exception("MONGO_URL tidak ditemukan di .env");

      db = await Db.create(mongoUrl);
      await db.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw Exception("Koneksi Timeout. Cek IP Whitelist Atlas."),
      );

      tasksCollection = db.collection('tasks');
      announcementsCollection = db.collection('announcements');
      usersCollection = db.collection('users');
      schedulesCollection = db.collection('schedules');

      print(" Berhasil terkoneksi ke MongoDB!");
    } catch (e) {
      print(" Gagal koneksi ke MongoDB: $e");
      // rethrow;
    }
  }
}
