import 'package:hive/hive.dart';

part 'schedule_request_model.g.dart';

@HiveType(typeId: 3)
class DetailPerubahan {
  @HiveField(0)
  final String? hariBaru;

  @HiveField(1)
  final DateTime? tanggalBaru;

  @HiveField(2)
  final String? jamMulaiBaru;

  @HiveField(3)
  final String? jamSelesaiBaru;

  @HiveField(4)
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

  Map<String, dynamic> toJson() => {
    'hari_baru': hariBaru,
    'tanggal_baru': tanggalBaru?.toIso8601String(),
    'jam_mulai_baru': jamMulaiBaru,
    'jam_selesai_baru': jamSelesaiBaru,
    'ruangan_baru': ruanganBaru,
  };
}

@HiveType(typeId: 4)
class ScheduleRequestModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String idSchedule;
  @HiveField(2)
  final String idDosen;
  @HiveField(3)
  final String namaDosen;
  @HiveField(4)
  final String tipeRequest; // PINDAH_JAM | PINDAH_RUANGAN | KEDUANYA
  @HiveField(5)
  final DetailPerubahan detailPerubahan;
  @HiveField(6)
  final String alasan;
  @HiveField(7)
  final String status; // PENDING | APPROVED | REJECTED
  @HiveField(8)
  final String? offlineId;
  @HiveField(9)
  final String? catatanAdmin;
  @HiveField(10)
  final String? idProcessor;
  @HiveField(11)
  final bool? isLate;
  @HiveField(12)
  final DateTime? createdAt;
  @HiveField(13)
  final DateTime? updatedAt;

  // Data jadwal yang di-embed saat fetch (join di controller)
  @HiveField(14)
  final String? namaMk;
  @HiveField(15)
  final String? kodeMk;
  @HiveField(16)
  final String? hariJadwal;
  @HiveField(17)
  final String? jamMulaiJadwal;
  @HiveField(18)
  final String? jamSelesaiJadwal;
  @HiveField(19)
  final String? ruanganJadwal;
  @HiveField(20)
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
    this.offlineId,
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
    final jadwalLama = json['jadwal_lama'] != null
        ? Map<String, dynamic>.from(json['jadwal_lama'])
        : jadwal;

    return ScheduleRequestModel(
      id: json['_id']?.toString() ?? '',
      idSchedule: json['id_schedule']?.toString() ?? '',
      idDosen: json['id_dosen']?.toString() ?? '',
      namaDosen: json['nama_dosen'] ?? '',
      tipeRequest: json['tipe_request'] ?? '',
      offlineId: json['offline_id'],
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
      namaMk:
          jadwalLama?['nama_matkul'] ??
          jadwalLama?['nama_mk'] ??
          json['nama_matkul'] ??
          json['nama_mk'] ??
          'Jadwal telah diubah',
      kodeMk: jadwalLama?['kode_mk'],
      hariJadwal: jadwalLama?['hari'],
      jamMulaiJadwal: jadwalLama?['jam_mulai'],
      jamSelesaiJadwal: jadwalLama?['jam_selesai'],
      ruanganJadwal: jadwalLama?['ruangan'],
      kelas: jadwalLama?['kelas'],
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
