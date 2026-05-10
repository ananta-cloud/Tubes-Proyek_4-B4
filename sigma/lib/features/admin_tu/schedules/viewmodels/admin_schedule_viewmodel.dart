import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import '../../../../../core/network/mongo_database.dart';
import '../models/schedule_model.dart';

const _kBoxSchedules = 'admin_schedules';
const _kBoxQueue = 'schedule_queue';

class AdminScheduleViewModel extends ChangeNotifier {
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isSyncInProgress = false;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get pendingQueueCount => _queueBox.length;

  int get draftCount =>
      _schedules.where((s) => s.status.toUpperCase() == 'DRAFT').length;
  int get publishedCount =>
      _schedules.where((s) => s.status.toUpperCase() == 'PUBLISHED').length;

  // ─── Boxes ────────────────────────────────────────────────────────────────
  Box<ScheduleModel> get _schedulesBox =>
      Hive.box<ScheduleModel>(_kBoxSchedules);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> fetchSchedules() async {
    if (_isSyncInProgress) return;
    _loadFromLocal();
    await _drainQueue();
    await _syncFromMongo();
  }

  // ─── Load lokal ───────────────────────────────────────────────────────────
  void _loadFromLocal() {
    try {
      _schedules = _schedulesBox.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AdminScheduleViewModel._loadFromLocal: $e');
    }
  }

  // ─── Sync dari MongoDB ────────────────────────────────────────────────────
  Future<void> _syncFromMongo() async {
    if (_isSyncInProgress) return;
    final isOnline = await _checkOnline();
    if (!isOnline) return;

    _isSyncInProgress = true;
    _isLoading = true;
    notifyListeners();

    try {
      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.schedulesCollection.find().toList(),
      );

      // Hanya overwrite jika queue kosong
      if (_queueBox.isEmpty) {
        final newEntries = <String, ScheduleModel>{};
        for (final d in docs) {
          final model = ScheduleModel.fromMongo(d);
          newEntries[model.id] = model;
        }

        // Hapus key lama yang sudah tidak ada di MongoDB
        final oldKeys = _schedulesBox.keys.cast<String>().toList();
        final newKeys = newEntries.keys.toSet();
        for (final oldKey in oldKeys) {
          if (!newKeys.contains(oldKey)) {
            await _schedulesBox.delete(oldKey);
          }
        }

        // Upsert semua data baru
        await _schedulesBox.putAll(newEntries);
      }

      _loadFromLocal();
    } catch (e) {
      debugPrint('❌ AdminScheduleViewModel._syncFromMongo: $e');
    } finally {
      _isLoading = false;
      _isSyncInProgress = false;
      notifyListeners();
    }
  }

  // ─── Publish ──────────────────────────────────────────────────────────────
  Future<void> publishSchedule(String id) async {
    // 1. Update Hive dulu
    final existing = _schedulesBox.get(id);
    if (existing != null) {
      final updated = ScheduleModel(
        id: existing.id,
        namaMatkul: existing.namaMatkul,
        namaDosen: existing.namaDosen,
        hari: existing.hari,
        jamMulai: existing.jamMulai,
        jamSelesai: existing.jamSelesai,
        ruangan: existing.ruangan,
        status: 'PUBLISHED',
        createdAt: existing.createdAt,
      );
      await _schedulesBox.put(id, updated);
      _loadFromLocal();
    }

    // 2. Masukkan ke queue
    await _queueBox.add({'operation': 'publish', 'id': id});

    // 3. Langsung drain jika online
    await _drainQueue();
  }

  // ─── Queue drain ──────────────────────────────────────────────────────────
  Future<void> _drainQueue() async {
    final isOnline = await _checkOnline();
    if (!isOnline || _queueBox.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    final keys = _queueBox.keys.toList();
    for (final key in keys) {
      final raw = _queueBox.get(key);
      if (raw == null) {
        await _queueBox.delete(key);
        continue;
      }
      final op = Map<String, dynamic>.from(raw);

      try {
        if (op['operation'] == 'publish') {
          await MongoDatabase.runSafe(
            () => MongoDatabase.schedulesCollection.updateOne(
              where.id(ObjectId.fromHexString(op['id'])),
              modify.set('status', 'PUBLISHED'),
            ),
          );
        }
        await _queueBox.delete(key);
        debugPrint('✅ Schedule queue item $key synced');
      } catch (e) {
        debugPrint('❌ AdminScheduleViewModel._drainQueue key=$key: $e');
        break;
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  // ─── Connection restored ──────────────────────────────────────────────────
  Future<void> onConnectionRestored() async {
    debugPrint('🔄 Connection restored — draining schedule queue...');
    await _drainQueue();
    await _syncFromMongo();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }
}
