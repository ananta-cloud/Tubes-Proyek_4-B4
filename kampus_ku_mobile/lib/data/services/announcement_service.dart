import '../../core/network/mongo_database.dart';
import '../models/announcement_model.dart';

class AnnouncementService {

  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final announcements = await MongoDatabase.announcementsCollection
          .find()
          .toList();
      return announcements
          .map((map) => AnnouncementModel.fromMongo(map))
          .toList();
    } catch (e) {
      print("Error AnnouncementService: $e");
      rethrow;
    }
  }
}