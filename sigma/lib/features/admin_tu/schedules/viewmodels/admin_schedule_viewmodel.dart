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
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  bool _isSyncInProgress = false;
  bool _isImporting = false;
  String _importStatus = '';
  SyncStatus _syncStatus = SyncStatus.idle;

  // Set ID jadwal yang masih pending (belum masuk MongoDB)
  Set<String> _pendingIds = {};

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String get importStatus => _importStatus;
  SyncStatus get syncStatus => _syncStatus;
  Set<String> get pendingIds => _pendingIds;

  // Jumlah jadwal (bukan item queue) yang masih pending
  int get pendingScheduleCount => _pendingIds.length;

  bool isSchedulePending(String id) => _pendingIds.contains(id);

  // ── Boxes ──────────────────────────────────────────────────────────────────
  Box<ScheduleModel> get _schedulesBox =>
      Hive.box<ScheduleModel>(_kBoxSchedules);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> fetchSchedules() async {
    if (_isSyncInProgress) return;
    _loadFromLocal();
    _rebuildPendingIds();
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

  // ── Rebuild set ID yang masih pending dari isi queue ───────────────────────
  void _rebuildPendingIds() {
    final ids = <String>{};
    for (final key in _queueBox.keys) {
      final raw = _queueBox.get(key);
      if (raw == null) continue;
      final op = Map<String, dynamic>.from(raw);
      if (op['operation'] == 'import_batch') {
        final opIds = List<String>.from(op['ids'] ?? []);
        ids.addAll(opIds);
      }
    }
    _pendingIds = ids;

    final newStatus = ids.isEmpty ? SyncStatus.idle : SyncStatus.pending;
    if (_syncStatus != SyncStatus.syncing && _syncStatus != newStatus) {
      _syncStatus = newStatus;
    }
    notifyListeners();
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

      // 2. Hapus jadwal lama dari MongoDB jika online
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

      // 4. Simpan ke MongoDB atau queue
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

        // Berhasil online — tidak ada pending
        _pendingIds = {};
        _syncStatus = SyncStatus.synced;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        _syncStatus = SyncStatus.idle;
        notifyListeners();
      } else {
        // Offline — masukkan ke queue dengan semua ID jadwal
        await _queueBox.add({
          'operation': 'import_batch',
          'ids': parsed.map((s) => s.id).toList(),
          'kelas_keys': kelasKeys.toList(),
        });
        // Tandai semua ID sebagai pending
        _pendingIds = parsed.map((s) => s.id).toSet();
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

    // ✅ Kumpulkan ID semua jadwal yang berhasil di-drain untuk di-enrich
    final enrichIds = <String>[];

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

          // ✅ Tandai ID ini untuk enrichment nama MK & dosen
          enrichIds.addAll(ids);
        }

        await _queueBox.delete(key);
        debugPrint('✅ Queue item $key synced');
      } catch (e) {
        debugPrint('❌ _drainQueue key=$key: $e');
        allSuccess = false;
        break;
      }
    }

    if (allSuccess && _queueBox.isEmpty) {
      // Semua berhasil — kosongkan pending IDs
      _pendingIds = {};
      _syncStatus = SyncStatus.synced;
      notifyListeners();

      // ✅ Enrich nama MK & dosen yang masih berupa kode (diimport saat offline)
      if (enrichIds.isNotEmpty) {
        await enrichPendingSchedules(enrichIds);
      }

      await Future.delayed(const Duration(seconds: 3));
      _syncStatus = SyncStatus.idle;
    } else {
      _rebuildPendingIds();
      _syncStatus = allSuccess ? SyncStatus.idle : SyncStatus.failed;
    }
    notifyListeners();
  }

  // ── Enrich nama MK & dosen untuk jadwal yang diimport saat offline ─────────
  //
  //  Dipanggil setelah _drainQueue berhasil. Jadwal yang diimport offline
  //  memiliki nama = kode (placeholder). Method ini lookup nama aslinya
  //  dari MongoDB dan update Hive + Mongo.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> enrichPendingSchedules(List<String> ids) async {
    if (ids.isEmpty) return;
    if (!await _checkOnline()) return;

    debugPrint('🔄 Enriching ${ids.length} jadwal (patch nama MK & dosen)...');

    // Kumpulkan semua kode unik dari jadwal yang perlu di-enrich
    final kodeMkSet = <String>{};
    final kodeDosenSet = <String>{};

    for (final id in ids) {
      final s = _schedulesBox.get(id);
      if (s == null) continue;
      // Hanya enrich jika memang butuh (flag dari parser) atau nama = kode
      if (!s.needsEnrichment && s.namaMatkul != s.kodeMk) continue;
      if (s.kodeMk.isNotEmpty) kodeMkSet.add(s.kodeMk);
      for (final k in s.kodeDosen.split(';')) {
        final t = k.trim();
        if (t.isNotEmpty) kodeDosenSet.add(t);
      }
    }

    if (kodeMkSet.isEmpty && kodeDosenSet.isEmpty) {
      debugPrint('ℹ️ Tidak ada jadwal yang perlu di-enrich.');
      return;
    }

    // Batch lookup ke MongoDB
    final namaMkMap = <String, String>{};
    final namaDosenMap = <String, String>{};

    try {
      if (kodeMkSet.isNotEmpty) {
        final mkDocs = await MongoDatabase.runSafe(
          () => MongoDatabase.mataKuliahCollection.find(<String, dynamic>{
            'kode_mk': {'\$in': kodeMkSet.toList()},
          }).toList(),
        );
        for (final d in mkDocs) {
          final kode = d['kode_mk']?.toString() ?? '';
          final nama =
              d['nama_mk']?.toString() ?? d['nama_matkul']?.toString() ?? '';
          if (kode.isNotEmpty && nama.isNotEmpty) namaMkMap[kode] = nama;
        }
        debugPrint(
          '✅ Enrich lookup MK: ${namaMkMap.length}/${kodeMkSet.length} ditemukan',
        );
      }

      if (kodeDosenSet.isNotEmpty) {
        final dosenDocs = await MongoDatabase.runSafe(
          () => MongoDatabase.dosenCollection.find(<String, dynamic>{
            'kode_dosen': {'\$in': kodeDosenSet.toList()},
          }).toList(),
        );
        for (final d in dosenDocs) {
          final kode = d['kode_dosen']?.toString() ?? '';
          final nama = d['nama_dosen']?.toString() ?? '';
          if (kode.isNotEmpty && nama.isNotEmpty) namaDosenMap[kode] = nama;
        }
        debugPrint(
          '✅ Enrich lookup dosen: ${namaDosenMap.length}/${kodeDosenSet.length} ditemukan',
        );
      }
    } catch (e) {
      debugPrint('❌ enrichPendingSchedules lookup gagal: $e');
      return;
    }

    // Update Hive + Mongo untuk setiap jadwal yang nama-nya berhasil di-resolve
    int enrichedCount = 0;
    for (final id in ids) {
      final s = _schedulesBox.get(id);
      if (s == null) continue;

      final newNamaMk = namaMkMap[s.kodeMk];

      final kodeList = s.kodeDosen
          .split(';')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
      final newNamaDosen = kodeList.isEmpty
          ? null
          : kodeList.map((k) => namaDosenMap[k] ?? k).join(';');

      // Hanya update jika ada perubahan nyata
      final mkChanged = newNamaMk != null && newNamaMk != s.namaMatkul;
      final dosenChanged = newNamaDosen != null && newNamaDosen != s.namaDosen;

      if (!mkChanged && !dosenChanged) continue;

      final updated = s.copyWith(
        namaMatkul: mkChanged ? newNamaMk : s.namaMatkul,
        namaDosen: dosenChanged ? newNamaDosen : s.namaDosen,
        needsEnrichment: false,
      );

      // Update Hive
      await _schedulesBox.put(id, updated);

      // Patch Mongo (best-effort — tidak fatal jika gagal)
      try {
        await MongoDatabase.runSafe(
          () => MongoDatabase.schedulesCollection.updateOne(
            where.eq('_id', ObjectId.parse(id)),
            modify
                .set('nama_matkul', updated.namaMatkul)
                .set('nama_dosen', updated.namaDosen)
                .set('needs_enrichment', false)
                .set('updated_at', DateTime.now()),
          ),
        );
        enrichedCount++;
      } catch (e) {
        debugPrint('⚠️ Patch Mongo untuk id=$id gagal: $e');
      }
    }

    debugPrint('✅ Enrichment selesai: $enrichedCount jadwal diperbarui.');

    if (enrichedCount > 0) {
      _loadFromLocal();
      notifyListeners();
    }
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
