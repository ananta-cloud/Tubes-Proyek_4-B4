import 'package:kampus_ku_mobile/core/network/api_client.dart';

class ScheduleService {
  Future<Map<String, dynamic>> getSchedules() async {
    return await ApiClient.get("/schedules");
  }
}
