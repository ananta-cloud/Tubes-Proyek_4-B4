import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'matkul_model.g.dart';

@HiveType(typeId: 6)
class MatkulModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String kodeMk;

  @HiveField(2)
  final String namaMatkul;

  @HiveField(3)
  final String programStudi;

  @HiveField(4)
  final String idProdi;

  @HiveField(5)
  final int sks;

  @HiveField(6)
  final String idJurusan;

  MatkulModel({
    required this.id,
    required this.kodeMk,
    required this.namaMatkul,
    required this.programStudi,
    required this.idProdi,
    required this.sks,
    required this.idJurusan,
  });

  factory MatkulModel.fromMongo(
    Map<String, dynamic> map, {
    String namaProdi = '-',
  }) {
    String parseId(dynamic v) {
      if (v == null) return ObjectId().toHexString();
      if (v is ObjectId) return v.toHexString();
      return v.toString();
    }

    return MatkulModel(
      id: parseId(map['_id']),
      kodeMk: map['kode_mk']?.toString() ?? '-',
      namaMatkul: map['nama_mk']?.toString() ?? '-',
      programStudi: namaProdi,
      idProdi: parseId(map['id_prodi']),
      sks: (map['sks'] is int)
          ? map['sks']
          : int.tryParse(map['sks']?.toString() ?? '0') ?? 0,
      idJurusan: parseId(map['id_jurusan']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'kodeMk': kodeMk,
    'namaMatkul': namaMatkul,
    'programStudi': programStudi,
    'idProdi': idProdi,
    'sks': sks,
  };
}
