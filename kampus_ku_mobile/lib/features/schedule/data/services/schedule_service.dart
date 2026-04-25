import 'package:kampus_ku_mobile/core/network/api_client.dart';

class ScheduleService {
  Future<List<dynamic>> getSchedules() async {
    final res = await ApiClient.get("/schedules");

    return res['data']; //  ambil array
  }
}
