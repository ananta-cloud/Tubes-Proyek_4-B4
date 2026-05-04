import 'package:mongo_dart/mongo_dart.dart';

class ScheduleModel {
  final String id;
  final String namaMatkul;
  final String namaDosen;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String ruangan;
  final String status; // 'DRAFT' | 'PUBLISHED'
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
}
