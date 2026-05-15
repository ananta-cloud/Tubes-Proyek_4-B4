import 'package:mongo_dart/mongo_dart.dart';
import '../../core/network/mongo_database.dart';
import '../models/mata_kuliah_model.dart';

class MataKuliahService {
  ObjectId _safeObjectId(String id) {
    String cleanId = id
        .replaceAll('ObjectId("', '')
        .replaceAll('")', '')
        .replaceAll("'", "")
        .trim();
    return ObjectId.fromHexString(cleanId);
  }

  // Ambil daftar mata kuliah yang diampu dosen berdasarkan jurusan
  Future<List<MataKuliahModel>> getMataKuliahByJurusan(String idJurusan) async {
    try {
      final data = await MongoDatabase.runSafe(
        () => MongoDatabase.mataKuliahCollection
            .find(where.eq('id_jurusan', _safeObjectId(idJurusan)))
            .toList(),
      );
      return data.map((e) => MataKuliahModel.fromJson(e)).toList();
    } catch (e) {
      print("🔥 Error Get Mata Kuliah: $e");
      return [];
    }
  }

  // Ambil daftar mata kuliah berdasarkan prodi
  Future<List<MataKuliahModel>> getMataKuliahByProdi(String idProdi) async {
    try {
      final data = await MongoDatabase.runSafe(
        () => MongoDatabase.mataKuliahCollection
            .find(where.eq('id_prodi', _safeObjectId(idProdi)))
            .toList(),
      );
      return data.map((e) => MataKuliahModel.fromJson(e)).toList();
    } catch (e) {
      print("🔥 Error Get Mata Kuliah: $e");
      return [];
    }
  }

  // Ambil semua mata kuliah
  Future<List<MataKuliahModel>> getAllMataKuliah() async {
    try {
      final data = await MongoDatabase.runSafe(
        () => MongoDatabase.mataKuliahCollection.find().toList(),
      );
      return data.map((e) => MataKuliahModel.fromJson(e)).toList();
    } catch (e) {
      print("🔥 Error Get All Mata Kuliah: $e");
      return [];
    }
  }
}
