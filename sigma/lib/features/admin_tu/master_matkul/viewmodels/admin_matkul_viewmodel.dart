import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import '../../../../../core/network/mongo_database.dart';
import '../../../../data/models/matkul_model.dart';

const _kBoxMatkul = 'admin_matkul';
const _kBoxProdi = 'admin_prodi';
const _kBoxQueue = 'matkul_queue';

enum SyncStatus { idle, pending, syncing, synced, failed }

class AdminMatkulViewModel extends ChangeNotifier {
  List<MatkulModel> _matkulList = [];
  Map<String, String> _prodiMap = {};

  bool _isLoading = false;
  bool _isSyncing = false;

  // FIX: pisah flag fetch-level dari flag sync-level agar tidak saling blok
  bool _isFetchInProgress = false;
  bool _isSyncInProgress = false;

  SyncStatus _syncStatus = SyncStatus.idle;
  Set<String> _pendingIds = {};

  List<MatkulModel> get matkulList => _matkulList;
  Map<String, String> get prodiMap => _prodiMap;
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
    if (_isFetchInProgress) return;
    _isFetchInProgress = true;
    try {
      _loadFromLocal();
      _rebuildPendingIds();
      await _drainQueue();
      await _syncFromMongo();
    } finally {
      _isFetchInProgress = false;
    }
  }

  // ─── Load lokal ───────────────────────────────────────────────────────────
  void _loadFromLocal() {
    try {
      final savedProdi = _prodiBox.get('prodiMap');
      if (savedProdi != null) {
        _prodiMap = Map<String, String>.from(savedProdi);
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
    if (!await _ensureOnline()) return;

    _isSyncInProgress = true;
    _isLoading = true;
    notifyListeners();

    try {
      final prodiDocs = await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('program_studi').find().toList(),
      );
      final newProdiMap = <String, String>{};

      for (final p in prodiDocs) {
        final key = p['_id'] is ObjectId
            ? (p['_id'] as ObjectId).toHexString()
            : p['_id'].toString();
        newProdiMap[key] = p['nama_prodi']?.toString() ?? '-';
      }
      _prodiMap = newProdiMap;
      await _prodiBox.put('prodiMap', _prodiMap);

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

    final model = MatkulModel(
      id: newId,
      kodeMk: kodeMk,
      namaMatkul: namaMatkul,
      programStudi: namaProdi,
      idProdi: idProdi,
      sks: sks,
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

    final updated = MatkulModel(
      id: id,
      kodeMk: kodeMk,
      namaMatkul: namaMatkul,
      programStudi: namaProdi,
      idProdi: idProdi,
      sks: sks,
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
  Future<void> _drainQueue() async {
    if (!await _ensureOnline() || _queueBox.isEmpty) return;

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
          await MongoDatabase.runSafe(
            () => col.replaceOne(where.id(ObjectId.fromHexString(op['id'])), {
              '_id': ObjectId.fromHexString(op['id']),
              'kode_mk': op['kodeMk'],
              'nama_mk': op['namaMatkul'],
              'id_prodi': ObjectId.fromHexString(op['idProdi']),
              'sks': op['sks'],
              'created_at': DateTime.now(),
              'updated_at': DateTime.now(),
            }, upsert: true),
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
                  .set('updated_at', DateTime.now()),
            ),
          );
        } else if (op['operation'] == 'delete') {
          await MongoDatabase.runSafe(
            () => col.deleteOne(where.id(ObjectId.fromHexString(op['id']))),
          );
        }

        await _queueBox.delete(key);
        final syncedId = op['id']?.toString();
        if (syncedId != null) _pendingIds.remove(syncedId);
        debugPrint('Matkul queue item $key synced');
      } catch (e) {
        failCount++;
        debugPrint(
          'Matkul queue item $key gagal: $e — lanjut ke item berikutnya',
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
