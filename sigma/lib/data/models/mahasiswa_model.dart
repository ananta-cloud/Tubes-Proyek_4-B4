import 'kelas_model.dart';

class MahasiswaModel {
  final String id;
  final String userId;
  final String nim;
  final String? idKelas;
  final KelasModel? kelas;

  MahasiswaModel({
    required this.id,
    required this.userId,
    required this.nim,
    this.idKelas,
    this.kelas,
  });

  factory MahasiswaModel.fromJson(Map<String, dynamic> json) {
    return MahasiswaModel(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      nim: json['nim'] ?? '',
      idKelas: json['id_kelas']?.toString(),
      // Jika data kelas ikut terbawa (join/lookup), parsing menjadi KelasModel
      kelas: json['kelas'] != null ? KelasModel.fromJson(json['kelas']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'nim': nim,
        'id_kelas': idKelas,
        'kelas': kelas?.toJson(),
      };
}