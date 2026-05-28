import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/data/services/fcm_sender_service.dart';

const _kBoxAnnouncements = 'admin_announcements';
const _kBoxQueue = 'announcement_queue';

enum SyncStatus { idle, pending, syncing, synced, failed }

class AdminAnnouncementViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _listJurusan = [];
  List<Map<String, dynamic>> _listProdi = [];
  String? _selectedJurusanId;
  String? _selectedProdiId;
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  List<Map<String, dynamic>> get listJurusan => _listJurusan;
  List<Map<String, dynamic>> get listProdi => _listProdi;
  String? get selectedJurusanId => _selectedJurusanId;
  String? get selectedProdiId => _selectedProdiId;

  SyncStatus _syncStatus = SyncStatus.idle;
  Set<String> _pendingIds = {};

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  SyncStatus get syncStatus => _syncStatus;
  Set<String> get pendingIds => _pendingIds;

  int get pendingQueueCount => _queueBox.length;
  int get pendingAnnouncementCount => _pendingIds.length;
  bool isAnnouncementPending(String id) => _pendingIds.contains(id);

  Future<void> fetchJurusan() async {
    try {
      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('jurusan').find().toList(),
      );
      _listJurusan = docs;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetchJurusan: $e');
    }
  }

  Future<void> fetchProdiByJurusan(String idJurusanHex) async {
    try {
      _selectedProdiId = null; // Reset prodi tiap kali jurusan diganti
      
      // Bersihkan string dari spasi tersembunyi
      final cleanId = idJurusanHex.trim(); 
      final objId = ObjectId.parse(cleanId);

      // Gunakan query builder 'where.eq' asli dari mongo_dart
      final docs = await MongoDatabase.runSafe(
        // PASTIKAN NAMA COLLECTION DI BAWAH INI SAMA PERSIS DENGAN DI MONGODB COMPASS ANDA
        () => MongoDatabase.db.collection('program_studi').find(
          where.eq('id_jurusan', objId)
        ).toList(),
      );
      
      _listProdi = docs;
      debugPrint('✅ Ditemukan ${docs.length} prodi untuk jurusan $cleanId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetchProdi: $e');
    }
  }

  void setJurusan(String? id) {
    _selectedJurusanId = id;
    if (id != null) {
      fetchProdiByJurusan(id);
    } else {
      _listProdi = [];
      _selectedProdiId = null;
    }
    notifyListeners();
  }

  void setProdi(String? id) {
    _selectedProdiId = id;
    notifyListeners();
  }

  void clearManajemenSelections() {
    _selectedJurusanId = null;
    _selectedProdiId = null;
    _listProdi = [];
  }

  int get thisMonthCount {
    final now = DateTime.now();
    return _announcements
        .where(
          (a) => a.createdAt.year == now.year && a.createdAt.month == now.month,
        )
        .length;
  }

  // ─── Boxes ────────────────────────────────────────────────────────────────
  Box<AnnouncementModel> get _announcementsBox =>
      Hive.box<AnnouncementModel>(_kBoxAnnouncements);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _loadFromLocal();
    _rebuildPendingIds();
    await _drainQueue();
    await syncFromMongo();
  }

  // ─── Load lokal ───────────────────────────────────────────────────────────
  void _loadFromLocal() {
    _announcements = _announcementsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void _rebuildPendingIds() {
    final ids = <String>{};
    for (final key in _queueBox.keys) {
      final raw = _queueBox.get(key);
      if (raw == null) continue;
      final op = Map<String, dynamic>.from(raw);
      final id = op['id']?.toString();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    _pendingIds = ids;

    final newStatus = ids.isEmpty ? SyncStatus.idle : SyncStatus.pending;
    if (_syncStatus != SyncStatus.syncing && _syncStatus != newStatus) {
      _syncStatus = newStatus;
    }
    notifyListeners();
  }

  // ─── Sync dari MongoDB ────────────────────────────────────────────────────
  Future<void> syncFromMongo() async {
    final isOnline = await _checkOnline();
    if (!isOnline) return;

    _isLoading = true;
    notifyListeners();
    try {
      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.announcementsCollection.find().toList(),
      );
      if (_queueBox.isEmpty) {
        await _announcementsBox.clear();
        for (final d in docs) {
          final model = AnnouncementModel.fromMongo(d);
          await _announcementsBox.put(model.id, model);
        }
        _loadFromLocal();
      }
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
    required List<String> kategoriList,
    required String target,
    required String tingkatKepentingan,
    DateTime? deadline,
    List<Map<String, String>> attachments = const [],
    // ─── TAMBAHKAN 5 PARAMETER INI ───
    String idPublisher = '',
    String namaPublisher = 'Admin',
    String rolePublisher = 'ADMIN_TU',
    String? idJurusan,
    String? idProdi,
  }) async {
    final newId = ObjectId().toHexString();
    final now = DateTime.now();

    // 1. Update UI secara lokal (agar terasa cepat tanpa loading)
    final newAnnouncement = AnnouncementModel(
      id: newId,
      judul: judul,
      isi: isi,
      kategori: kategoriList,
      targetAudience: target,
      tingkatKepentingan: tingkatKepentingan,
      attachments: attachments,
      createdAt: now,
      updatedAt: now,
      // Masukkan data publisher & jurusan/prodi ke model lokal
      idPublisher: idPublisher,
      namaPublisher: namaPublisher,
      rolePublisher: rolePublisher,
      idJurusan: idJurusan,
      idProdi: idProdi,
    );

    _announcements.insert(0, newAnnouncement);
    _pendingIds.add(newId);
    notifyListeners();

    // 2. Simpan ke Queue (Antrean Hive) untuk background sync
    await _queueBox.put(newId, {
      'id': newId,
      'action': 'create',
      'judul': judul,
      'isi': isi,
      'kategori': kategoriList,
      'target': target,
      'tingkat_kepentingan': tingkatKepentingan,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      'attachments': attachments,
      'timestamp': now.toIso8601String(),

      // ─── SIMPAN DATA INI KE QUEUE ───
      'id_publisher': idPublisher,
      'nama_publisher': namaPublisher,
      'role_publisher': rolePublisher,
      'id_jurusan': idJurusan,
      'id_prodi': idProdi,
    });

    // 3. Panggil proses upload
    _drainQueue();
  }

  Future<void> _drainQueue() async {
    final isOnline = await _checkOnline();
    if (!isOnline || _queueBox.isEmpty) return;

    _isSyncing = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    bool allSuccess = true;
    final keys = _queueBox.keys.toList();

    for (final key in keys) {
      final raw = _queueBox.get(key);
      if (raw == null) {
        await _queueBox.delete(key);
        continue;
      }
      final op = Map<String, dynamic>.from(raw);

      try {
        if (op['operation'] == 'create' || op['action'] == 'create') {
          List<String> kategoriList = [];
          if (op['kategoriList'] is List) {
            kategoriList = List<String>.from(op['kategoriList']);
          } else if (op['kategori'] != null) {
            kategoriList = [op['kategori'].toString()];
          }

          final doc = {
            // ─── GANTI MENJADI ObjectId.parse ───
            '_id': ObjectId.parse(op['id']),
            'judul': op['judul'],
            'isi': op['isi'],
            'kategori': kategoriList,
            'target_audience': op['target'] ?? op['target_audience'],
            'tingkat_kepentingan':
                op['tingkat_kepentingan'] ??
                op['tingkatKepentingan'] ??
                'BIASA',
            'created_at': DateTime.parse(op['timestamp'] ?? op['createdAt']),
            'updated_at': DateTime.parse(op['timestamp'] ?? op['createdAt']),
            'attachments': op['attachments'] ?? [],
            if (op['deadline'] != null)
              'deadline': DateTime.parse(op['deadline']),

            // ─── GANTI MENJADI ObjectId.parse ───
            'id_publisher':
                (op['id_publisher'] != null &&
                    op['id_publisher'].toString().isNotEmpty)
                ? ObjectId.parse(op['id_publisher'])
                : (op['idPublisher'] != null &&
                      op['idPublisher'].toString().isNotEmpty)
                ? ObjectId.parse(op['idPublisher'])
                : ObjectId(),
            'nama_publisher':
                op['nama_publisher'] ?? op['namaPublisher'] ?? 'Admin',
            'role_publisher':
                op['role_publisher'] ?? op['rolePublisher'] ?? 'ADMIN_TU',
          };

          // ─── GANTI MENJADI ObjectId.parse ───
          if (op['id_jurusan'] != null &&
              op['id_jurusan'].toString().isNotEmpty) {
            doc['id_jurusan'] = ObjectId.parse(op['id_jurusan']);
          } else if (op['idJurusan'] != null &&
              op['idJurusan'].toString().isNotEmpty) {
            doc['id_jurusan'] = ObjectId.parse(op['idJurusan']);
          }

          if (op['id_prodi'] != null && op['id_prodi'].toString().isNotEmpty) {
            doc['id_prodi'] = ObjectId.parse(op['id_prodi']);
          } else if (op['idProdi'] != null &&
              op['idProdi'].toString().isNotEmpty) {
            doc['id_prodi'] = ObjectId.parse(op['idProdi']);
          }

          await MongoDatabase.runSafe(
            () => MongoDatabase.announcementsCollection.insertOne(doc),
          );

          await FcmSenderService.sendNotificationToTarget(
            judul: op['judul'],
            isi: op['isi'],
            module: 'pengumuman',
            targetAudience: op['target'] ?? op['target_audience'],
          );
        }

        await _queueBox.delete(key);
        final syncedId = op['id']?.toString();
        if (syncedId != null) _pendingIds.remove(syncedId);
        debugPrint(' ✅ Announcement queue item $key synced');
      } catch (e) {
        debugPrint(' ❌ AdminAnnouncementViewModel._drainQueue key=$key: $e');
        allSuccess = false;
        break;
      }
    }

    _isSyncing = false;

    if (allSuccess && _queueBox.isEmpty) {
      _pendingIds = {};
      _syncStatus = SyncStatus.synced;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      _syncStatus = SyncStatus.idle;
    } else {
      _rebuildPendingIds();
      _syncStatus = allSuccess ? SyncStatus.idle : SyncStatus.failed;
    }
    notifyListeners();
  }

  // ─── Connection restored ──────────────────────────────────────────────────
  Future<void> onConnectionRestored() async {
    debugPrint(' Connection restored — draining announcement queue...');
    await _drainQueue();
    await syncFromMongo();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }
}
