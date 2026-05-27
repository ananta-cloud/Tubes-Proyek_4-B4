import 'package:sigma/core/network/mongo_database.dart';

class AnnouncementService {
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final announcements = await MongoDatabase.runSafe(
        () => MongoDatabase.announcementsCollection.find().toList(),
      );
      return announcements;
    } catch (e) {
      print("Error AnnouncementService (Mongo): $e");
      rethrow;
    }
  }
}
