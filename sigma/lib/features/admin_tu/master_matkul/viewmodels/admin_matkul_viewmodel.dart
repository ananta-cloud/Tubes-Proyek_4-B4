import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import '../../../../../core/network/mongo_database.dart';
import '../models/matkul_model.dart';

const _kBoxMatkul = 'admin_matkul';
const _kBoxProdi = 'admin_prodi';
const _kBoxQueue = 'matkul_queue';

enum SyncStatus { idle, pending, syncing, synced, failed }

class AdminMatkulViewModel extends ChangeNotifier {
  List<MatkulModel> _matkulList = [];
  Map<String, String> _prodiMap = {};
  Map<String, String> _prodiJurusanMap = {};

  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isSyncInProgress = false;

  SyncStatus _syncStatus = SyncStatus.idle;
  Set<String> _pendingIds = {};

  List<MatkulModel> get matkulList => _matkulList;
  Map<String, String> get prodiMap => _prodiMap;
  Map<String, String> get prodiJurusanMap => _prodiJurusanMap;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  SyncStatus get syncStatus => _syncStatus;
  Set<String> get pendingIds => _pendingIds;

  int get pendingQueueCount => _queueBox.length;
  int get pendingMatkulCount => _pendingIds.length;
  bool isMatkulPending(String id) => _pendingIds.contains(id);

