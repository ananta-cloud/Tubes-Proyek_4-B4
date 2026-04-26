import 'package:kampus_ku_mobile/core/network/api_client.dart';

class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final res = await ApiClient.get("/schedules");
    return List<Map<String, dynamic>>.from(res['data']);
  }
}
