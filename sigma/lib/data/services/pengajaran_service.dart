import '../../core/network/mongo_database.dart';
import '../models/pengajaran_model.dart';

class PengajaranService {
  Future<List<Map<String, dynamic>>> getPengajaranByDosen(
    String idDosen,
  ) async {
    return await MongoDatabase.runSafe(() async {
      // Cari data pengajaran yang id_dosen-nya cocok
      return await MongoDatabase.db.collection('pengajaran').find({
        'id_dosen': idDosen,
      }).toList();
    });
  }
}
