import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDatabase {
  static late Db db;
  static late DbCollection tasksCollection;
  static late DbCollection announcementsCollection;
  static late DbCollection usersCollection;
  static late DbCollection schedulesCollection;

  // Mutex sederhana untuk mencegah concurrent requests ke Atlas
  static bool _isOperationRunning = false;

  static Future<void> connect() async {
    try {
      String mongoUrl = dotenv.env['MONGO_URL'] ?? '';
      if (mongoUrl.isEmpty)
        throw Exception("MONGO_URL tidak ditemukan di .env");

      // Tambah tls=true jika belum ada di URL
      if (!mongoUrl.contains('tls=true') && !mongoUrl.contains('ssl=true')) {
        final separator = mongoUrl.contains('?') ? '&' : '?';
        mongoUrl = '$mongoUrl${separator}tls=true';
      }

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

      print("✅ Berhasil terkoneksi ke MongoDB!");
    } catch (e) {
      print("❌ Gagal koneksi ke MongoDB: $e");
      rethrow;
    }
  }

  // Pastikan koneksi masih aktif sebelum operasi
  static Future<void> ensureConnected() async {
    try {
      if (db.state != State.OPEN) {
        await db.close().catchError((_) {});
        await db.open();
        return;
      }
      await db.serverStatus();
    } catch (e) {
      try {
        await db.close().catchError((_) {});
      } catch (_) {}
      await db.open();
    }
  }

  // Jalankan operasi DB secara sequential (tidak concurrent)
  // agar tidak error "connection closed" di Atlas
  static Future<T> runSafe<T>(Future<T> Function() operation) async {
    while (_isOperationRunning) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    _isOperationRunning = true;
    try {
      await ensureConnected();
      return await operation();
    } finally {
      _isOperationRunning = false;
    }
  }
}
