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

  ScheduleLocalModel({
    required this.id,
    required this.namaMk,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.dosen,
  });

  factory ScheduleLocalModel.fromJson(Map<String, dynamic> json) {
    return ScheduleLocalModel(
      id: json['id'] ?? json['_id'].toString(),
      namaMk: json['nama_mk'] ?? '-',
      hari: json['hari'] ?? '-',
      jamMulai: json['jam_mulai'] ?? '-',
      jamSelesai: json['jam_selesai'] ?? '-',
      ruangan: json['ruangan'] ?? '-',
      dosen: json['nama_dosen'] ?? '-',
    );
  }

  @override
  String toString() {
    return 'ScheduleLocalModel(namaMk: $namaMk, hari: $hari, jam: $jamMulai-$jamSelesai)';
  }
}
