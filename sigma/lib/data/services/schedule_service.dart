import 'package:sigma/core/network/mongo_database.dart';

class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules() async {
    return MongoDatabase.runSafe(() async {
      final data = await MongoDatabase.schedulesCollection.find({
        "status": "PUBLISHED",
      }).toList();

      print("MONGO SCHEDULE: ${data.length}");
      return data;
    });
  }
}
