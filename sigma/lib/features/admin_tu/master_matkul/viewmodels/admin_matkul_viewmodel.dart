import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import '../../../../../core/network/mongo_database.dart';
import '../../../../data/models/matkul_model.dart';

const _kBoxMatkul = 'admin_matkul';
const _kBoxProdi = 'admin_prodi';
const _kBoxQueue = 'matkul_queue';

class AdminMatkulViewModel extends ChangeNotifier {
  List<MatkulModel> _matkulList = [];
  Map<String, String> _prodiMap = {};

  Map<String, String> _prodiJurusanMap = {};
  Map<String, String> get prodiJurusanMap => _prodiJurusanMap;

  bool _isLoading = false;
  bool _isSyncing = false;

  // Guard agar tidak ada dua sync berjalan bersamaan
  bool _isSyncInProgress = false;

  List<MatkulModel> get matkulList => _matkulList;
  Map<String, String> get prodiMap => _prodiMap;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get pendingQueueCount => _queueBox.length;

  // ─── Boxes ────────────────────────────────────────────────────────────────
  Box<MatkulModel> get _matkulBox => Hive.box<MatkulModel>(_kBoxMatkul);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);
  Box get _prodiBox => Hive.box(_kBoxProdi);

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> fetchMatkul() async {
    if (_isSyncInProgress) return; // cegah double sync
    _loadFromLocal();
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
      debugPrint(' AdminMatkulViewModel._loadFromLocal: $e');
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
      // 1. Fetch prodi
      final prodiDocs = await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('program_studi').find().toList(),
      );
      final newProdiMap = <String, String>{};
      final newProdiJurusanMap = <String, String>{}; // ← tambah

      for (final p in prodiDocs) {
        final key = p['_id'] is ObjectId
            ? (p['_id'] as ObjectId).toHexString()
            : p['_id'].toString();
        newProdiMap[key] = p['nama_prodi']?.toString() ?? '-';

        // simpan mapping prodi -> jurusan
        final idJurusan = p['id_jurusan'] is ObjectId
            ? (p['id_jurusan'] as ObjectId).toHexString()
            : p['id_jurusan']?.toString() ?? '';
        newProdiJurusanMap[key] = idJurusan;
      }
      _prodiMap = newProdiMap;
      _prodiJurusanMap = newProdiJurusanMap; // ← tambah
      await _prodiBox.put('prodiMap', _prodiMap);
      await _prodiBox.put('prodiJurusanMap', _prodiJurusanMap);

      // 2. Hanya overwrite Hive jika queue kosong
      if (_queueBox.isEmpty) {
        final mkDocs = await MongoDatabase.runSafe(
          () => MongoDatabase.db.collection('mata_kuliah').find().toList(),
        );

        // Gunakan putAll untuk batch update — lebih aman dari clear() + loop
        final newEntries = <String, MatkulModel>{};
        for (final d in mkDocs) {
          final idProdiHex = d['id_prodi'] is ObjectId
              ? (d['id_prodi'] as ObjectId).toHexString()
              : d['id_prodi']?.toString() ?? '';
          final namaProdi = _prodiMap[idProdiHex] ?? '-';
          final model = MatkulModel.fromMongo(d, namaProdi: namaProdi);
          newEntries[model.id] = model;
        }

        // Hapus key lama yang sudah tidak ada di MongoDB
        final oldKeys = _matkulBox.keys.cast<String>().toList();
        final newKeys = newEntries.keys.toSet();
        for (final oldKey in oldKeys) {
          if (!newKeys.contains(oldKey)) {
            await _matkulBox.delete(oldKey);
          }
        }

        // Upsert semua data baru
        await _matkulBox.putAll(newEntries);
      }

      _loadFromLocal();
    } catch (e) {
      debugPrint('❌ AdminMatkulViewModel._syncFromMongo: $e');
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

    // 1. Simpan ke Hive langsung
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

    // 2. Tambah ke queue
    await _queueBox.add({
      'operation': 'add',
      'id': newId,
      'kodeMk': kodeMk,
      'namaMatkul': namaMatkul,
      'idProdi': idProdi,
      'sks': sks,
      'idJurusan': idJurusan,
    });

    // 3. Drain — jika online langsung sync, jika tidak tetap tersimpan di queue
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

    await _drainQueue();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────
  Future<void> deleteMatkul(String id) async {
    await _matkulBox.delete(id);
    _loadFromLocal();

    await _queueBox.add({'operation': 'delete', 'id': id});

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
        final col = MongoDatabase.db.collection('mata_kuliah');

        if (op['operation'] == 'add') {
          // Cek dulu apakah sudah ada di MongoDB (hindari duplicate)
          final existing = await MongoDatabase.runSafe(
            () => col.findOne(where.id(ObjectId.fromHexString(op['id']))),
          );
          if (existing == null) {
            await MongoDatabase.runSafe(
              () => col.insertOne({
                '_id': ObjectId.fromHexString(op['id']),
                'kode_mk': op['kodeMk'],
                'nama_mk': op['namaMatkul'],
                'id_prodi': ObjectId.fromHexString(op['idProdi']),
                'sks': op['sks'],
                'created_at': DateTime.now(),
                'updated_at': DateTime.now(),
                'id_jurusan': ObjectId.fromHexString(op['idJurusan']),
              }),
            );
          }
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

        await _queueBox.delete(key);
        debugPrint('✅ Matkul queue item $key synced');
      } catch (e) {
        debugPrint('❌ AdminMatkulViewModel._drainQueue key=$key: $e');
        break;
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  // ─── Connection restored ──────────────────────────────────────────────────
  Future<void> onConnectionRestored() async {
    debugPrint('🔄 Connection restored — draining matkul queue...');
    await _drainQueue();
    await _syncFromMongo();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  Future<bool> _checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !(result as List).contains(ConnectivityResult.none);
  }
}
