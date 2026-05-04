import 'package:hive/hive.dart';

part 'schedule_local_model.g.dart';

@HiveType(typeId: 1)
class ScheduleLocalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String namaMk;

  @HiveField(2)
  String hari;

  @HiveField(3)
  String jamMulai;

  @HiveField(4)
  String jamSelesai;

  @HiveField(5)
  String ruangan;

  @HiveField(6)
  String dosen;

  @HiveField(7)
  String status; // DRAFT | FINAL | PUBLISHED

  @HiveField(8)
  String tipe; // KULIAH | UTS | UAS

  @HiveField(9)
  String kodeMk;

  @HiveField(10)
  String idMk;

  @HiveField(11)
  String idProdi;

  @HiveField(12)
  String idJurusan;

  @HiveField(13)
  String idPeriode;

  @HiveField(14)
  String? updatedAt;

  ScheduleLocalModel({
    required this.id,
    required this.namaMk,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.dosen,
    this.status = 'DRAFT',
    this.tipe = 'KULIAH',
    this.kodeMk = '',
    this.idMk = '',
    this.idProdi = '',
    this.idJurusan = '',
    this.idPeriode = '',
    this.updatedAt,
  });

  factory ScheduleLocalModel.fromJson(Map<String, dynamic> json) {
    return ScheduleLocalModel(
      // PERBAIKAN 1: Hapus duplikasi parameter 'id'
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      namaMk: json['nama_mk'] ?? '-',
      hari: json['hari'] ?? '-',
      jamMulai: json['jam_mulai'] ?? '-',
      jamSelesai: json['jam_selesai'] ?? '-',
      ruangan: json['ruangan'] ?? '-',
      dosen: json['nama_dosen'] ?? '-',
      status: json['status'] ?? 'DRAFT',
      tipe: json['tipe'] ?? 'KULIAH',
      kodeMk: json['kode_mk'] ?? '',
      idMk: json['id_mk']?.toString() ?? '',
      idProdi: json['id_prodi']?.toString() ?? '',
      idJurusan: json['id_jurusan']?.toString() ?? '',
      idPeriode: json['id_periode']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'nama_mk': namaMk,
    'hari': hari,
    'jam_mulai': jamMulai,
    'jam_selesai': jamSelesai,
    'ruangan': ruangan,
    'nama_dosen': dosen,
    'status': status,
    'tipe': tipe,
    'kode_mk': kodeMk,
    'id_mk': idMk,
    'id_prodi': idProdi,
    'id_jurusan': idJurusan,
    'id_periode': idPeriode,
    'updated_at': updatedAt,
  };

  // PERBAIKAN 2: Hapus toString() yang rusak dan duplikat
  @override
  String toString() {
    return 'ScheduleLocalModel(namaMk: $namaMk, hari: $hari, jam: $jamMulai-$jamSelesai, status: $status)';
  }
}
