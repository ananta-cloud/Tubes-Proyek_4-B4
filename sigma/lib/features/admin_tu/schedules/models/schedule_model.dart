import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'schedule_model.g.dart';

@HiveType(typeId: 5)
class ScheduleModel extends HiveObject {
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

    return ScheduleModel(
      id: parseId(map['_id']),
      namaMatkul:
          map['nama_matkul']?.toString() ??
          map['mata_kuliah']?.toString() ??
          '-',
      namaDosen: map['nama_dosen']?.toString() ?? '-',
      hari: map['hari']?.toString() ?? '-',
      jamMulai: map['jam_mulai']?.toString() ?? '00:00',
      jamSelesai: map['jam_selesai']?.toString() ?? '00:00',
      ruangan: map['ruangan']?.toString() ?? '-',
      status: map['status']?.toString() ?? 'DRAFT',
      createdAt: parseDate(map['created_at']),
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
  };
}
