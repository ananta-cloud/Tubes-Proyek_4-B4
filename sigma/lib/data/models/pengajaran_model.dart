import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'pengajaran_model.g.dart';

@HiveType(typeId: 9)
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
  final String kodeMk;

  @HiveField(5)
  final List<String> targetKelas;

  PengajaranModel({
    required this.id,
    required this.idDosen,
    required this.idMk,
    required this.namaMk,
    required this.kodeMk,
    required this.targetKelas,
  });

  factory PengajaranModel.fromMongo(Map<String, dynamic> json) {
    String extractId(dynamic field) {
      if (field == null) return '';
      if (field is ObjectId) return field.toHexString();
      if (field is Map && field.containsKey('\$oid')) return field['\$oid'];
      return field
          .toString()
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '')
          .trim();
    }

    List<String> parsedKelas = [];
    var targetData = json['target_kelas'];

    try {
      if (targetData is List) {
        // Jika dari Atlas sudah berupa Array: ["2A-D3", "2B-D3"]
        parsedKelas = targetData.map((e) => e.toString()).toList();
      } else if (targetData != null && targetData.toString().isNotEmpty) {
        // Jika di Atlas lupa diubah dan masih String biasa: "2B-D3"
        parsedKelas = [targetData.toString()];
      }
    } catch (e) {
      print("⚠️ Gagal parsing kelas: $e");
    }

    return PengajaranModel(
      id: extractId(json['_id']),
      idDosen: extractId(json['id_dosen']),
      idMk: extractId(json['id_mk']),
      namaMk: json['nama_mk']?.toString() ?? '',
      kodeMk: json['kode_mk']?.toString() ?? '',
      targetKelas: parsedKelas,
    );
  }
}
