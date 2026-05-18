import 'package:hive/hive.dart';

part 'pengajaran_model.g.dart'; // File ini dihasilkan oleh build_runner

@HiveType(typeId: 4) // Gunakan ID unik yang belum dipakai
class PengajaranModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String idDosen;

  @HiveField(2)
  final String idMk;

  @HiveField(3)
  final String namaMk;

  @HiveField(4)
  final String targetKelas; // Contoh: "2B-D3"

  PengajaranModel({
    required this.id,
    required this.idDosen,
    required this.idMk,
    required this.namaMk,
    required this.targetKelas,
  });

  factory PengajaranModel.fromMongo(Map<String, dynamic> json) {
    return PengajaranModel(
      id: json['_id'] is String ? json['_id'] : json['_id'].toHexString(),
      idDosen: json['id_dosen'].toString(),
      idMk: json['id_mk'].toString(),
      namaMk: json['nama_mk'] ?? '',
      targetKelas: json['target_kelas'] ?? '',
    );
  }
}
