import 'package:sigma/core/network/mongo_database.dart';

class ScheduleService {
  // Tambahkan parameter opsional idJurusan di sini
  Future<List<Map<String, dynamic>>> getSchedules({String? idJurusan}) async {
    try {
      // Query filter: Jika idJurusan ada, masukkan ke filter. Jika tidak, ambil semua.
      var query = {};
      if (idJurusan != null && idJurusan.isNotEmpty) {
        query = {'id_jurusan': idJurusan};
      }

      final data = await MongoDatabase.schedulesCollection.find(query).toList();
      return data;
    } catch (e) {
      print("Error in ScheduleService: $e");
      return [];
    }
  }
}
