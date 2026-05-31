import 'dart:async';
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
  static late DbCollection prodiCollection;
  static late DbCollection dosenCollection;
  static late DbCollection timPenjadwalanCollection;

  static bool isOffline = true;
  static bool _isConnecting = false;
  static final List<Completer<void>> _waiters = [];
  static bool _dbInitialized = false;
  static Future<void> connect() async {
    // Sudah konek, skip
    if (_dbInitialized && db.state == State.OPEN && !isOffline) return;

    // Sedang konek, tunggu
    if (_isConnecting) {
      final c = Completer<void>();
      _waiters.add(c);
      return c.future;
    }

    _isConnecting = true;
    try {
      String mongoUrl = dotenv.env['MONGO_URL']?.trim() ?? '';
      if (mongoUrl.isEmpty)
        throw Exception("MONGO_URL tidak ditemukan di .env");

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
        onTimeout: () => throw Exception("Koneksi timeout."),
      );

      tasksCollection = db.collection('tasks');
      announcementsCollection = db.collection('announcements');
      usersCollection = db.collection('users');
      schedulesCollection = db.collection('schedules');
      mataKuliahCollection = db.collection('mata_kuliah');
      mahasiswaCollection = db.collection('mahasiswa');
      kelasCollection = db.collection('kelas');
      prodiCollection = db.collection('program_studi');
      dosenCollection = db.collection('dosen');
      timPenjadwalanCollection = db.collection('tim_penjadwalan');

      _dbInitialized = true;
      isOffline = false;
      print("Berhasil terkoneksi ke MongoDB!");

      for (final c in _waiters) c.complete();
    } catch (e) {
      isOffline = true;
      print("Gagal koneksi ke MongoDB: $e");
      for (final c in _waiters) c.completeError(e);
      rethrow;
    } finally {
      _waiters.clear();
      _isConnecting = false;
    }
  }

  static Future<void> ensureConnected() async {
    if (!_dbInitialized || isOffline) {
      await connect();
      return;
    }

    if (db.state != State.OPEN) {
      await connect();
      return;
    }

    // Verifikasi koneksi masih hidup
    try {
      await db
          .collection('users')
          .findOne(where.eq('_id', '000000000000000000000000'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Koneksi mati, reconnect
      _dbInitialized = false;
      isOffline = true;
      await connect();
    }
  }

  static Future<T> runSafe<T>(Future<T> Function() operation) async {
    if (isOffline) throw Exception("Aplikasi dalam mode offline.");
    await ensureConnected();
    return await operation();
  }
}
