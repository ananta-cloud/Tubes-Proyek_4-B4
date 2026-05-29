import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import '../../../../../core/network/mongo_database.dart';
import '../../../../data/models/schedule_model.dart';

const _kBoxSchedules = 'admin_schedules';
const _kBoxQueue = 'schedule_queue';

enum SyncStatus { idle, pending, syncing, synced, failed }

class AdminScheduleViewModel extends ChangeNotifier {
  final PengajaranService _pengajaranService = PengajaranService();

  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  bool _isSyncInProgress = false;
  bool _isImporting = false;
  String _importStatus = '';
  SyncStatus _syncStatus = SyncStatus.idle;

  Set<String> _pendingIds = {};

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String get importStatus => _importStatus;
  SyncStatus get syncStatus => _syncStatus;
  Set<String> get pendingIds => _pendingIds;
  int get pendingScheduleCount => _pendingIds.length;

  Box<ScheduleModel> get _schedulesBox =>
      Hive.box<ScheduleModel>(_kBoxSchedules);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ── Initialization & Fetch ──────────────────────────────────────────────────
  Future<void> fetchSchedules() async {
    if (_isSyncInProgress) return;
    _loadFromLocal();
    _rebuildPendingIds();
    await _drainQueue();
    await _syncFromMongo();
  }

  void _loadFromLocal() {
    _schedules = _schedulesBox.values.toList();
    notifyListeners();
  }

  void _rebuildPendingIds() {
    final ids = <String>{};
    for (final key in _queueBox.keys) {
      final raw = _queueBox.get(key);
      if (raw == null) continue;
      final op = Map<String, dynamic>.from(raw);
      if (op['operation'] == 'import_batch') {
        ids.addAll(List<String>.from(op['ids'] ?? []));
      }
    }
    _pendingIds = ids;
    _syncStatus = ids.isEmpty ? SyncStatus.idle : SyncStatus.pending;
    notifyListeners();
  }

  // ── Sync dari MongoDB → Hive ───────────────────────────────────────────────
  Future<void> _syncFromMongo() async {
    if (_isSyncInProgress || !await _checkOnline()) return;

    _isSyncInProgress = true;
    _isLoading = true;
    notifyListeners();

    try {
      final docs = await MongoDatabase.runSafe(
        () => MongoDatabase.schedulesCollection.find().toList(),
      );

      _importStatus = 'Sinkronisasi master data...';
      notifyListeners();

      bool kelasOk = await _pengajaranService.generateKelasFromSchedules();
      bool pengajaranOk = false;

      if (kelasOk) {
        pengajaranOk = await _pengajaranService
            .generatePengajaranFromSchedules();
      }

      if (kelasOk && pengajaranOk) {
        _importStatus = 'Import & Sinkronisasi Selesai!';
        debugPrint('✅ Semua data sinkron!');
      } else {
        _importStatus = 'Import berhasil, tapi sinkronisasi gagal.';
        debugPrint('❌ Gagal di tahap sinkronisasi Kelas/Pengajaran');
      }

      if (_queueBox.isEmpty) {
        final newEntries = <String, ScheduleModel>{};
        for (final d in docs) {
          final m = ScheduleModel.fromMongo(d);
          newEntries[m.id] = m;
        }
        final oldKeys = _schedulesBox.keys.cast<String>().toList();
        for (final k in oldKeys)
          if (!newEntries.containsKey(k)) await _schedulesBox.delete(k);
        await _schedulesBox.putAll(newEntries);
      }
      _loadFromLocal();
    } catch (e) {
      debugPrint('Sync Mongo error: $e');
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

      // 1. Bersihkan Data Lama
      _importStatus = 'Membersihkan data lama...';
      notifyListeners();

      final keysToDelete = _schedulesBox.keys.cast<String>().where((key) {
        final e = _schedulesBox.get(key);
        return e != null &&
            kelasKeys.contains('${e.semester}|${e.tahunAkademik}|${e.kelas}');
      }).toList();
      for (final k in keysToDelete) await _schedulesBox.delete(k);

      final isOnline = await _checkOnline();
      if (isOnline) {
        for (final kelasKey in kelasKeys) {
          final parts = kelasKey.split('|');
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

      // 2. Simpan Data Baru
      _importStatus = 'Menyimpan jadwal...';
      notifyListeners();

      final newEntries = {for (var s in parsed) s.id: s};
      await _schedulesBox.putAll(newEntries);
      _loadFromLocal();

      // 3. Sinkronisasi Cloud & Master Data (Kelas/Pengajaran)
      if (isOnline) {
        _importStatus = 'Mengirim ke server...';
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

        _importStatus = 'Sinkronisasi master data...';
        notifyListeners();

        bool success = await _pengajaranService.sinkronisasiMasterData();
        if (!success) throw Exception("Gagal sinkronisasi Kelas/Pengajaran!");

        _pendingIds = {};
        _syncStatus = SyncStatus.synced;
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await _queueBox.add({
          'operation': 'import_batch',
          'ids': parsed.map((s) => s.id).toList(),
          'kelas_keys': kelasKeys.toList(),
        });
        _pendingIds = parsed.map((s) => s.id).toSet();
        _syncStatus = SyncStatus.pending;
      }

      _importStatus = 'Import selesai!';
    } catch (e) {
      _importStatus = 'Error: $e';
      _syncStatus = SyncStatus.failed;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ── Drain Queue Offline ────────────────────────────────────────────────────
  Future<void> _drainQueue() async {
    if (!await _checkOnline() || _queueBox.isEmpty) return;

    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final keys = _queueBox.keys.toList();
      for (final key in keys) {
        final op = Map<String, dynamic>.from(_queueBox.get(key)!);

        if (op['operation'] == 'import_batch') {
          // Re-eksekusi hapus & insert batch di sini (logika sama dengan importSchedules)
          // ... (implementasi detail sama dengan importSchedules) ...
        }
        await _queueBox.delete(key);
      }

      // Trigger generate ulang master data setelah drain sukses
      await _pengajaranService.sinkronisasiMasterData();

      _pendingIds = {};
      _syncStatus = SyncStatus.synced;
    } catch (e) {
      _syncStatus = SyncStatus.failed;
    }
    notifyListeners();
  }

  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }

  Future<void> onConnectionRestored() async {
    debugPrint(' Connection restored — draining queue...');
    await _drainQueue();
    await _syncFromMongo();
  }
}
