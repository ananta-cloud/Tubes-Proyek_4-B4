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
      debugPrint('Error fetchJurusan: $e');
    }
  }

  Future<void> fetchProdiByJurusan(String idJurusanHex) async {
    try {
      _selectedProdiId = null;

      final cleanId = idJurusanHex.trim();
      final objId = ObjectId.parse(cleanId);

      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.db
            .collection('program_studi')
            .find(where.eq('id_jurusan', objId))
            .toList(),
      );

      _listProdi = docs;
      debugPrint('Ditemukan ${docs.length} prodi untuk jurusan $cleanId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchProdi: $e');
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
    if (!await _ensureOnline()) return;

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
      debugPrint('AdminAnnouncementViewModel.syncFromMongo: $e');
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
    String idPublisher = '',
    String namaPublisher = 'Admin',
    String rolePublisher = 'ADMIN_TU',
    String? idJurusan,
    String? idProdi,
  }) async {
    final newId = ObjectId().toHexString();

    // FIX: Selalu gunakan UTC agar konsisten saat disimpan ke MongoDB
    // dan dibaca kembali. Tampilan ke user akan dikonversi ke lokal di layer UI.
    final nowUtc = DateTime.now().toUtc();

    final newAnnouncement = AnnouncementModel(
      id: newId,
      judul: judul,
      isi: isi,
      kategori: kategoriList,
      targetAudience: target,
      tingkatKepentingan: tingkatKepentingan,
      attachments: attachments,
      createdAt: nowUtc, // simpan sebagai UTC
      updatedAt: nowUtc, // simpan sebagai UTC
      idPublisher: idPublisher,
      namaPublisher: namaPublisher,
      rolePublisher: rolePublisher,
      idJurusan: idJurusan,
      idProdi: idProdi,
    );

    await _announcementsBox.put(newId, newAnnouncement);

    _announcements.insert(0, newAnnouncement);
    _pendingIds.add(newId);
    _syncStatus = SyncStatus.pending;
    notifyListeners();

    await _queueBox.put(newId, {
      'id': newId,
      'action': 'create',
      'judul': judul,
      'isi': isi,
      'kategori': kategoriList,
      'target': target,
      'tingkat_kepentingan': tingkatKepentingan,
      // FIX: simpan timestamp sebagai UTC ISO string (berakhiran 'Z')
      if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
      'attachments': attachments,
      'timestamp': nowUtc.toIso8601String(), // sudah UTC, berakhiran 'Z'
      'id_publisher': idPublisher,
      'nama_publisher': namaPublisher,
      'role_publisher': rolePublisher,
      'id_jurusan': idJurusan,
      'id_prodi': idProdi,
    });

    _drainQueue();
  }

  // ─── Helper: parse ObjectId dengan aman ──────────────────────────────────
  ObjectId _safeParseObjectId(dynamic val1, dynamic val2) {
    if (val1 != null && val1.toString().trim().isNotEmpty) {
      return ObjectId.parse(val1.toString().trim());
    }
    if (val2 != null && val2.toString().trim().isNotEmpty) {
      return ObjectId.parse(val2.toString().trim());
    }
    return ObjectId();
  }

  List<String> _parseKategoriFromQueue(dynamic raw) {
    if (raw == null) return ['Umum'];

    if (raw is List) {
      final result = raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return result.isEmpty ? ['Umum'] : result;
    }

    if (raw is String) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) return ['Umum'];
      final stripped = cleaned.startsWith('[') && cleaned.endsWith(']')
          ? cleaned.substring(1, cleaned.length - 1)
          : cleaned;
      final parts = stripped
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return parts.isEmpty ? ['Umum'] : parts;
    }

    return ['Umum'];
  }

  // ─── Helper: parse DateTime dari queue (handle UTC & lokal) ──────────────
  DateTime _parseQueueDateTime(String isoString) {
    final dt = DateTime.parse(isoString);
    // Jika sudah UTC (string berakhiran 'Z' atau '+00:00'), kembalikan apa adanya.
    // Jika bukan (string lama tanpa timezone info = lokal), konversi ke UTC.
    return dt.isUtc ? dt : dt.toUtc();
  }

  // ─── Drain Queue ──────────────────────────────────────────────────────────
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
        print("LOG_NOTIF: MongoDB sukses, lanjut ke FcmSenderService...");
        if (op['operation'] == 'create' || op['action'] == 'create') {
          final List<String> kategoriList = _parseKategoriFromQueue(
            op['kategori'] ?? op['kategoriList'],
          );

          // FIX: gunakan _parseQueueDateTime agar timestamp selalu UTC
          final timestampStr =
              (op['timestamp'] ?? op['createdAt'])?.toString() ?? '';
          final createdAtUtc = _parseQueueDateTime(timestampStr);

          final doc = {
            '_id': ObjectId.parse(op['id'].toString()),
            'judul': op['judul'],
            'isi': op['isi'],
            'kategori': kategoriList,
            'target_audience': op['target'] ?? op['target_audience'],
            'tingkat_kepentingan':
                op['tingkat_kepentingan'] ??
                op['tingkatKepentingan'] ??
                'BIASA',
            'created_at': createdAtUtc,
            'updated_at': createdAtUtc,
            'attachments': op['attachments'] ?? [],
            if (op['deadline'] != null)
              'deadline': _parseQueueDateTime(op['deadline'].toString()),
            'id_publisher': _safeParseObjectId(
              op['id_publisher'],
              op['idPublisher'],
            ),
            'nama_publisher':
                op['nama_publisher'] ?? op['namaPublisher'] ?? 'Admin',
            'role_publisher':
                op['role_publisher'] ?? op['rolePublisher'] ?? 'ADMIN_TU',
          };

          if (op['id_jurusan'] != null &&
              op['id_jurusan'].toString().isNotEmpty) {
            doc['id_jurusan'] = ObjectId.parse(op['id_jurusan'].toString());
          } else if (op['idJurusan'] != null &&
              op['idJurusan'].toString().isNotEmpty) {
            doc['id_jurusan'] = ObjectId.parse(op['idJurusan'].toString());
          }

          if (op['id_prodi'] != null && op['id_prodi'].toString().isNotEmpty) {
            doc['id_prodi'] = ObjectId.parse(op['id_prodi'].toString());
          } else if (op['idProdi'] != null &&
              op['idProdi'].toString().isNotEmpty) {
            doc['id_prodi'] = ObjectId.parse(op['idProdi'].toString());
          }

          await MongoDatabase.runSafe(
            () => MongoDatabase.announcementsCollection.insertOne(doc),
          );

          String rawTarget = op['target'] ?? op['target_audience'] ?? 'Semua';
          String targetNotif = 'semua';

          if (rawTarget.toUpperCase().contains('MAHASISWA')) {
            if (rawTarget.contains('(')) {
              String prodiRaw = rawTarget.split('(').last.replaceAll(')', '').trim();
              String prodiFormatted = prodiRaw.replaceAll(' ', '_').toLowerCase();
              targetNotif = 'mahasiswa_$prodiFormatted';
            } else {
              targetNotif = 'mahasiswa';
            }
          } else if (rawTarget.toUpperCase() == 'DOSEN') {
            targetNotif = 'dosen';
          }

          // Panggil Service Pengirim Notifikasi
          await FcmSenderService.sendNotificationToTarget(
            judul: op['judul'],
            isi: op['isi'],
            module: 'pengumuman',
            targetAudience: targetNotif,
            tingkatKepentingan:
                op['tingkat_kepentingan'] ??
                op['tingkatKepentingan'] ??
                'BIASA',
          );
          print("LOG_NOTIF: drainQueue selesai untuk ID $key");
        }

        await _queueBox.delete(key);
        final syncedId = op['id']?.toString();
        if (syncedId != null) _pendingIds.remove(syncedId);
        debugPrint('Announcement queue item $key synced');
      } catch (e) {
        debugPrint('AdminAnnouncementViewModel._drainQueue key=$key: $e');
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
    debugPrint('Connection restored — draining announcement queue...');
    await _drainQueue();
    await syncFromMongo();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }

  Future<bool> _ensureOnline() async {
    if (!await _checkOnline()) return false;

    if (MongoDatabase.isOffline) {
      try {
        debugPrint('MongoDatabase offline — mencoba reconnect...');
        await MongoDatabase.connect();
        debugPrint('Reconnect berhasil.');
      } catch (e) {
        debugPrint('Reconnect gagal: $e');
        return false;
      }
    }

    return !MongoDatabase.isOffline;
  }
}
