import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDatabase {
  static late Db db;
  static late DbCollection tasksCollection;
  static late DbCollection announcementsCollection;
  static late DbCollection usersCollection;
  static late DbCollection schedulesCollection;
  static late DbCollection mataKuliahCollection;
  static late DbCollection mahasiswaCollection;
  static late DbCollection kelasCollection;
  static late DbCollection dosenCollection;

  static bool isOffline = true;
  static bool _isOperationRunning = false;

  static Future<void> connect() async {
    try {
      String mongoUrl = dotenv.env['MONGO_URL']?.trim() ?? '';
      if (mongoUrl.isEmpty) {
        throw Exception("MONGO_URL tidak ditemukan di .env");
      }

      if (!mongoUrl.contains('tls=true') && !mongoUrl.contains('ssl=true')) {
        final separator = mongoUrl.contains('?') ? '&' : '?';
        mongoUrl = '$mongoUrl${separator}tls=true';
      }
      if (!mongoUrl.contains('connectTimeoutMS')) {
        final separator = mongoUrl.contains('?') ? '&' : '?';
        mongoUrl = '$mongoUrl${separator}connectTimeoutMS=30000';
      }
      if (!mongoUrl.contains('serverSelectionTimeoutMS')) {
        final separator = mongoUrl.contains('?') ? '&' : '?';
        mongoUrl = '$mongoUrl${separator}serverSelectionTimeoutMS=30000';
      }
      
      if (!mongoUrl.contains('safeAtlas=true')) {
        final separator = mongoUrl.contains('?') ? '&' : '?';
        mongoUrl = '$mongoUrl${separator}safeAtlas=true';
      }

      db = await Db.create(mongoUrl);
      await db.open().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception(
          "Koneksi timeout. Cek IP Whitelist Atlas, pastikan perangkat/emulator "
          "dapat mengakses internet, atau gunakan 0.0.0.0/0 jika perlu.",
        ),
      );

      tasksCollection = db.collection('tasks');
      announcementsCollection = db.collection('announcements');
      usersCollection = db.collection('users');
      schedulesCollection = db.collection('schedules');
      mataKuliahCollection = db.collection('mata_kuliah');
      mahasiswaCollection = db.collection('mahasiswa');
      kelasCollection = db.collection('kelas');
      dosenCollection = db.collection('dosen'); 

      isOffline = false;
      print("Berhasil terkoneksi ke MongoDB!");
    } catch (e) {
      isOffline = true;
      print("Gagal koneksi ke MongoDB: $e");
      rethrow;
    }
  }

  static Future<void> ensureConnected() async {
    if (!db.isConnected) {
      print("🔄 Reconnecting ke MongoDB...");
      await connect();
    }
  }

  static Future<T> runSafe<T>(Future<T> Function() operation) async {
    if (isOffline) {
      throw Exception(
        "Aplikasi dalam mode offline. Operasi database tidak tersedia.",
      );
    }

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