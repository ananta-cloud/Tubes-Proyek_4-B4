import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class MahasiswaModel {
  final String id;
  final String userId;
  final String nim;
  final String nama;
  final String idProdi;
  final String idKelas;

  MahasiswaModel({
    required this.id,
    required this.userId,
    required this.nim,
    required this.nama,
    required this.idProdi,
    required this.idKelas,
  });

  factory MahasiswaModel.fromMongo(Map<String, dynamic> json) {
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

    return MahasiswaModel(
      id: extractId(json['_id']),
      userId: extractId(json['user_id']),
      nim: json['nim']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      idProdi: extractId(json['id_prodi']),
      idKelas: extractId(json['id_kelas']),
    );
  }
}
