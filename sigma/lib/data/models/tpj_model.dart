import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

part 'tpj_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TimPenjadwalanModel
//
//  Sesuai struktur collection `tim_penjadwalan` di MongoDB:
//  {
//    "_id"        : ObjectId("..."),
//    "user_id"    : ObjectId("..."),   ← referensi ke collection users
//    "nama"       : "Tim Penjadwalan",
//    "id_jurusan" : ObjectId("..."),
//    "created_at" : ISODate("..."),
//    "updated_at" : ISODate("...")
//  }
// ─────────────────────────────────────────────────────────────────────────────
@HiveType(typeId: 8)
class TimPenjadwalanModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String nama;

  @HiveField(3)
  final String idJurusan;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  TimPenjadwalanModel({
    required this.id,
    this.userId = '',
    required this.nama,
    required this.idJurusan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimPenjadwalanModel.fromMongo(Map<String, dynamic> map) {
    String parseId(dynamic v) {
      if (v == null) return '';
      if (v is ObjectId) return v.oid;
      return v.toString();
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return TimPenjadwalanModel(
      id: parseId(map['_id']),
      userId: parseId(map['user_id']),
      nama: map['nama']?.toString() ?? '-',
      idJurusan: parseId(map['id_jurusan']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMongoMap() {
    final map = <String, dynamic>{
      'nama': nama,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };

    if (userId.isNotEmpty) {
      map['user_id'] = ObjectId.fromHexString(userId);
    }
    if (idJurusan.isNotEmpty) {
      map['id_jurusan'] = ObjectId.fromHexString(idJurusan);
    }

    return map;
  }

  @override
  String toString() =>
      'TimPenjadwalanModel(nama: $nama, idJurusan: $idJurusan)';
}
