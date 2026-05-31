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

  factory TaskModel.fromMongo(Map<String, dynamic> json) {
    // 1. Ekstraksi ID yang aman
    String extractSafeId(dynamic idValue) {
      if (idValue == null) return '';
      if (idValue is ObjectId) return idValue.toHexString();
      String raw = idValue.toString();
      final match = RegExp(r'[a-fA-F0-9]{24}').firstMatch(raw);
      return match?.group(0) ?? raw;
    }

    // 2. Ekstraksi dan proteksi lampiran
    List<Map<String, String>> parsedLampiran = [];
    if (json['lampiran'] != null && json['lampiran'] is List) {
      for (var lamp in json['lampiran']) {
        if (lamp is Map) {
          parsedLampiran.add({
            // Gunakan key 'name' atau 'title', fallback ke string kosong jika null
            'title': lamp['name']?.toString() ?? lamp['title']?.toString() ?? '',
            'type': lamp['type']?.toString() ?? 'file',
            'data': lamp['data'] != null ? lamp['data'].toString() : '',
            'size': lamp['size'] != null ? lamp['size'].toString() : '',
          });
        }
      }
    }

    // 3. Ekstraksi Target Kelas
    List<String> targetKelasList = [];
    if (json['target_kelas'] != null && json['target_kelas'] is List) {
      targetKelasList = (json['target_kelas'] as List)
          .map((e) => extractSafeId(e))
          .where((id) => id.isNotEmpty)
          .toList();
    }

    // 4. Ekstraksi Tanggal
    DateTime parsedDeadline = DateTime.now();
    if (json['deadline'] != null) {
      if (json['deadline'] is DateTime) {
        parsedDeadline = json['deadline'];
      } else if (json['deadline'] is String) {
        parsedDeadline = DateTime.tryParse(json['deadline']) ?? DateTime.now();
      } else if (json['deadline'] is Map && json['deadline']['\$date'] != null) {
        parsedDeadline = DateTime.tryParse(json['deadline']['\$date']) ?? DateTime.now();
      }
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (json['created_at'] != null) {
      if (json['created_at'] is DateTime) {
        parsedCreatedAt = json['created_at'];
      } else if (json['created_at'] is Map && json['created_at']['\$date'] != null) {
        parsedCreatedAt = DateTime.tryParse(json['created_at']['\$date']) ?? DateTime.now();
      }
    }

    DateTime parsedUpdatedAt = DateTime.now();
    if (json['updated_at'] != null) {
      if (json['updated_at'] is DateTime) {
        parsedUpdatedAt = json['updated_at'];
      } else if (json['updated_at'] is Map && json['updated_at']['\$date'] != null) {
        parsedUpdatedAt = DateTime.tryParse(json['updated_at']['\$date']) ?? DateTime.now();
      }
    }

    return TaskModel(
      id: extractSafeId(json['_id']),
      idUser: extractSafeId(json['id_user']),
      namaTugas: json['nama_tugas']?.toString() ?? 'Tugas Tanpa Nama',
      deskripsi: json['deskripsi']?.toString(),
      kodeMk: json['kode_mk']?.toString(),
      namaMkSnapshot: json['nama_mk_snapshot']?.toString(),
      deadline: parsedDeadline,
      status: json['status']?.toString() ?? 'BELUM',
      isSynced: json['is_synced'] ?? true,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      lampiran: parsedLampiran.isNotEmpty ? parsedLampiran : null,
      targetKelas: targetKelasList,
      namaDosen: json['nama_dosen']?.toString() ?? 'Dosen',
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
      'lampiran': lampiran?.map((l) => {
        'name': l['title'] ?? l['name'] ?? 'Lampiran',
        'type': l['type'],
        'data': l['data'],  // Base64 data
        'size': l['size'],
      }).toList(),
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
