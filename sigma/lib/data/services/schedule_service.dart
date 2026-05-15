import 'package:sigma/core/network/mongo_database.dart';

class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final data = await MongoDatabase.runSafe(
      () => MongoDatabase.schedulesCollection.find({
        "status": "PUBLISHED", //  FILTER PENTING
      }).toList(),
    );

      print("MONGO SCHEDULE: ${data.length}");
      return data;
    }
  }