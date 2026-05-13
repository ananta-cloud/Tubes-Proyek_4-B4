import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'schedule_model.g.dart';

@HiveType(typeId: 5)
class ScheduleModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String namaMatkul;

  @HiveField(2)
  final String namaDosen;

  @HiveField(3)
  final String hari;

  @HiveField(4)
  final String jamMulai;

  @HiveField(5)
  final String jamSelesai;

  @HiveField(6)
  final String ruangan;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final DateTime createdAt;

  // ── Field baru untuk import Excel ────────────────────────────────────────
  @HiveField(9)
  final String kelas; // contoh: "1A-D3", "2B-D4"

  @HiveField(10)
  final String kodeMk; // contoh: "25IF1107"

  @HiveField(11)
  final String kodeDosen; // contoh: "KO009N" (bisa multiple: "KO073N;KO063N")

  @HiveField(12)
  final String tePr; // "TE" atau "PR"

  @HiveField(13)
  final String semester; // "GENAP" atau "GANJIL"

  @HiveField(14)
  final String tahunAkademik; // contoh: "2025/2026"

  @HiveField(15)
  final int jamKe; // jam ke berapa (1-12)

  ScheduleModel({
    required this.id,
    required this.namaMatkul,
    required this.namaDosen,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.status,
    required this.createdAt,
    this.kelas = '',
    this.kodeMk = '',
    this.kodeDosen = '',
    this.tePr = '',
    this.semester = '',
    this.tahunAkademik = '',
    this.jamKe = 0,
  });

  factory ScheduleModel.fromMongo(Map<String, dynamic> map) {
    String parseId(dynamic v) {
      if (v == null) return ObjectId().toHexString();
      if (v is ObjectId) return v.toHexString();
      return v.toString();
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    // kode_dosen bisa Array atau String di MongoDB
    String parseKodeDosen(dynamic v) {
      if (v == null) return '';
      if (v is List) return v.map((e) => e.toString()).join(';');
      return v.toString();
    }

    return ScheduleModel(
      id: parseId(map['_id']),
      namaMatkul:
          map['nama_matkul']?.toString() ??
          map['mata_kuliah']?.toString() ??
          map['nama_mk']?.toString() ??
          '-',
      namaDosen: map['nama_dosen']?.toString() ?? '-',
      hari: map['hari']?.toString() ?? '-',
      jamMulai: map['jam_mulai']?.toString() ?? '00:00',
      jamSelesai: map['jam_selesai']?.toString() ?? '00:00',
      ruangan: map['ruangan']?.toString() ?? '-',
      status: map['status']?.toString() ?? 'DRAFT',
      createdAt: parseDate(map['created_at']),
      kelas: map['kelas']?.toString() ?? '',
      kodeMk: map['kode_mk']?.toString() ?? '',
      kodeDosen: parseKodeDosen(map['kode_dosen']),
      tePr: map['te_pr']?.toString() ?? '',
      semester: map['semester']?.toString() ?? '',
      tahunAkademik: map['tahun_akademik']?.toString() ?? '',
      jamKe: (map['jam_ke_mulai'] is int)
          ? map['jam_ke_mulai']
          : int.tryParse(map['jam_ke_mulai']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMongoMap() => {
    'nama_matkul': namaMatkul,
    'nama_dosen': namaDosen,
    'hari': hari,
    'jam_mulai': jamMulai,
    'jam_selesai': jamSelesai,
    'ruangan': ruangan,
    'status': status,
    'created_at': createdAt,
    'kelas': kelas,
    'kode_mk': kodeMk,
    'kode_dosen': kodeDosen.isNotEmpty ? kodeDosen.split(';') : [],
    'te_pr': tePr,
    'semester': semester,
    'tahun_akademik': tahunAkademik,
    'jam_ke_mulai': jamKe,
  };
}
