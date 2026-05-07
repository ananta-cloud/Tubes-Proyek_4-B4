import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import '../../../../../core/network/mongo_database.dart';
import '../models/matkul_model.dart';

const _kBoxMatkul = 'admin_matkul';
const _kBoxProdi = 'admin_prodi';
const _kBoxQueue = 'matkul_queue';

class AdminMatkulViewModel extends ChangeNotifier {
  List<MatkulModel> _matkulList = [];
  Map<String, String> _prodiMap = {};
  bool _isLoading = false;
  bool _isSyncing = false;

  List<MatkulModel> get matkulList => _matkulList;
  Map<String, String> get prodiMap => _prodiMap;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get pendingQueueCount => _queueBox.length;

  // ─── Boxes ───────────────────────────────────────────────────────────────
  Box<MatkulModel> get _matkulBox => Hive.box<MatkulModel>(_kBoxMatkul);
  Box<Map> get _queueBox => Hive.box<Map>(_kBoxQueue);

  // ProdiMap disimpan sebagai JSON string di box terpisah
  Box get _prodiBox => Hive.box(_kBoxProdi);

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> fetchMatkul() async {
    _loadFromLocal();
    await _syncFromMongo();
  }

  // ─── Load lokal ───────────────────────────────────────────────────────────
  void _loadFromLocal() {
    // Load prodiMap dari Hive
    final savedProdi = _prodiBox.get('prodiMap');
    if (savedProdi != null) {
      _prodiMap = Map<String, String>.from(savedProdi);
    }
    // Load matkul dari Hive
    _matkulList = _matkulBox.values.toList();
    notifyListeners();
  }

  // ─── Sync dari MongoDB ────────────────────────────────────────────────────
  Future<void> _syncFromMongo() async {
    final isOnline = await _checkOnline();
    if (!isOnline) return;

    _isLoading = true;
    notifyListeners();
    try {
      // 1. Fetch prodi
      final prodiDocs = await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('program_studi').find().toList(),
      );
      _prodiMap = {
        for (final p in prodiDocs)
          (p['_id'] is ObjectId
                  ? (p['_id'] as ObjectId).toHexString()
                  : p['_id'].toString()):
              p['nama_prodi']?.toString() ?? '-',
      };
      // Simpan prodiMap ke Hive
      await _prodiBox.put('prodiMap', _prodiMap);

      // 2. Fetch matkul
      final mkDocs = await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('mata_kuliah').find().toList(),
      );
      await _matkulBox.clear();
      for (final d in mkDocs) {
        final idProdiHex = d['id_prodi'] is ObjectId
            ? (d['id_prodi'] as ObjectId).toHexString()
            : d['id_prodi']?.toString() ?? '';
        final namaProdi = _prodiMap[idProdiHex] ?? '-';
        final model = MatkulModel.fromMongo(d, namaProdi: namaProdi);
        await _matkulBox.put(model.id, model);
      }
      _loadFromLocal();
    } catch (e) {
      debugPrint('❌ AdminMatkulViewModel._syncFromMongo: $e');
    } finally {
      _isLoading = false;
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

    // 1. Simpan ke Hive
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

    // 2. Masukkan ke queue
    await _queueBox.add({
      'operation': 'add',
      'id': newId,
      'kodeMk': kodeMk,
      'namaMatkul': namaMatkul,
      'idProdi': idProdi,
      'sks': sks,
    });

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

    // 1. Update Hive
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

    // 2. Masukkan ke queue
    await _queueBox.add({
      'operation': 'update',
      'id': id,
      'kodeMk': kodeMk,
      'namaMatkul': namaMatkul,
      'idProdi': idProdi,
      'sks': sks,
    });

    await _drainQueue();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────
  Future<void> deleteMatkul(String id) async {
    // 1. Hapus dari Hive
    await _matkulBox.delete(id);
    _loadFromLocal();

    // 2. Masukkan ke queue
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
      final op = Map<String, dynamic>.from(_queueBox.get(key) ?? {});
      if (op.isEmpty) continue;

      try {
        final col = MongoDatabase.db.collection('mata_kuliah');

        if (op['operation'] == 'add') {
          await MongoDatabase.runSafe(
            () => col.insertOne({
              '_id': ObjectId.fromHexString(op['id']),
              'kode_mk': op['kodeMk'],
              'nama_mk': op['namaMatkul'],
              'id_prodi': ObjectId.fromHexString(op['idProdi']),
              'sks': op['sks'],
              'created_at': DateTime.now(),
            }),
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
      } catch (e) {
        debugPrint('❌ AdminMatkulViewModel._drainQueue: $e');
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
