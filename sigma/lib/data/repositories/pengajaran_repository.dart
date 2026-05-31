import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/pengajaran_model.dart';
import '../services/pengajaran_service.dart';

class PengajaranRepository {
  final PengajaranService _service = PengajaranService();
  final Box<PengajaranModel> _box = Hive.box<PengajaranModel>('pengajaran');

  List<PengajaranModel> getLocalPengajaran(String idDosen) {
    return _box.values.where((p) => p.kodeDosen == idDosen).toList();
  }

  // Sinkronisasi dari Cloud ke Lokal
  Future<void> syncPengajaran(String idDosen) async {
    final connectivity = await Connectivity().checkConnectivity();
    if ((connectivity as List).contains(ConnectivityResult.none)) return;

    try {
      final remoteData = await _service.getPengajaranByDosen(idDosen);

      // Update data di Hive
      for (var json in remoteData) {
        final model = PengajaranModel.fromMongo(json);
        await _box.put(model.id, model);
      }
    } catch (e) {
      print("❌ Sync Pengajaran Error: $e");
    }
  }
}
