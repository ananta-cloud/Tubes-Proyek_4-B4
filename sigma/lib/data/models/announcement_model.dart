import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'announcement_model.g.dart';

@HiveType(typeId: 0)
class AnnouncementModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String judul;
  @HiveField(2) final String isi;
  @HiveField(3) final String targetAudience;
  @HiveField(4) final String namaPublisher;
  @HiveField(5) final List<String> kategori;
  @HiveField(6) final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.targetAudience,
    required this.namaPublisher,
    required this.kategori,
    required this.createdAt,
  });

  // Format dari mongo_dart: _id adalah ObjectId, date adalah DateTime langsung
  factory AnnouncementModel.fromMongo(Map<String, dynamic> map) {
    return AnnouncementModel(
      id:             (map['_id'] as ObjectId).toHexString(),
      judul:          map['judul'] ?? 'Tanpa Judul',
      isi:            map['isi'] ?? '',
      targetAudience: map['target_audience'] ?? 'SEMUA',
      namaPublisher:  map['nama_publisher'] ?? 'Admin',
      kategori:       map['kategori'] != null
                        ? List<String>.from(map['kategori'])
                        : [],
      createdAt:      map['created_at'] != null
                        ? map['created_at'] as DateTime
                        : DateTime.now(),
    );
  }
}