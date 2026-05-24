import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import '../../../../../core/network/mongo_database.dart';
import '../models/schedule_model.dart';

const _kBoxSchedules = 'admin_schedules';
const _kBoxQueue = 'schedule_queue';

// ── Status sinkronisasi — ditampilkan sebagai indikator di UI ────────────────
enum SyncStatus {
  idle, // tidak ada pending queue
  pending, // ada jadwal di queue, belum tersync ke MongoDB
  syncing, // sedang proses sync ke MongoDB
  synced, // baru saja berhasil sync (tampilkan sebentar lalu kembali idle)
  failed, // sync gagal
}

class AdminScheduleViewModel extends ChangeNotifier {
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  bool _isSyncInProgress = false;
  bool _isImporting = false;
  String _importStatus = '';
  SyncStatus _syncStatus = SyncStatus.idle;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String get importStatus => _importStatus;
  SyncStatus get syncStatus => _syncStatus;
  int get pendingQueueCount => _queueBox.length;

  // ── Boxes ──────────────────────────────────────────────────────────────────
  Box<ScheduleModel> get _schedulesBox =>
      Hive.box<ScheduleModel>(_kBoxSchedules);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> fetchSchedules() async {
    if (_isSyncInProgress) return;
    _loadFromLocal();
    _updateSyncStatus(); // update status dari queue saat ini
    await _drainQueue();
    await _syncFromMongo();
  }

  // ── Load dari Hive ─────────────────────────────────────────────────────────
  void _loadFromLocal() {
    try {
      _schedules = _schedulesBox.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ _loadFromLocal: $e');
    }
  }

  // ── Update sync status berdasarkan isi queue ───────────────────────────────
  void _updateSyncStatus() {
    if (_syncStatus == SyncStatus.syncing) return; // jangan override saat sync
    final newStatus = _queueBox.isEmpty ? SyncStatus.idle : SyncStatus.pending;
    if (_syncStatus != newStatus) {
      _syncStatus = newStatus;
      notifyListeners();
    }
  }

  // ── Sync dari MongoDB → Hive ───────────────────────────────────────────────
  Future<void> _syncFromMongo() async {
    if (_isSyncInProgress) return;
    if (!await _checkOnline()) return;

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
          final m = ScheduleModel.fromMongo(d);
          newEntries[m.id] = m;
        }

