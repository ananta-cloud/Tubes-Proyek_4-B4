class DetailPerubahan {
  final String? hariBaru;
  final DateTime? tanggalBaru;
  final String? jamMulaiBaru;
  final String? jamSelesaiBaru;
  final String? ruanganBaru;

  DetailPerubahan({
    this.hariBaru,
    this.tanggalBaru,
    this.jamMulaiBaru,
    this.jamSelesaiBaru,
    this.ruanganBaru,
  });

  factory DetailPerubahan.fromJson(Map<String, dynamic> json) {
    return DetailPerubahan(
      hariBaru: json['hari_baru'],
      tanggalBaru: json['tanggal_baru'] != null
          ? DateTime.tryParse(json['tanggal_baru'].toString())
          : null,
      jamMulaiBaru: json['jam_mulai_baru'],
      jamSelesaiBaru: json['jam_selesai_baru'],
      ruanganBaru: json['ruangan_baru'],
    );
  }
}

class ScheduleRequestModel {
  final String id;
  final String idSchedule;
  final String idDosen;
  final String namaDosen;
  final String tipeRequest; // PINDAH_JAM | PINDAH_RUANGAN | KEDUANYA
  final DetailPerubahan detailPerubahan;
  final String alasan;
  final String status; // PENDING | APPROVED | REJECTED
  final String? catatanAdmin;
  final String? idProcessor;
  final bool? isLate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Data jadwal yang di-embed saat fetch (join di controller)
  final String? namaMk;
  final String? kodeMk;
  final String? hariJadwal;
  final String? jamMulaiJadwal;
  final String? jamSelesaiJadwal;
  final String? ruanganJadwal;
  final String? kelas;

  ScheduleRequestModel({
    required this.id,
    required this.idSchedule,
    required this.idDosen,
    required this.namaDosen,
    required this.tipeRequest,
    required this.detailPerubahan,
    required this.alasan,
    required this.status,
    this.catatanAdmin,
    this.idProcessor,
    this.isLate,
    this.createdAt,
    this.updatedAt,
    this.namaMk,
    this.kodeMk,
    this.hariJadwal,
    this.jamMulaiJadwal,
    this.jamSelesaiJadwal,
    this.ruanganJadwal,
    this.kelas,
  });

  factory ScheduleRequestModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? jadwal,
  }) {
    return ScheduleRequestModel(
      id: json['_id']?.toString() ?? '',
      idSchedule: json['id_schedule']?.toString() ?? '',
      idDosen: json['id_dosen']?.toString() ?? '',
      namaDosen: json['nama_dosen'] ?? '',
      tipeRequest: json['tipe_request'] ?? '',
      detailPerubahan: DetailPerubahan.fromJson(
        Map<String, dynamic>.from(json['detail_perubahan'] ?? {}),
      ),
      alasan: json['alasan'] ?? '',
      status: json['status'] ?? 'PENDING',
      catatanAdmin: json['catatan_admin'],
      idProcessor: json['id_processor']?.toString(),
      isLate: json['is_late'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      // embed dari jadwal
      namaMk: jadwal?['nama_mk'],
      kodeMk: jadwal?['kode_mk'],
      hariJadwal: jadwal?['hari'],
      jamMulaiJadwal: jadwal?['jam_mulai'],
      jamSelesaiJadwal: jadwal?['jam_selesai'],
      ruanganJadwal: jadwal?['ruangan'],
      kelas: jadwal?['kelas'],
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  String get tipeLabel {
    switch (tipeRequest) {
      case 'PINDAH_JAM':
        return 'Pindah Jam';
      case 'PINDAH_RUANGAN':
        return 'Pindah Ruangan';
      case 'KEDUANYA':
        return 'Jam & Ruangan';
      default:
        return tipeRequest;
    }
  }

  String get tanggalFormatted {
    if (createdAt == null) return '-';
    return '${createdAt!.day.toString().padLeft(2, '0')} '
        '${_bulan(createdAt!.month)} ${createdAt!.year}, '
        '${createdAt!.hour.toString().padLeft(2, '0')}:'
        '${createdAt!.minute.toString().padLeft(2, '0')}';
  }

  String _bulan(int m) => [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ags',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ][m];
}