  Box<MatkulModel> get _matkulBox => Hive.box<MatkulModel>(_kBoxMatkul);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);
  Box get _prodiBox => Hive.box(_kBoxProdi);

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> fetchMatkul() async {
    if (_isSyncInProgress) return;
    _loadFromLocal();
    _rebuildPendingIds();
    await _drainQueue();
    await _syncFromMongo();
  }

  // ─── Load lokal ───────────────────────────────────────────────────────────
  void _loadFromLocal() {
    try {
      final savedProdi = _prodiBox.get('prodiMap');
      if (savedProdi != null) {
        _prodiMap = Map<String, String>.from(savedProdi);
      }
      final savedJurusan = _prodiBox.get('prodiJurusanMap');
      if (savedJurusan != null) {
        _prodiJurusanMap = Map<String, String>.from(savedJurusan);
      }
      _matkulList = _matkulBox.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('AdminMatkulViewModel._loadFromLocal: $e');
    }
  }

  // ─── Rebuild pending IDs ──────────────────────────────────────────────────
  void _rebuildPendingIds() {
    final ids = <String>{};
    for (final key in _queueBox.keys) {
      final raw = _queueBox.get(key);
      if (raw == null) continue;
      final op = Map<String, dynamic>.from(raw);
      if (op['operation'] == 'add' || op['operation'] == 'update') {
        final id = op['id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    _pendingIds = ids;

    final newStatus = ids.isEmpty ? SyncStatus.idle : SyncStatus.pending;
    if (_syncStatus != SyncStatus.syncing && _syncStatus != newStatus) {
      _syncStatus = newStatus;
    }
    notifyListeners();
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
      final prodiDocs = await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('program_studi').find().toList(),
      );
      final newProdiMap = <String, String>{};
      final newProdiJurusanMap = <String, String>{};

      for (final p in prodiDocs) {
        final key = p['_id'] is ObjectId
            ? (p['_id'] as ObjectId).toHexString()
            : p['_id'].toString();
        newProdiMap[key] = p['nama_prodi']?.toString() ?? '-';
        final idJurusan = p['id_jurusan'] is ObjectId
            ? (p['id_jurusan'] as ObjectId).toHexString()
            : p['id_jurusan']?.toString() ?? '';
        newProdiJurusanMap[key] = idJurusan;
      }
      _prodiMap = newProdiMap;
      _prodiJurusanMap = newProdiJurusanMap;
      await _prodiBox.put('prodiMap', _prodiMap);
      await _prodiBox.put('prodiJurusanMap', _prodiJurusanMap);

      if (_queueBox.isEmpty) {
        final mkDocs = await MongoDatabase.runSafe(
          () => MongoDatabase.db.collection('mata_kuliah').find().toList(),
        );

        final newEntries = <String, MatkulModel>{};
        for (final d in mkDocs) {
          final idProdiHex = d['id_prodi'] is ObjectId
              ? (d['id_prodi'] as ObjectId).toHexString()
              : d['id_prodi']?.toString() ?? '';
          final namaProdi = _prodiMap[idProdiHex] ?? '-';
          final model = MatkulModel.fromMongo(d, namaProdi: namaProdi);
          newEntries[model.id] = model;
        }

        final oldKeys = _matkulBox.keys.cast<String>().toList();
        final newKeys = newEntries.keys.toSet();
        for (final oldKey in oldKeys) {
          if (!newKeys.contains(oldKey)) await _matkulBox.delete(oldKey);
        }
        await _matkulBox.putAll(newEntries);
      }

      _loadFromLocal();
    } catch (e) {
      debugPrint('AdminMatkulViewModel._syncFromMongo: $e');
    } finally {
      _isLoading = false;
      _isSyncInProgress = false;
      notifyListeners();
    }
  }

  // ─── Add ──────────────────────────────────────────────────────────────────
  Future<void> addMatkul({
    required String kodeMk,
    required String namaMatkul,
    required String idProdi,
    required int sks,
  }) async {
    final newId = ObjectId().toHexString();
    final namaProdi = _prodiMap[idProdi] ?? '-';
    final idJurusan = _prodiJurusanMap[idProdi] ?? '';

    final model = MatkulModel(
      id: newId,
      kodeMk: kodeMk,
      namaMatkul: namaMatkul,
      programStudi: namaProdi,
      idProdi: idProdi,
      sks: sks,
      idJurusan: idJurusan,
    );
    await _matkulBox.put(newId, model);
    _loadFromLocal();

    await _queueBox.add({
      'operation': 'add',
      'id': newId,
      'kodeMk': kodeMk,
      'namaMatkul': namaMatkul,
      'idProdi': idProdi,
      'sks': sks,
      'idJurusan': idJurusan,
    });

    _pendingIds.add(newId);
    _syncStatus = SyncStatus.pending;
    notifyListeners();

    await _drainQueue();
  }

  // ─── Update ───────────────────────────────────────────────────────────────
  Future<void> updateMatkul({
    required String id,
    required String kodeMk,
    required String namaMatkul,
    required String idProdi,
    required int sks,
  }) async {
    final namaProdi = _prodiMap[idProdi] ?? '-';
    final idJurusan = _prodiJurusanMap[idProdi] ?? '';

    final updated = MatkulModel(
      id: id,
      kodeMk: kodeMk,
      namaMatkul: namaMatkul,
      programStudi: namaProdi,
      idProdi: idProdi,
      sks: sks,
      idJurusan: idJurusan,
    );
    await _matkulBox.put(id, updated);
    _loadFromLocal();

    await _queueBox.add({
      'operation': 'update',
      'id': id,
      'kodeMk': kodeMk,
      'namaMatkul': namaMatkul,
      'idProdi': idProdi,
      'sks': sks,
      'idJurusan': idJurusan,
    });

    _pendingIds.add(id);
    _syncStatus = SyncStatus.pending;
    notifyListeners();

    await _drainQueue();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────
  Future<void> deleteMatkul(String id) async {
    await _matkulBox.delete(id);
    _pendingIds.remove(id);
    _loadFromLocal();

    await _queueBox.add({'operation': 'delete', 'id': id});
    await _drainQueue();
  }

  // ─── Queue drain ──────────────────────────────────────────────────────────
  //
  // FIX: hilangkan `break` — proses SEMUA item queue meski ada yang gagal.
  // Setiap item dicoba secara independen; yang gagal tetap di queue untuk
  // dicoba lagi, yang berhasil langsung dihapus dari queue.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _drainQueue() async {
    final isOnline = await _checkOnline();
    if (!isOnline || _queueBox.isEmpty) return;

    _isSyncing = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    final keys = _queueBox.keys.toList();
    int failCount = 0;

    for (final key in keys) {
      final raw = _queueBox.get(key);
      if (raw == null) {
        await _queueBox.delete(key);
        continue;
      }
      final op = Map<String, dynamic>.from(raw);

      try {
        final col = MongoDatabase.db.collection('mata_kuliah');

        if (op['operation'] == 'add') {
          // FIX: pakai insertOne dengan upsert-style — jika sudah ada,
          // update saja. Ini menghindari duplicate key error yang dulu
          // menyebabkan drain berhenti total.
          await MongoDatabase.runSafe(
            () => col.replaceOne(
              where.id(ObjectId.fromHexString(op['id'])),
              {
                '_id': ObjectId.fromHexString(op['id']),
                'kode_mk': op['kodeMk'],
                'nama_mk': op['namaMatkul'],
                'id_prodi': ObjectId.fromHexString(op['idProdi']),
                'sks': op['sks'],
                'created_at': DateTime.now(),
                'updated_at': DateTime.now(),
                'id_jurusan': ObjectId.fromHexString(op['idJurusan']),
              },
              upsert: true, //insert jika belum ada, replace jika sudah
            ),
          );
        } else if (op['operation'] == 'update') {
          await MongoDatabase.runSafe(
            () => col.updateOne(
              where.id(ObjectId.fromHexString(op['id'])),
              modify
                  .set('kode_mk', op['kodeMk'])
                  .set('nama_mk', op['namaMatkul'])
                  .set('id_prodi', ObjectId.fromHexString(op['idProdi']))
                  .set('sks', op['sks'])
                  .set('updated_at', DateTime.now())
                  .set('id_jurusan', ObjectId.fromHexString(op['idJurusan'])),
            ),
          );
        } else if (op['operation'] == 'delete') {
          await MongoDatabase.runSafe(
            () => col.deleteOne(where.id(ObjectId.fromHexString(op['id']))),
          );
        }

        // Berhasil — hapus dari queue dan pending set
        await _queueBox.delete(key);
        final syncedId = op['id']?.toString();
        if (syncedId != null) _pendingIds.remove(syncedId);
        debugPrint('Matkul queue item $key synced');
      } catch (e) {
        // FIX: tidak break — lanjut ke item berikutnya
        failCount++;
        debugPrint(
          '❌ Matkul queue item $key gagal: $e — lanjut ke item berikutnya',
        );
      }
    }

    _isSyncing = false;

    if (failCount == 0 && _queueBox.isEmpty) {
      _pendingIds = {};
      _syncStatus = SyncStatus.synced;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      _syncStatus = SyncStatus.idle;
    } else if (failCount > 0) {
      // Ada yang gagal — rebuild dari sisa queue
      _rebuildPendingIds();
      _syncStatus = SyncStatus.failed;
    } else {
      _rebuildPendingIds();
      _syncStatus = SyncStatus.idle;
    }
    notifyListeners();
  }

  // ─── Connection restored ──────────────────────────────────────────────────
  Future<void> onConnectionRestored() async {
    debugPrint('Connection restored — draining matkul queue...');
    await _drainQueue();
    await _syncFromMongo();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }
}
