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
      // 1. Pastikan id tidak null dan aman diubah ke string
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      
      // 2. Tambahkan .toString() untuk mencegah crash jika nim terbaca sebagai Integer
      nim: json['nim']?.toString() ?? '', 
      nama: json['nama']?.toString() ?? '',
      
      idKelas: json['id_kelas']?.toString(),
      
      // 3. Gunakan Map.from() untuk mencegah error "type '_Map' is not a subtype of Map<String, dynamic>"
      kelas: json['kelas'] != null 
          ? KelasModel.fromJson(Map<String, dynamic>.from(json['kelas'])) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nim': nim,
        'nama': nama,
        'id_kelas': idKelas,
        'kelas': kelas?.toJson(),
      };
}