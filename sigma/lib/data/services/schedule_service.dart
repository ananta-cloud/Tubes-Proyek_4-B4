import 'package:sigma/core/network/mongo_database.dart';

/// Service layer untuk operasi jadwal langsung ke MongoDB.
/// Dipakai oleh SchedulingController (Tim Penjadwalan).
class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules([String? kelasMahasiswa]) async {
    final data = await MongoDatabase.runSafe(
      () => MongoDatabase.schedulesCollection.find({
        "status": "PUBLISHED",
        "kelas": {r'$regex': kelasMahasiswa, r'$options': 'i'},
      }).toList(),
    );

      print("MONGO SCHEDULE: ${data.length}");
      return data;
    }
  }