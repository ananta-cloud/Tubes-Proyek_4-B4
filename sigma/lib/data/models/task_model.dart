import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'task_model.g.dart';

@HiveType(typeId: 3)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String idUser;

  @HiveField(2)
  String namaTugas;

  @HiveField(3)
  String? deskripsi;

  // BERUBAH DARI idMk MENJADI kodeMk
  @HiveField(4)
  String? kodeMk;

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

  @HiveField(12)
  List<String>? targetKelas;

  @HiveField(13)
  String? namaDosen;

  TaskModel({
    required this.id,
    required this.idUser,
    required this.namaTugas,
    this.deskripsi,
    this.kodeMk, // Berubah
    this.namaMkSnapshot,
    required this.deadline,
    this.status = 'BELUM',
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.lampiran,
    this.targetKelas,
    this.namaDosen,
  });

  bool get isPersonal => kodeMk == null || kodeMk!.isEmpty;

  factory TaskModel.fromMongo(Map<String, dynamic> map) {
    return TaskModel(
      id: (map['_id'] as ObjectId).toHexString(),
      idUser: (map['id_user'] as ObjectId).toHexString(),
      namaTugas: map['nama_tugas'] ?? '',
      deskripsi: map['deskripsi'],
      kodeMk: map['kode_mk']?.toString(), // BERUBAH: Ambil dari kode_mk
      namaMkSnapshot: map['nama_mk_snapshot'],
      deadline: map['deadline'] as DateTime,
      status: map['status'] ?? 'BELUM',
      isSynced: true,
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime,
      lampiran: map['lampiran'] != null
          ? (map['lampiran'] as List)
                .map((e) => Map<String, String>.from(e as Map))
                .toList()
          : null,
      targetKelas: map['target_kelas'] is List
          ? (map['target_kelas'] as List).map((e) {
              if (e is ObjectId) return e.toHexString();
              return e.toString();
            }).toList()
          : [],
      namaDosen: map['nama_dosen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': ObjectId.parse(id),
      'id_user': ObjectId.parse(idUser),
      'nama_tugas': namaTugas,
      'deskripsi': deskripsi,
      'kode_mk': kodeMk, // BERUBAH
      'nama_mk_snapshot': namaMkSnapshot,
      'deadline': deadline,
      'status': status,
      'is_synced': isSynced,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'lampiran': lampiran,
      // Pastikan target_kelas menjadi Array
      'target_kelas':
          targetKelas?.map((idHex) {
            if (idHex.length == 24) return ObjectId.parse(idHex);
            return idHex;
          }).toList() ??
          [],
      'nama_dosen': namaDosen,
    };
  }
}
