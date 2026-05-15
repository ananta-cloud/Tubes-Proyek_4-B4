class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role;
  final String? idJurusan;
  final String? idProdi;
  final String? kodeDosen;
  final String? kelas;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.idJurusan,
    this.idProdi,
    this.kodeDosen,
    this.kelas,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"]
          .toString()
          .replaceAll('ObjectId("', '')
          .replaceAll('")', ''),
      nama: json["nama"] ?? "",
      email: json["email"],
      role: json["role"] ?? "",
      idJurusan: json["id_jurusan"]?.toString(),
      idProdi: json["id_prodi"]?.toString(),
      kodeDosen: json["kode_dosen"],
      kelas: json["kelas"],
    );
  }
}
