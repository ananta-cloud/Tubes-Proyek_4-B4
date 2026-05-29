import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

part 'dosen_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DosenModel
//
//  Sesuai struktur collection `dosen` di MongoDB:
//  {
//    "_id"        : ObjectId("..."),
//    "user_id"    : ObjectId("..."),   ← referensi ke collection users
//    "kode_dosen" : "Kode dosen",
//    "nama_dosen" : "Nama dosen",
//    "id_jurusan" : ObjectId("..."),
//    "created_at" : ISODate("..."),
//    "updated_at" : ISODate("...")
//  }
// ─────────────────────────────────────────────────────────────────────────────
@HiveType(typeId: 7)
class DosenModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String kodeDosen;

  @HiveField(3)
  final String namaDosen;

  @HiveField(4)
  final String idJurusan;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final String email;

  DosenModel({
    required this.id,
    this.userId = '',
    required this.kodeDosen,
    required this.namaDosen,
    required this.idJurusan,
    required this.createdAt,
    required this.updatedAt,
    this.email = '', 
  });

  factory DosenModel.fromMongo(Map<String, dynamic> map) {
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

    return DosenModel(
      id: parseId(map['_id']),
      userId: parseId(map['user_id']),
      kodeDosen: map['kode_dosen']?.toString() ?? '',
      namaDosen: map['nama_dosen']?.toString() ?? '-',
      idJurusan: parseId(map['id_jurusan']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      // 🔥 Parsing email dari database MongoDB
      email: map['email']?.toString() ?? '', 
    );
  }

  Map<String, dynamic> toMongoMap() {
    final map = <String, dynamic>{
      'kode_dosen': kodeDosen,
      'nama_dosen': namaDosen,
      'email': email, 
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
  String toString() => 'DosenModel(kode: $kodeDosen, nama: $namaDosen, email: $email)';
}