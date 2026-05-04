import 'package:flutter/material.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/dosen_request_service.dart';

class DosenRequestController extends ChangeNotifier {
  final DosenRequestService service;
  DosenRequestController(this.service);

  List<Map<String, dynamic>> mySchedules = [];
  List<ScheduleRequestModel> myRequests = [];
  List<String> ruanganTersedia = [];

  bool isLoadingSchedules = false;
  bool isLoadingRequests = false;
  bool isCheckingRuangan = false;
  bool isSubmitting = false;
  String? errorMsg;

  // Form
  Map<String, dynamic>? selectedJadwal;
  String? selectedTipeRequest; // PINDAH_JAM | PINDAH_RUANGAN | KEDUANYA
  String? selectedHariBaru;
  String? selectedJamMulaiBaru;
  String? selectedJamSelesaiBaru;
  String? selectedRuanganBaru;
  String? selectedTipeJadwalBaru; // TE | PR

  // ─────────────────────────────────────────────────
  // LOAD JADWAL MILIK DOSEN
  // ─────────────────────────────────────────────────

  Future<void> loadMySchedules(String kodeDosen) async {
    isLoadingSchedules = true;
    notifyListeners();

    try {
      mySchedules = await service.getMySchedules(kodeDosen);
    } catch (e) {
      errorMsg = e.toString();
    }

    isLoadingSchedules = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────
  // CEK RUANGAN TERSEDIA
  // ─────────────────────────────────────────────────

  Future<void> checkRuangan({
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    String? excludeScheduleId,
  }) async {
    isCheckingRuangan = true;
    ruanganTersedia = [];
    notifyListeners();

    try {
      ruanganTersedia = await service.getRuanganTersedia(
        hari: hari,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        excludeScheduleId: excludeScheduleId,
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    isCheckingRuangan = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────
  // SUBMIT REQUEST
  // ─────────────────────────────────────────────────

  Future<bool> submitRequest({
    required String idDosen,
    required String namaDosen,
    required String alasan,
  }) async {
    if (selectedJadwal == null || selectedTipeRequest == null) return false;

    isSubmitting = true;
    notifyListeners();

    final detailPerubahan = <String, dynamic>{};
    if (selectedHariBaru != null)
      detailPerubahan['hari_baru'] = selectedHariBaru;
    if (selectedJamMulaiBaru != null)
      detailPerubahan['jam_mulai_baru'] = selectedJamMulaiBaru;
    if (selectedJamSelesaiBaru != null)
      detailPerubahan['jam_selesai_baru'] = selectedJamSelesaiBaru;
    if (selectedRuanganBaru != null)
      detailPerubahan['ruangan_baru'] = selectedRuanganBaru;
    if (selectedTipeJadwalBaru != null)
      detailPerubahan['tipe_jadwal_baru'] = selectedTipeJadwalBaru;

    final ok = await service.submitRequest(
      idSchedule: selectedJadwal!['_id'].toString(),
      idDosen: idDosen,
      namaDosen: namaDosen,
      tipeRequest: selectedTipeRequest!,
      detailPerubahan: detailPerubahan,
      alasan: alasan,
    );

    if (ok) resetForm();

    isSubmitting = false;
    notifyListeners();
    return ok;
  }

  // ─────────────────────────────────────────────────
  // RIWAYAT REQUEST
  // ─────────────────────────────────────────────────

  Future<void> loadMyRequests(String idDosen) async {
    isLoadingRequests = true;
    notifyListeners();

    try {
      myRequests = await service.getMyRequests(idDosen);
    } catch (e) {
      errorMsg = e.toString();
    }

    isLoadingRequests = false;
    notifyListeners();
  }

  Future<bool> cancelRequest(String requestId, String idDosen) async {
    final ok = await service.cancelRequest(requestId);
    if (ok) await loadMyRequests(idDosen);
    return ok;
  }

  // ─────────────────────────────────────────────────
  // FORM HELPERS
  // ─────────────────────────────────────────────────

  void selectJadwal(Map<String, dynamic> jadwal) {
    selectedJadwal = jadwal;
    // Reset pilihan lain saat jadwal berubah
    selectedRuanganBaru = null;
    ruanganTersedia = [];
    notifyListeners();
  }

  void selectTipeRequest(String tipe) {
    selectedTipeRequest = tipe;
    notifyListeners();
  }

  void selectHariBaru(String hari) {
    selectedHariBaru = hari;
    // Reset ruangan saat hari berubah
    selectedRuanganBaru = null;
    ruanganTersedia = [];
    notifyListeners();
  }

  void selectJam(String mulai, String selesai) {
    selectedJamMulaiBaru = mulai;
    selectedJamSelesaiBaru = selesai;
    // Reset ruangan saat jam berubah
    selectedRuanganBaru = null;
    ruanganTersedia = [];
    notifyListeners();
  }

  void selectRuangan(String ruangan) {
    selectedRuanganBaru = ruangan;
    notifyListeners();
  }

  void selectTipeJadwal(String tipe) {
    selectedTipeJadwalBaru = tipe;
    notifyListeners();
  }

  void resetForm() {
    selectedJadwal = null;
    selectedTipeRequest = null;
    selectedHariBaru = null;
    selectedJamMulaiBaru = null;
    selectedJamSelesaiBaru = null;
    selectedRuanganBaru = null;
    selectedTipeJadwalBaru = null;
    ruanganTersedia = [];
    notifyListeners();
  }
}
