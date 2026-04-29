import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'task_model.g.dart';

@HiveType(typeId: 3)
class TaskModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String idUser;
  @HiveField(2) String namaTugas;
  @HiveField(3) String? deskripsi;
  @HiveField(4) String? idMk;
  @HiveField(5) String? namaMkSnapshot;
  @HiveField(6) DateTime deadline;
  @HiveField(7) String status;
  @HiveField(8) bool isSynced;
  @HiveField(9) DateTime createdAt;
  @HiveField(10) DateTime updatedAt;

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
  });

  // Format dari mongo_dart: _id adalah ObjectId, date adalah DateTime langsung
  factory TaskModel.fromMongo(Map<String, dynamic> map) {
    return TaskModel(
      id:             (map['_id'] as ObjectId).toHexString(),
      idUser:         (map['id_user'] as ObjectId).toHexString(),
      namaTugas:      map['nama_tugas'],
      deskripsi:      map['deskripsi'],
      idMk:           map['id_mk'],
      namaMkSnapshot: map['nama_mk_snapshot'],
      deadline:       map['deadline'] as DateTime,
      status:         map['status'] ?? 'BELUM',
      isSynced:       true,
      createdAt:      map['created_at'] as DateTime,
      updatedAt:      map['updated_at'] as DateTime,
    );
  }
}