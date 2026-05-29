import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'announcement_model.g.dart';

@HiveType(typeId: 2)
class AnnouncementModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String judul;

  @HiveField(2)
  final String isi;

  @HiveField(3)
  final String targetAudience;

  @HiveField(4)
  final String idPublisher;

  @HiveField(5)
  final String namaPublisher;

  @HiveField(6)
  final String rolePublisher;

  @HiveField(7)
  final String? idProdi;

  @HiveField(8)
  final String? idJurusan;

  @HiveField(9)
  final List<String>? targetAngkatan;

  @HiveField(10)
  final List<String> kategori;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final String tingkatKepentingan;

  @HiveField(14)
  final List<Map<String, dynamic>> attachments;

  AnnouncementModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.targetAudience,
    required this.idPublisher,
    required this.namaPublisher,
    required this.rolePublisher,
    this.idProdi,
    this.idJurusan,
    this.targetAngkatan,
    required this.kategori,
    required this.createdAt,
    required this.updatedAt,
    required this.tingkatKepentingan,
    this.attachments = const [],
  });

  factory AnnouncementModel.fromMongo(Map<String, dynamic> map) {
    try {
      // 1. Parsing Kategori
      List<String> parsedKategori = [];
      if (map['kategori'] != null) {
        if (map['kategori'] is List) {
          parsedKategori = List<String>.from(
            map['kategori'].map((e) => e.toString()),
          );
        } else {
          parsedKategori = [map['kategori'].toString()];
        }
      }

      // 2. Parsing Target Angkatan
      List<String>? parsedTargetAngkatan;
      if (map['target_angkatan'] != null) {
        if (map['target_angkatan'] is List) {
          parsedTargetAngkatan = List<String>.from(
            map['target_angkatan'].map((e) => e.toString()),
          );
        } else {
          parsedTargetAngkatan = [map['target_angkatan'].toString()];
        }
      }

      // 3. Parsing Attachments
      List<Map<String, dynamic>> parsedAttachments = [];
      if (map['attachments'] != null && map['attachments'] is List) {
        parsedAttachments = (map['attachments'] as List)
            .whereType<Map>()
            .map(
              (e) => Map<String, dynamic>.from(
                e.map((k, v) => MapEntry(k.toString(), v.toString())),
              ),
            )
            .toList();
      }

      DateTime parseDate(dynamic val) {
        if (val == null) return DateTime.now();
        if (val is DateTime) return val;
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        return DateTime.now();
      }

      String parseId(dynamic value) {
        if (value == null) return ObjectId().oid;
        if (value is ObjectId) return value.oid;
        return value.toString();
      }

      return AnnouncementModel(
        id: parseId(map['_id']),
        judul: map['judul']?.toString() ?? 'Tanpa Judul',
        isi: map['isi']?.toString() ?? '',
        targetAudience: map['target_audience']?.toString() ?? 'SEMUA',
        idPublisher: parseId(map['id_publisher']),
        namaPublisher: map['nama_publisher']?.toString() ?? 'Admin',
        rolePublisher: map['role_publisher']?.toString() ?? 'MANAJEMEN',
        idProdi: map['id_prodi'] != null ? parseId(map['id_prodi']) : null,
        idJurusan: map['id_jurusan'] != null
            ? parseId(map['id_jurusan'])
            : null,
        targetAngkatan: parsedTargetAngkatan,
        kategori: parsedKategori,
        tingkatKepentingan: map['tingkat_kepentingan']?.toString() ?? 'BIASA',
        createdAt: parseDate(map['created_at']),
        updatedAt: parseDate(map['updated_at']),
        attachments: parsedAttachments,
      );
    } catch (e) {
      print("❌ ERROR PARSING DARI MONGO: $e");
      print("DATA YANG ERROR: $map");
      rethrow;
    }
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parsedAttachments = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      parsedAttachments = (json['attachments'] as List)
          .whereType<Map>()
          .map(
            (e) => Map<String, String>.from(
              e.map((k, v) => MapEntry(k.toString(), v.toString())),
            ),
          )
          .toList();
    }

    return AnnouncementModel(
      id: json['id'] ?? '',
      judul: json['judul'] ?? '',
      isi: json['isi'] ?? '',
      targetAudience: json['target_audience'] ?? '',
      idPublisher: json['id_publisher'] ?? '',
      namaPublisher: json['nama_publisher'] ?? '',
      rolePublisher: json['role_publisher'] ?? '',
      idProdi: json['id_prodi'],
      idJurusan: json['id_jurusan'],
      targetAngkatan: json['target_angkatan'] != null
          ? List<String>.from(json['target_angkatan'])
          : null,
      kategori: List<String>.from(json['kategori'] ?? []),
      tingkatKepentingan: json['tingkat_kepentingan'] ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      attachments: parsedAttachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'isi': isi,
      'target_audience': targetAudience,
      'id_publisher': idPublisher,
      'nama_publisher': namaPublisher,
      'role_publisher': rolePublisher,
      'id_prodi': idProdi,
      'id_jurusan': idJurusan,
      'target_angkatan': targetAngkatan,
      'kategori': kategori,
      'tingkatKepentingan': tingkatKepentingan,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachments': attachments,
    };
  }
}
