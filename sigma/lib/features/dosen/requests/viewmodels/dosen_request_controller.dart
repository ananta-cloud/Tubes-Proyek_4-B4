import 'package:flutter/material.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/dosen_request_service.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DosenRequestController extends ChangeNotifier {
  final DosenRequestService service;
  DosenRequestController(this.service) {
    monitorConnection();
  }

  final Box _pendingBox = Hive.box('pending_requests');
  final Box _cancelQueue = Hive.box('cancel_queue');

  bool _isSyncing = false;

  List<Map<String, dynamic>> mySchedules = [];
  List<ScheduleRequestModel> myRequests = [];
  List<String> ruanganTersedia = [];

  bool isLoadingSchedules = false;
  bool isLoadingRequests = false;
  bool isCheckingRuangan = false;
  bool isSubmitting = false;
  String? errorMsg;
  String? _lastIdDosen;
  bool isOffline = false;
  bool _justSynced = false;
  bool get justSynced => _justSynced;

  List<Map<String, dynamic>> get pendingRequests => _pendingBox.values
      .map((e) => Map<String, dynamic>.from(e))
      .toList()
      .reversed
      .toList();

  // Form
  Map<String, dynamic>? selectedJadwal;
  // String? selectedTipeRequest; // PINDAH_JAM | PINDAH_RUANGAN | KEDUANYA
  // String? selectedHariBaru;
  DateTime? selectedTanggalBaru;
  String? selectedJamMulaiBaru;
  String? selectedJamSelesaiBaru;
  String? selectedRuanganBaru;
  String? selectedTipeJadwalBaru; // TE | PR

  void monitorConnection() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = isOffline;
      isOffline = results.contains(ConnectivityResult.none);
      notifyListeners();

      if (wasOffline && !isOffline) {
        syncPendingRequests();
      }
    });
  }

  // ─────────────────────────────────────────────────
  // LOAD JADWAL MILIK DOSEN
  // ─────────────────────────────────────────────────

  Future<void> loadMySchedules(String kodeDosen) async {
    if (kodeDosen.isEmpty) {
      print('⚠️ loadMySchedules dibatalkan karena kodeDosen kosong');
      return;
    }

    isLoadingSchedules = true;
    notifyListeners();
    try {
      print('🔄 Memulai fetch jadwal untuk kode dosen: "$kodeDosen"');
      final rawSchedules = await service.getMySchedules(kodeDosen);

      print(
        '📦 Total data mentah dari MongoDB: ${rawSchedules.length} dokumen.',
      );

      final List<Map<String, dynamic>> tempSchedules = [];
      final targetKode = kodeDosen.trim().toUpperCase();

      for (var item in rawSchedules) {
        final kodes = item['kode_dosen'];
        bool isMengampu = false;

        if (kodes is List) {
          // Normalisasi setiap elemen di dalam array
          isMengampu = kodes.any(
            (k) => k.toString().trim().toUpperCase() == targetKode,
          );
        } else if (kodes != null) {
          isMengampu = kodes.toString().trim().toUpperCase() == targetKode;
        }

        if (isMengampu) {
          final sanitizedItem = item.map((key, value) {
            if (value != null && value.runtimeType.toString() == 'ObjectId') {
              return MapEntry(key, value.toHexString());
            }
            return MapEntry(key, value);
          });
          tempSchedules.add(sanitizedItem);
        }
      }
      mySchedules = _mergeJadwal(tempSchedules);
      print(
        'Selesai menyaring! Jadwal lolos filter untuk $targetKode: ${mySchedules.length} data.',
      );
    } catch (e) {
      errorMsg = e.toString();
      print('❌ Error saat load/filter MySchedules: $e');
    }
    isLoadingSchedules = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _mergeJadwal(List<Map<String, dynamic>> raw) {
    final merged = <String, Map<String, dynamic>>{};

    for (final item in raw) {
      // hari + kodeMk + kodeDosen + kelas + ruangan
      final key =
          '${item['hari']}|${item['kode_mk']}|${item['kode_dosen']}|'
          '${item['kelas']}|${item['ruangan']}';

      if (!merged.containsKey(key)) {
        merged[key] = Map<String, dynamic>.from(item);
      } else {
        // Ambil jam_selesai yang paling akhir
        final existing = merged[key]!;
        final existingSelesai = existing['jam_selesai']?.toString() ?? '';
        final newSelesai = item['jam_selesai']?.toString() ?? '';
        if (newSelesai.compareTo(existingSelesai) > 0) {
          existing['jam_selesai'] = newSelesai;
        }
        // Ambil jam_ke range
        final existingJamKe = existing['jam_ke'];
        final newJamKe = item['jam_ke'];
        if (existingJamKe != null && newJamKe != null) {
          final start = (existingJamKe is int)
              ? existingJamKe
              : int.tryParse(existingJamKe.toString()) ?? 0;
          final end = (newJamKe is int)
              ? newJamKe
              : int.tryParse(newJamKe.toString()) ?? 0;
          existing['jam_ke'] = '$start–$end';
        }
      }
    }

    return merged.values.toList();
  }

  // ─────────────────────────────────────────────────
  // CEK RUANGAN TERSEDIA
  // ─────────────────────────────────────────────────

  // Future<void> checkRuangan({
  //   required String hari,
  //   required String jamMulai,
  //   required String jamSelesai,
  //   String? excludeScheduleId,
  // }) async {
  //   isCheckingRuangan = true;
  //   ruanganTersedia = [];
  //   notifyListeners();

  //   try {
  //     ruanganTersedia = await service.getRuanganTersedia(
  //       hari: hari,
  //       jamMulai: jamMulai,
  //       jamSelesai: jamSelesai,
  //       excludeScheduleId: excludeScheduleId,
  //     );
  //   } catch (e) {
  //     errorMsg = e.toString();
  //   }

  //   isCheckingRuangan = false;
  //   notifyListeners();
  // }
  Future<void> checkRuangan({String? excludeScheduleId}) async {
    if (selectedTanggalBaru == null) return;

    final hari = _hariDari(selectedTanggalBaru!);
    final jamMulai =
        selectedJamMulaiBaru ?? selectedJadwal?['jam_mulai']?.toString() ?? '';
    final jamSelesai =
        selectedJamSelesaiBaru ??
        selectedJadwal?['jam_selesai']?.toString() ??
        '';

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
    if (selectedJadwal == null || selectedTanggalBaru == null) return false;

    // final hariLama = selectedJadwal!['hari']?.toString() ?? '';
    final jamMulaiLama = selectedJadwal!['jam_mulai']?.toString() ?? '';
    final jamSelesaiLama = selectedJadwal!['jam_selesai']?.toString() ?? '';

    final detailPerubahan = <String, dynamic>{
      'tanggal_baru': selectedTanggalBaru!.toIso8601String(),
      'hari_baru': _hariDari(selectedTanggalBaru!),
      'jam_mulai_baru': selectedJamMulaiBaru ?? jamMulaiLama,
      'jam_selesai_baru': selectedJamSelesaiBaru ?? jamSelesaiLama,
      'ruangan_baru': selectedRuanganBaru ?? '',
      if (selectedTipeJadwalBaru != null)
        'tipe_jadwal_baru': selectedTipeJadwalBaru,
    };

    var connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      final offlineId = DateTime.now().millisecondsSinceEpoch.toString();
      await _pendingBox.put(offlineId, {
        'id': offlineId,
        'id_schedule': selectedJadwal!['_id'].toString(),
        'id_dosen': idDosen,
        'nama_dosen': namaDosen,
        'tipe_request': autoTipeRequest ?? 'KEDUANYA',
        'alasan': alasan,
        'nama_matkul':
            selectedJadwal!['nama_matkul'] ?? selectedJadwal!['nama_mk'] ?? '',
        'status': 'PENDING',
        'offline_id': offlineId,
        'detail_perubahan': {
          'tanggal_baru': selectedTanggalBaru!.toIso8601String(),
          'hari_baru': _hariDari(selectedTanggalBaru!),
          'jam_mulai_baru': selectedJamMulaiBaru ?? jamMulaiLama,
          'jam_selesai_baru': selectedJamSelesaiBaru ?? jamSelesaiLama,
          'ruangan_baru': selectedRuanganBaru ?? '',
        },
      });
      resetForm();
      return true;
    }

    isSubmitting = true;
    notifyListeners();

    final ok = await service.submitRequest(
      idSchedule: selectedJadwal!['_id'].toString(),
      idDosen: idDosen,
      namaDosen: namaDosen,
      tipeRequest: autoTipeRequest ?? 'KEDUANYA',
      detailPerubahan: detailPerubahan,
      alasan: alasan,
      namaMatkul:
          selectedJadwal!['nama_matkul'] ?? selectedJadwal!['nama_mk'] ?? '',
      offlineId: DateTime.now().millisecondsSinceEpoch.toString(),
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
    _lastIdDosen = idDosen;
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

  List<String> get cancelQueueIds =>
      _cancelQueue.values.map((e) => e.toString()).toList();
  Future<bool> cancelRequest(String requestId, String idDosen) async {
    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity.contains(ConnectivityResult.none)) {
      await _cancelQueue.put(requestId, requestId);
      notifyListeners();
      return true;
    }

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

  void selectTanggal(DateTime tanggal) {
    selectedTanggalBaru = tanggal;
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

  String _normalizeJam(String jam) => jam.replaceAll('.', ':');

  String? get autoTipeRequest {
    if (selectedJadwal == null || selectedTanggalBaru == null) return null;

    final hariLama = selectedJadwal!['hari']?.toString() ?? '';
    final jamMulaiLama = _normalizeJam(
      selectedJadwal!['jam_mulai']?.toString() ?? '',
    );
    final jamSelesaiLama = _normalizeJam(
      selectedJadwal!['jam_selesai']?.toString() ?? '',
    );
    final ruanganLama = selectedJadwal!['ruangan']?.toString() ?? '';

    final hariTanggalBaru = _hariDari(selectedTanggalBaru!);
    final samaHari = hariTanggalBaru == hariLama;
    final samaJamMulai =
        _normalizeJam(selectedJamMulaiBaru ?? jamMulaiLama) == jamMulaiLama;
    final samaJamSelesai =
        _normalizeJam(selectedJamSelesaiBaru ?? jamSelesaiLama) ==
        jamSelesaiLama;
    final samaRuangan = (selectedRuanganBaru ?? ruanganLama) == ruanganLama;

    if (samaHari && samaJamMulai && samaJamSelesai) return 'PINDAH_RUANGAN';
    if (samaRuangan) return 'PINDAH_JAM';
    return 'KEDUANYA';
  }

  String _hariDari(DateTime dt) {
    const hari = [
      'SENIN',
      'SELASA',
      'RABU',
      'KAMIS',
      'JUMAT',
      'SABTU',
      'MINGGU',
    ];
    return hari[dt.weekday - 1];
  }

  void resetForm() {
    selectedJadwal = null;
    selectedTanggalBaru = null;
    selectedJamMulaiBaru = null;
    selectedJamSelesaiBaru = null;
    selectedRuanganBaru = null;
    selectedTipeJadwalBaru = null;
    ruanganTersedia = [];
    notifyListeners();
  }

  Future<void> syncPendingRequests() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Sync pending requests
      if (_pendingBox.isNotEmpty) {
        final keys = _pendingBox.keys.toList();
        for (var key in keys) {
          final data = Map<String, dynamic>.from(_pendingBox.get(key));
          final detail = Map<String, dynamic>.from(
            data['detail_perubahan'] ?? {},
          );
          final ok = await service.submitRequest(
            idSchedule: data['id_schedule'],
            idDosen: data['id_dosen'],
            namaDosen: data['nama_dosen'],
            tipeRequest: data['tipe_request'],
            detailPerubahan: detail,
            alasan: data['alasan'],
            namaMatkul: data['nama_matkul'] ?? '',
            offlineId: data['offline_id'],
          );
          if (ok) await _pendingBox.delete(key);
        }
      }

      // Sync cancel queue
      if (_cancelQueue.isNotEmpty) {
        final keys = _cancelQueue.keys.toList();
        for (var key in keys) {
          final requestId = _cancelQueue.get(key).toString();
          final ok = await service.cancelRequest(requestId);
          if (ok) await _cancelQueue.delete(key);
        }
      }

      if (_pendingBox.isEmpty && _cancelQueue.isEmpty && _lastIdDosen != null) {
        await loadMyRequests(_lastIdDosen!);
        _justSynced = true;
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void clearSyncFlag() {
    _justSynced = false;
    notifyListeners();
  }
}