        final oldKeys = _schedulesBox.keys.cast<String>().toList();
        for (final k in oldKeys) {
          if (!newEntries.containsKey(k)) await _schedulesBox.delete(k);
        }
        await _schedulesBox.putAll(newEntries);
      }

      _loadFromLocal();
    } catch (e) {
      debugPrint('❌ _syncFromMongo: $e');
    } finally {
      _isLoading = false;
      _isSyncInProgress = false;
      notifyListeners();
    }
  }

  // ── Import dari Excel ──────────────────────────────────────────────────────
  Future<void> importSchedules(List<ScheduleModel> parsed) async {
    if (parsed.isEmpty) return;

    _isImporting = true;
    _importStatus = 'Mempersiapkan data...';
    notifyListeners();

    try {
      final kelasKeys = parsed
          .map((s) => '${s.semester}|${s.tahunAkademik}|${s.kelas}')
          .toSet();

      // 1. Hapus jadwal lama dari Hive
      _importStatus = 'Menghapus jadwal lama...';
      notifyListeners();

      final keysToDelete = _schedulesBox.keys.cast<String>().where((key) {
        final e = _schedulesBox.get(key);
        if (e == null) return false;
        return kelasKeys.contains(
          '${e.semester}|${e.tahunAkademik}|${e.kelas}',
        );
      }).toList();
      for (final k in keysToDelete) await _schedulesBox.delete(k);

      // 2. Hapus jadwal lama dari MongoDB (jika online)
      final isOnline = await _checkOnline();
      if (isOnline) {
        for (final kelasKey in kelasKeys) {
          final parts = kelasKey.split('|');
          _importStatus = 'Menghapus jadwal lama ${parts[2]} dari server...';
          notifyListeners();

          await MongoDatabase.runSafe(
            () => MongoDatabase.schedulesCollection.deleteMany(
              where
                  .eq('semester', parts[0])
                  .eq('tahun_akademik', parts[1])
                  .eq('kelas', parts[2]),
            ),
          );
        }
      }

      // 3. Simpan data baru ke Hive
      _importStatus = 'Menyimpan ${parsed.length} jadwal ke lokal...';
      notifyListeners();

      final newEntries = <String, ScheduleModel>{};
      for (final s in parsed) newEntries[s.id] = s;
      await _schedulesBox.putAll(newEntries);
      _loadFromLocal();

      // 4. Simpan ke MongoDB atau masukkan queue
      if (isOnline) {
        _importStatus = 'Menyimpan ${parsed.length} jadwal ke server...';
        notifyListeners();

        final mongoDocs = parsed
            .map(
              (s) => {
                '_id': ObjectId.parse(s.id),
                ...s.toMongoMap(),
                'updated_at': DateTime.now(),
              },
            )
            .toList();

        await MongoDatabase.runSafe(
          () => MongoDatabase.schedulesCollection.insertMany(mongoDocs),
        );

        // Berhasil sync — tampilkan status "synced" sebentar
        _syncStatus = SyncStatus.synced;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        _syncStatus = SyncStatus.idle;
        notifyListeners();
      } else {
        // Offline — masukkan ke queue, status jadi pending
        await _queueBox.add({
          'operation': 'import_batch',
          'ids': parsed.map((s) => s.id).toList(),
          'kelas_keys': kelasKeys.toList(),
        });
        _syncStatus = SyncStatus.pending;
        notifyListeners();
      }

      _importStatus =
          'Import selesai! ${parsed.length} jadwal berhasil disimpan.';
      notifyListeners();
    } catch (e) {
      _importStatus = 'Terjadi kesalahan: $e';
      _syncStatus = SyncStatus.failed;
      debugPrint('❌ importSchedules: $e');
      notifyListeners();
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ── Drain offline queue ────────────────────────────────────────────────────
  Future<void> _drainQueue() async {
    if (!await _checkOnline() || _queueBox.isEmpty) return;

    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    final keys = _queueBox.keys.toList();
    bool allSuccess = true;

    for (final key in keys) {
      final raw = _queueBox.get(key);
      if (raw == null) {
        await _queueBox.delete(key);
        continue;
      }
      final op = Map<String, dynamic>.from(raw);

      try {
        if (op['operation'] == 'import_batch') {
          final ids = List<String>.from(op['ids'] ?? []);
          final kelasKeys = List<String>.from(op['kelas_keys'] ?? []);

          // Hapus lama
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

          // Insert batch
          final mongoDocs = ids
              .map((id) => _schedulesBox.get(id))
              .whereType<ScheduleModel>()
              .map(
                (s) => {
                  '_id': ObjectId.parse(s.id),
                  ...s.toMongoMap(),
                  'updated_at': DateTime.now(),
                },
              )
              .toList();

          if (mongoDocs.isNotEmpty) {
            await MongoDatabase.runSafe(
              () => MongoDatabase.schedulesCollection.insertMany(mongoDocs),
            );
          }
        }

        await _queueBox.delete(key);
        debugPrint('✅ Queue item $key synced');
      } catch (e) {
        debugPrint('❌ _drainQueue key=$key: $e');
        allSuccess = false;
        break;
      }
    }

    // Update status berdasarkan hasil drain
    if (allSuccess && _queueBox.isEmpty) {
      _syncStatus = SyncStatus.synced;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      _syncStatus = SyncStatus.idle;
    } else {
      _syncStatus = allSuccess ? SyncStatus.idle : SyncStatus.failed;
    }
    notifyListeners();
  }

  // ── Connection restored ────────────────────────────────────────────────────
  Future<void> onConnectionRestored() async {
    debugPrint('🔄 Connection restored — draining queue...');
    await _drainQueue();
    await _syncFromMongo();
  }

  // ── Helper ─────────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }
}
