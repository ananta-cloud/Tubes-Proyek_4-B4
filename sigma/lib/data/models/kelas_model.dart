class KelasModel {
  final String id;
  final String namaKelas;
  final String idProdi;
  final String? namaProdi;
  final int angkatan;

  KelasModel({
    required this.id,
    required this.namaKelas,
    required this.idProdi,
    this.namaProdi,
    required this.angkatan,
  });

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      namaKelas: json['nama_kelas'] ?? '',
      idProdi: json['id_prodi']?.toString() ?? '',
      namaProdi: json['nama_prodi']?.toString(),
      angkatan: json['angkatan'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_kelas': namaKelas,
        'id_prodi': idProdi,
        'nama_prodi': namaProdi,
        'angkatan': angkatan,
      };
}