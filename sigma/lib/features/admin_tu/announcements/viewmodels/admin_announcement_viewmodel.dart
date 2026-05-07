import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/announcement_model.dart';

// Konstanta nama box Hive
const _kBoxAnnouncements = 'admin_announcements';
const _kBoxQueue = 'announcement_queue';

class AdminAnnouncementViewModel extends ChangeNotifier {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  int get thisMonthCount {
    final now = DateTime.now();
    return _announcements
        .where(
          (a) => a.createdAt.year == now.year && a.createdAt.month == now.month,
        )
        .length;
  }

  int get totalRead => 0;

  // ─── Boxes ───────────────────────────────────────────────────────────────
  Box<AnnouncementModel> get _announcementsBox =>
      Hive.box<AnnouncementModel>(_kBoxAnnouncements);

  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ─── Init ─────────────────────────────────────────────────────────────────
  /// Panggil saat halaman pertama kali dibuka.
  /// Load dari Hive dulu (instan), lalu coba sync dari MongoDB.
  Future<void> init() async {
    _loadFromLocal();
    await syncFromMongo();
  }

  // ─── Load lokal ───────────────────────────────────────────────────────────
  void _loadFromLocal() {
    _announcements = _announcementsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // ─── Fetch dari MongoDB ───────────────────────────────────────────────────
  Future<void> syncFromMongo() async {
    final isOnline = await _checkOnline();
    if (!isOnline) return;

    _isLoading = true;
    notifyListeners();
    try {
      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.announcementsCollection.find().toList(),
      );
      // Simpan ke Hive
      await _announcementsBox.clear();
      for (final d in docs) {
        final model = AnnouncementModel.fromMongo(d);
        await _announcementsBox.put(model.id, model);
      }
      _loadFromLocal();
    } catch (e) {
      debugPrint('❌ AdminAnnouncementViewModel.syncFromMongo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create ───────────────────────────────────────────────────────────────
  Future<void> createAnnouncement({
    required String judul,
    required String isi,
    required String kategori,
    required String target,
    String namaPublisher = 'Ibu Admin TU',
    String rolePublisher = 'ADMIN_TU',
  }) async {
    final now = DateTime.now();
    final newId = ObjectId().toHexString();

    // 1. Simpan ke Hive dulu (langsung terlihat di UI)
    final model = AnnouncementModel(
      id: newId,
      judul: judul,
      isi: isi,
      kategori: [kategori],
      targetAudience: target,
      idPublisher: ObjectId().toHexString(),
      namaPublisher: namaPublisher,
      rolePublisher: rolePublisher,
      tingkatKepentingan: 'BIASA',
      createdAt: now,
      updatedAt: now,
    );
    await _announcementsBox.put(newId, model);
    _loadFromLocal();

    // 2. Masukkan ke queue
    await _queueBox.add({
      'operation': 'create',
      'id': newId,
      'judul': judul,
      'isi': isi,
      'kategori': kategori,
      'target': target,
      'namaPublisher': namaPublisher,
      'rolePublisher': rolePublisher,
      'createdAt': now.toIso8601String(),
    });

    // 3. Coba langsung sync jika online
    await _drainQueue();
  }

  // ─── Queue drain ──────────────────────────────────────────────────────────
  /// Kirim semua operasi pending ke MongoDB (dipanggil saat online).
  Future<void> _drainQueue() async {
    final isOnline = await _checkOnline();
    if (!isOnline || _queueBox.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    final keys = _queueBox.keys.toList();
    for (final key in keys) {
      final op = Map<String, dynamic>.from(_queueBox.get(key) ?? {});
      if (op.isEmpty) continue;

      try {
        if (op['operation'] == 'create') {
          final doc = {
            '_id': ObjectId.fromHexString(op['id']),
            'judul': op['judul'],
            'isi': op['isi'],
            'kategori': [op['kategori']],
            'target_audience': op['target'],
            'id_publisher': ObjectId(),
            'nama_publisher': op['namaPublisher'],
            'role_publisher': op['rolePublisher'],
            'tingkat_kepentingan': 'BIASA',
            'created_at': DateTime.parse(op['createdAt']),
            'updated_at': DateTime.parse(op['createdAt']),
          };
          await MongoDatabase.runSafe(
            () => MongoDatabase.announcementsCollection.insertOne(doc),
          );
        }
        // Hapus dari queue setelah berhasil
        await _queueBox.delete(key);
      } catch (e) {
        debugPrint('❌ AdminAnnouncementViewModel._drainQueue: $e');
        break; // Berhenti, coba lagi nanti
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Panggil ini saat app kembali online (dari koneksi listener di main).
  Future<void> onConnectionRestored() async {
    await _drainQueue();
    await syncFromMongo();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }

  int get pendingQueueCount => _queueBox.length;
}
