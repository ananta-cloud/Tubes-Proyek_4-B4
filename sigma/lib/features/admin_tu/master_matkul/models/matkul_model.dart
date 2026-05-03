import 'package:mongo_dart/mongo_dart.dart';

class MatkulModel {
  final String id;
  final String kodeMk;
  final String namaMatkul;
  final String programStudi; // nama hasil lookup
  final String idProdi; // ObjectId string, untuk keperluan update
  final int sks;

  MatkulModel({
    required this.id,
    required this.kodeMk,
    required this.namaMatkul,
    required this.programStudi,
    required this.idProdi,
    required this.sks,
  });

  factory MatkulModel.fromMongo(
    Map<String, dynamic> map, {
    String namaProdi = '-', // di-inject dari luar setelah lookup
  }) {
    String parseId(dynamic v) {
      if (v == null) return ObjectId().toHexString();
      if (v is ObjectId) return v.toHexString();
      return v.toString();
    }

    return MatkulModel(
      id: parseId(map['_id']),
      kodeMk: map['kode_mk']?.toString() ?? '-',
      namaMatkul: map['nama_mk']?.toString() ?? '-', // ← fix: nama_mk
      programStudi: namaProdi, // ← dari lookup
      idProdi: parseId(map['id_prodi']),
      sks: (map['sks'] is int)
          ? map['sks']
          : int.tryParse(map['sks']?.toString() ?? '0') ?? 0,
    );
  }
}
