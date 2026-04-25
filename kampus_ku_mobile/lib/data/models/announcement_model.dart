import 'package:hive/hive.dart';

part 'announcement_model.g.dart';

@HiveType(typeId: 0)
class AnnouncementModel extends HiveObject {
  @HiveField(0)
  final String id; // Dari _id MongoDB

  @HiveField(1)
  final String judul;

  @HiveField(2)
  final String isi;

  @HiveField(3)
  final String targetAudience; // Contoh: 'SEMUA_MAHASISWA', 'PRODI_MAHASISWA'

  @HiveField(4)
  final String namaPublisher; 

  @HiveField(5)
  final List<String> kategori; // Karena di Mongo berupa Array, di sini pakai List<String>

  @HiveField(6)
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.targetAudience,
    required this.namaPublisher,
    required this.kategori,
    required this.createdAt,
  });

  // Fungsi tambahan yang sangat berguna untuk mengubah JSON dari API Laravel menjadi Model Dart
  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['_id'] ?? '',
      judul: json['judul'] ?? 'Tanpa Judul',
      isi: json['isi'] ?? '',
      targetAudience: json['target_audience'] ?? 'SEMUA',
      namaPublisher: json['nama_publisher'] ?? 'Admin',
      // Menangani array kategori dari JSON dengan aman
      kategori: json['kategori'] != null ? List<String>.from(json['kategori']) : [],
      // MongoDB biasanya mengirim tanggal dalam format ISO 8601
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}