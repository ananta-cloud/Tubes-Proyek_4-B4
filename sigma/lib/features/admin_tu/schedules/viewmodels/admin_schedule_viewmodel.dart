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

  // Progress import
  String _importStatus = '';
  bool _isImporting = false;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isImporting => _isImporting;
  String get importStatus => _importStatus;
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

      if (_queueBox.isEmpty) {
        final newEntries = <String, ScheduleModel>{};
        for (final d in docs) {
          final model = ScheduleModel.fromMongo(d);
          newEntries[model.id] = model;
        }

        final oldKeys = _schedulesBox.keys.cast<String>().toList();
        final newKeys = newEntries.keys.toSet();
        for (final oldKey in oldKeys) {
          if (!newKeys.contains(oldKey)) {
            await _schedulesBox.delete(oldKey);
          }
        }

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

  // ─── Import dari Excel ────────────────────────────────────────────────────
  /// Menerima list jadwal hasil parse Excel, hapus duplikat berdasarkan
  /// semester + tahunAkademik + kelas, lalu simpan semua ke Hive dan MongoDB.
  Future<void> importSchedules(List<ScheduleModel> parsed) async {
    if (parsed.isEmpty) return;

    _isImporting = true;
    _importStatus = 'Mempersiapkan data...';
    notifyListeners();

    try {
      // Kumpulkan kombinasi unik semester + tahunAkademik + kelas dari data baru
      final kelasKeys = parsed
          .map((s) => '${s.semester}|${s.tahunAkademik}|${s.kelas}')
          .toSet();

      _importStatus = 'Menghapus jadwal lama...';
      notifyListeners();

      // 1. Hapus dari Hive — semua entry yang cocok semester+tahunAkademik+kelas
      final keysToDelete = _schedulesBox.keys.cast<String>().where((key) {
        final existing = _schedulesBox.get(key);
        if (existing == null) return false;
        final k =
            '${existing.semester}|${existing.tahunAkademik}|${existing.kelas}';
        return kelasKeys.contains(k);
      }).toList();

      for (final key in keysToDelete) {
        await _schedulesBox.delete(key);
      }

      // 2. Hapus dari MongoDB (jika online)
      final isOnline = await _checkOnline();
      if (isOnline) {
        for (final kelasKey in kelasKeys) {
          final parts = kelasKey.split('|');
          final sem = parts[0];
          final tahun = parts[1];
          final kelas = parts[2];

          _importStatus = 'Menghapus jadwal lama $kelas dari server...';
          notifyListeners();

          await MongoDatabase.runSafe(
            () => MongoDatabase.schedulesCollection.deleteMany(
              where
                  .eq('semester', sem)
                  .eq('tahun_akademik', tahun)
                  .eq('kelas', kelas),
            ),
          );
        }
      }

      // 3. Simpan data baru ke Hive
      _importStatus = 'Menyimpan ${parsed.length} jadwal...';
      notifyListeners();

      final newEntries = <String, ScheduleModel>{};
      for (final s in parsed) {
        newEntries[s.id] = s;
      }
      await _schedulesBox.putAll(newEntries);
      _loadFromLocal();

      // 4. Simpan ke MongoDB (jika online) atau queue
      if (isOnline) {
        int saved = 0;
        for (final s in parsed) {
          _importStatus = 'Menyimpan ke server... ($saved/${parsed.length})';
          notifyListeners();

          await MongoDatabase.runSafe(
            () => MongoDatabase.schedulesCollection.insertOne({
              '_id': ObjectId.fromHexString(s.id),
              ...s.toMongoMap(),
              'updated_at': DateTime.now(),
            }),
          );
          saved++;
        }
      } else {
        // Offline — masukkan ke queue batch
        await _queueBox.add({
          'operation': 'import_batch',
          'ids': parsed.map((s) => s.id).toList(),
          'kelas_keys': kelasKeys.toList(),
        });
      }

      _importStatus =
          'Import selesai! ${parsed.length} jadwal berhasil disimpan.';
      notifyListeners();
    } catch (e) {
      _importStatus = 'Terjadi kesalahan: $e';
      debugPrint('❌ AdminScheduleViewModel.importSchedules: $e');
      notifyListeners();
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ─── Publish ──────────────────────────────────────────────────────────────
  Future<void> publishSchedule(String id) async {
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
        kelas: existing.kelas,
        kodeMk: existing.kodeMk,
        kodeDosen: existing.kodeDosen,
        tePr: existing.tePr,
        semester: existing.semester,
        tahunAkademik: existing.tahunAkademik,
        jamKe: existing.jamKe,
      );
      await _schedulesBox.put(id, updated);
      _loadFromLocal();
    }

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
        } else if (op['operation'] == 'import_batch') {
          // Drain import yang pending saat offline
          final ids = List<String>.from(op['ids'] ?? []);
          final kelasKeys = List<String>.from(op['kelas_keys'] ?? []);

          // Hapus duplikat dulu
          for (final kelasKey in kelasKeys) {
            final parts = kelasKey.split('|');
            if (parts.length < 3) continue;
            await MongoDatabase.runSafe(
              () => MongoDatabase.schedulesCollection.deleteMany(
                where
                    .eq('semester', parts[0])
                    .eq('tahun_akademik', parts[1])
                    .eq('kelas', parts[2]),
              ),
            );
          }

          // Insert semua dari Hive
          for (final id in ids) {
            final s = _schedulesBox.get(id);
            if (s == null) continue;
            await MongoDatabase.runSafe(
              () => MongoDatabase.schedulesCollection.insertOne({
                '_id': ObjectId.fromHexString(s.id),
                ...s.toMongoMap(),
                'updated_at': DateTime.now(),
              }),
            );
          }
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
