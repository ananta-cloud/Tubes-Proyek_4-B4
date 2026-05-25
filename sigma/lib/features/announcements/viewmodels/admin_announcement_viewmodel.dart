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
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  bool _isSyncing = false;

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
    String namaPublisher = 'Ibu Admin TU',
    String rolePublisher = 'ADMIN_TU',
    List<Map<String, String>> attachments = const [],
    DateTime? deadline,
  }) async {
    final now = DateTime.now();
    final newId = ObjectId().toHexString();

    final model = AnnouncementModel(
      id: newId,
      judul: judul,
      isi: isi,
      kategori: kategoriList,
      targetAudience: target,
      idPublisher: ObjectId().toHexString(),
      namaPublisher: namaPublisher,
      rolePublisher: rolePublisher,
      tingkatKepentingan: tingkatKepentingan,
      createdAt: now,
      updatedAt: now,
      attachments: attachments,
    );
    await _announcementsBox.put(newId, model);
    _loadFromLocal();

    await _queueBox.add({
      'operation': 'create',
      'id': newId,
      'judul': judul,
      'isi': isi,
      'kategoriList': kategoriList,
      'target': target,
      'tingkatKepentingan': tingkatKepentingan,
      'namaPublisher': namaPublisher,
      'rolePublisher': rolePublisher,
      'createdAt': now.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'attachments': attachments,
    });

    _pendingIds.add(newId);
    _syncStatus = SyncStatus.pending;
    notifyListeners();

    await _drainQueue();
  }

  // ─── Queue drain ──────────────────────────────────────────────────────────
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
        if (op['operation'] == 'create') {
          List<String> kategoriList = [];
          if (op['kategoriList'] is List) {
            kategoriList = List<String>.from(op['kategoriList']);
          } else if (op['kategori'] != null) {
            kategoriList = [op['kategori'].toString()];
          }

          await MongoDatabase.runSafe(
            () => MongoDatabase.announcementsCollection.insertOne({
              '_id': ObjectId.fromHexString(op['id']),
              'judul': op['judul'],
              'isi': op['isi'],
              'kategori': kategoriList,
              'target_audience': op['target'],
              'id_publisher': ObjectId(),
              'nama_publisher': op['namaPublisher'],
              'role_publisher': op['rolePublisher'],
              'tingkat_kepentingan': op['tingkatKepentingan'] ?? 'BIASA',
              'created_at': DateTime.parse(op['createdAt']),
              'updated_at': DateTime.parse(op['createdAt']),
              'attachments': op['attachments'] ?? [],
              if (op['deadline'] != null)
                'deadline': DateTime.parse(op['deadline']),
            }),
          );

          await FcmSenderService.sendNotificationToTarget(
            judul: op['judul'],
            isi: op['isi'],
            module: 'pengumuman',
            targetAudience: op['target'],
          );
        }

        await _queueBox.delete(key);
        final syncedId = op['id']?.toString();
        if (syncedId != null) _pendingIds.remove(syncedId);
        debugPrint(' Announcement queue item $key synced');
      } catch (e) {
        debugPrint(' AdminAnnouncementViewModel._drainQueue key=$key: $e');
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
