import 'package:mongo_dart/mongo_dart.dart'; // Wajib import ini untuk ObjectId
import '../../core/network/mongo_database.dart';

class PengajaranService {
  Future<List<Map<String, dynamic>>> getPengajaranByDosen(
    String idDosen,
  ) async {
    return await MongoDatabase.runSafe(() async {
      try {
        // KONVERSI STRING KE OBJECTID SEBELUM MENCARI
        final objectIdDosen = ObjectId.fromHexString(idDosen);

        // Cari data pengajaran yang id_dosen-nya cocok dengan ObjectId
        final result = await MongoDatabase.db.collection('pengajaran').find({
          'id_dosen': objectIdDosen,
        }).toList();

        print("🔍 Ditemukan ${result.length} kelas untuk dosen ini.");
        return result;
      } catch (e) {
        print("❌ Error format ObjectId di PengajaranService: $e");

        // Fallback: Coba cari pakai string biasa (berjaga-jaga jika ada data lama)
        final fallbackResult = await MongoDatabase.db
            .collection('pengajaran')
            .find({'id_dosen': idDosen})
            .toList();

        return fallbackResult;
      }
    });
  }
}
