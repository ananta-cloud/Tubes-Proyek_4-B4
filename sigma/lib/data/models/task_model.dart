import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'task_model.g.dart';

@HiveType(typeId: 10)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String idUser;

  @HiveField(2)
  String namaTugas;

  @HiveField(3)
  String? deskripsi;

  @HiveField(4)
  String? idMk;

  @HiveField(5)
  String? namaMkSnapshot;

  @HiveField(6)
  DateTime deadline;

  @HiveField(7)
  String status;

  @HiveField(8)
  bool isSynced;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  List<Map<String, String>>? lampiran;

  TaskModel({
    required this.id,
    required this.idUser,
    required this.namaTugas,
    this.deskripsi,
    this.idMk,
    this.namaMkSnapshot,
    required this.deadline,
    this.status = 'BELUM',
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.lampiran,
  });

  // Jika idMk kosong/null, otomatis dianggap sebagai Tugas Personal
  bool get isPersonal => idMk == null || idMk!.isEmpty;

  factory TaskModel.fromMongo(Map<String, dynamic> map) {
    return TaskModel(
      id: (map['_id'] as ObjectId).toHexString(),
      idUser: (map['id_user'] as ObjectId).toHexString(),
      namaTugas: map['nama_tugas'],
      deskripsi: map['deskripsi'],
      idMk: map['id_mk'],
      namaMkSnapshot: map['nama_mk_snapshot'],
      deadline: map['deadline'] as DateTime,
      status: map['status'] ?? 'BELUM',
      isSynced:
          map['is_synced'] ??
          map['is_synced'] ??
          true, // Default ke true karena ditarik dari Cloud
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime,
      // Pada TaskModel.fromMongo:
      lampiran: map['lampiran'] != null
          ? (map['lampiran'] as List)
                .map((e) => Map<String, String>.from(e as Map))
                .toList()
          : null,
    );
  }

  // Convert to JSON for MongoDB
  Map<String, dynamic> toJson() {
    return {
      '_id': ObjectId.fromHexString(id),
      'id_user': ObjectId.fromHexString(idUser),
      'nama_tugas': namaTugas,
      'deskripsi': deskripsi,
      'id_mk': idMk,
      'nama_mk_snapshot': namaMkSnapshot,
      'deadline': deadline,
      'status': status,
      'is_synced': isSynced,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'lampiran': lampiran,
    };
  }
}
