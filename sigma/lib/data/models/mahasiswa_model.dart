import 'kelas_model.dart';

class MahasiswaModel {
  final String id;
  final String email;
  final String nim;
  final String nama;
  final String? idKelas;
  final KelasModel? kelas;

  MahasiswaModel({
    required this.id,
    required this.email,
    required this.nim,
    required this.nama,
    this.idKelas,
    this.kelas,
  });

  factory MahasiswaModel.fromJson(Map<String, dynamic> json) {
    return MahasiswaModel(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      email: json['email']?.toString() ?? '',
      nim: json['nim'] ?? '',
      nama: json['nama'] ?? '',
      idKelas: json['id_kelas']?.toString(),
      kelas: json['kelas'] != null ? KelasModel.fromJson(json['kelas']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email':email,
        'nim': nim,
        'nama': nama,
        'id_kelas': idKelas,
        'kelas': kelas?.toJson(),
      };
}
