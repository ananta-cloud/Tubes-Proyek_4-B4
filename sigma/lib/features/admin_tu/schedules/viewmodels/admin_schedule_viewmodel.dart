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

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get pendingQueueCount => _queueBox.length;

  int get draftCount =>
      _schedules.where((s) => s.status.toUpperCase() == 'DRAFT').length;
  int get publishedCount =>
      _schedules.where((s) => s.status.toUpperCase() == 'PUBLISHED').length;

  // ─── Boxes ───────────────────────────────────────────────────────────────
  Box<ScheduleModel> get _schedulesBox =>
      Hive.box<ScheduleModel>(_kBoxSchedules);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> fetchSchedules() async {
    _loadFromLocal();
    await _syncFromMongo();
  }

  // ─── Load lokal ───────────────────────────────────────────────────────────
  void _loadFromLocal() {
    _schedules = _schedulesBox.values.toList();
    notifyListeners();
  }

  // ─── Sync dari MongoDB ────────────────────────────────────────────────────
  Future<void> _syncFromMongo() async {
    final isOnline = await _checkOnline();
    if (!isOnline) return;

    _isLoading = true;
    notifyListeners();
    try {
      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.schedulesCollection.find().toList(),
      );
      await _schedulesBox.clear();
      for (final d in docs) {
        final model = ScheduleModel.fromMongo(d);
        await _schedulesBox.put(model.id, model);
      }
      _loadFromLocal();
    } catch (e) {
      debugPrint('❌ AdminScheduleViewModel._syncFromMongo: $e');
    } finally {
      _isLoading = false;
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
      final op = Map<String, dynamic>.from(_queueBox.get(key) ?? {});
      if (op.isEmpty) continue;

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
      } catch (e) {
        debugPrint('❌ AdminScheduleViewModel._drainQueue: $e');
        break;
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Panggil saat koneksi kembali online
  Future<void> onConnectionRestored() async {
    await _drainQueue();
    await _syncFromMongo();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }
}
