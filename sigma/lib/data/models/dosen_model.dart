import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class DosenModel {
  final String id;
  final String userId; 
  final String kodeDosen;
  final String namaDosen;
  final String idJurusan;

  DosenModel({
    required this.id,
    required this.userId,
    required this.kodeDosen,
    required this.namaDosen,
    required this.idJurusan,
  });

  factory DosenModel.fromMongo(Map<String, dynamic> json) {
    String extractId(dynamic field) {
      if (field == null) return '';
      if (field is ObjectId) return field.toHexString();
      if (field is Map && field.containsKey('\$oid')) return field['\$oid'];
      return field.toString().replaceAll('ObjectId("', '').replaceAll('")', '').trim();
    }

    return DosenModel(
      id: extractId(json['_id']),
      userId: extractId(json['user_id']), 
      kodeDosen: json['kode_dosen']?.toString() ?? '',
      namaDosen: json['nama_dosen']?.toString() ?? '',
      idJurusan: extractId(json['id_jurusan']),
    );
  }
}