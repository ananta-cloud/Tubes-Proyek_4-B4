import 'package:kampus_ku_mobile/core/network/api_client.dart';

class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final res = await ApiClient.get("/schedules");
    return List<Map<String, dynamic>>.from(res['data']);
  }

  // POST Jadwal Baru
  Future<void> postSchedule(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/penjadwalan/schedules'),
      body: data,
      headers: {
        'Authorization': 'Bearer $token',
      }, // Sesuaikan dengan sistem Auth kamu
    );
    if (response.statusCode != 201) throw Exception('Gagal membuat jadwal');
  }

  // PUT Update Jadwal
  Future<void> putSchedule(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/penjadwalan/schedules/$id'),
      body: data,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Gagal update jadwal');
  }

  // PATCH Finalize
  Future<void> patchFinalize(String id) async {
    await http.patch(
      Uri.parse('$baseUrl/penjadwalan/schedules/$id/finalize'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // PATCH Approve Request
  Future<void> patchApproveRequest(String id, String? catatan) async {
    await http.patch(
      Uri.parse('$baseUrl/penjadwalan/requests/$id/approve'),
      body: {'catatan_admin': catatan},
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
