import 'package:hive/hive.dart';

part 'announcement_model.g.dart';

@HiveType(typeId: 2) // Pastikan typeId tidak bentrok dengan model lain (Jadwal = 1)
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
  final String namaPublisher;

  @HiveField(5)
  final List<String> kategori;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isImportant;

  AnnouncementModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.targetAudience,
    required this.namaPublisher,
    required this.kategori,
    required this.createdAt,
    required this.isImportant,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    // 1. Parsing Kategori secara aman
    List<String> parsedKategori = [];
    if (json['kategori'] != null) {
      if (json['kategori'] is List) {
        parsedKategori = List<String>.from(json['kategori']);
      } else if (json['kategori'] is String) {
        parsedKategori = json['kategori'].toString().split(',').map((e) => e.trim()).toList();
      }
    }

    // 2. Parsing Tanggal secara aman
    DateTime parsedDate = DateTime.now();
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        parsedDate = DateTime.now();
      }
    }

    // Ekstraksi nilai untuk dicek
    String textJudul = json['judul']?.toString() ?? json['title']?.toString() ?? 'Tanpa Judul';
    String textTarget = json['target_audience']?.toString() ?? 'SEMUA';

    // 3. Logika untuk menentukan apakah pengumuman penting
    bool penting = parsedKategori.any((k) => k.toLowerCase().contains('penting')) ||
                   textTarget.toLowerCase().contains('dosen') ||
                   textJudul.toLowerCase().contains('wajib');

    // Jika API sudah mengirimkan boolean 'is_important', kita pakai itu. Jika tidak, pakai logika di atas.
    bool finalIsImportant = json['is_important'] ?? penting;

    return AnnouncementModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      judul: textJudul,
      isi: json['isi']?.toString() ?? '',
      targetAudience: textTarget,
      namaPublisher: json['nama_publisher']?.toString() ?? json['nama_pembuat']?.toString() ?? 'Admin',
      kategori: parsedKategori,
      createdAt: parsedDate,
      isImportant: finalIsImportant, // Masukkan ke model
    );
  }

  @override
  String toString() {
    return 'AnnouncementModel(judul: $judul, kategori: $kategori, isImportant: $isImportant)';
  }
}