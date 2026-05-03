import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../../../../../core/network/mongo_database.dart';
import '../models/matkul_model.dart';

class AdminMatkulViewModel extends ChangeNotifier {
  List<MatkulModel> _matkulList = [];
  bool _isLoading = false;

  // Cache prodi: { idProdiHex -> nama_prodi }
  Map<String, String> _prodiMap = {};

  List<MatkulModel> get matkulList => _matkulList;
  bool get isLoading => _isLoading;
  Map<String, String> get prodiMap => _prodiMap;

  Future<void> fetchMatkul() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Fetch semua prodi dulu (sequential, pakai runSafe)
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

      // 2. Fetch matkul (sequential setelah prodi selesai)
      final mkDocs = await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('mata_kuliah').find().toList(),
      );

      _matkulList = mkDocs.map((d) {
        final idProdiHex = d['id_prodi'] is ObjectId
            ? (d['id_prodi'] as ObjectId).toHexString()
            : d['id_prodi']?.toString() ?? '';
        final namaProdi = _prodiMap[idProdiHex] ?? '-';
        return MatkulModel.fromMongo(d, namaProdi: namaProdi);
      }).toList();
    } catch (e) {
      debugPrint('❌ AdminMatkulViewModel.fetchMatkul: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMatkul({
    required String kodeMk,
    required String namaMatkul,
    required String idProdi,
    required int sks,
  }) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.db.collection('mata_kuliah').insertOne({
          '_id': ObjectId(),
          'kode_mk': kodeMk,
          'nama_mk': namaMatkul,
          'id_prodi': ObjectId.fromHexString(idProdi),
          'sks': sks,
          'created_at': DateTime.now(),
        }),
      );
      await fetchMatkul();
    } catch (e) {
      debugPrint('❌ AdminMatkulViewModel.addMatkul: $e');
    }
  }

  Future<void> updateMatkul({
    required String id,
    required String kodeMk,
    required String namaMatkul,
    required String idProdi,
    required int sks,
  }) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.db
            .collection('mata_kuliah')
            .updateOne(
              where.id(ObjectId.fromHexString(id)),
              modify
                  .set('kode_mk', kodeMk)
                  .set('nama_mk', namaMatkul)
                  .set('id_prodi', ObjectId.fromHexString(idProdi))
                  .set('sks', sks)
                  .set('updated_at', DateTime.now()),
            ),
      );
      await fetchMatkul();
    } catch (e) {
      debugPrint('❌ AdminMatkulViewModel.updateMatkul: $e');
    }
  }

  Future<void> deleteMatkul(String id) async {
    try {
      await MongoDatabase.runSafe(
        () => MongoDatabase.db
            .collection('mata_kuliah')
            .deleteOne(where.id(ObjectId.fromHexString(id))),
      );
      _matkulList.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AdminMatkulViewModel.deleteMatkul: $e');
    }
  }
}
