import 'package:hive/hive.dart';

part 'announcement_local_model.g.dart';

@HiveType(typeId: 2) // Pastikan typeId berbeda dengan Schedule (1)
class AnnouncementLocalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String judul;

  @HiveField(2)
  String isi;

  @HiveField(3)
  String kategori;

  @HiveField(4)
  String tanggal;

  @HiveField(5)
  bool isImportant;

  AnnouncementLocalModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.tanggal,
    required this.isImportant,
  });

  factory AnnouncementLocalModel.fromJson(Map<String, dynamic> json) {
    // Penanganan default value dari JSON Laravel
    String textKategori = json['target_audience'] ?? json['kategori'] ?? 'Umum';
    String textJudul = json['judul'] ?? 'Tanpa Judul';

    // Logika sederhana untuk menentukan apakah pengumuman ini "Penting"
    bool penting =
        textKategori.toLowerCase().contains('penting') ||
        textKategori.toLowerCase().contains('dosen') ||
        textJudul.toLowerCase().contains('wajib');

    return AnnouncementLocalModel(
      id:
          json['_id']?.toString() ??
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      judul: json['judul'] ?? json['title'] ?? 'Tanpa Judul',
      isi: json['isi'] ?? '',
      kategori: textKategori,
      tanggal: json['created_at'] != null
          ? json['created_at'].toString().substring(0, 10)
          : '-',
      isImportant: penting,
    );
  }

  @override
  String toString() {
    return 'AnnouncementLocalModel(judul: $judul, kategori: $kategori, tanggal: $tanggal)';
  }
}
