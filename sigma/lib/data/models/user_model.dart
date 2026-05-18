class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role;
  final String? idJurusan;
  final String? idProdi;
  final String? kodeDosen; 
  final String? kelas; 
  final String? angkatan; 
  final String? deviceToken;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.idJurusan,
    this.idProdi,
    this.kodeDosen,
    this.kelas,
    this.angkatan,
    this.deviceToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? cleanId(dynamic val) {
      if (val == null) return null;
      String str = val.toString();
      return str.replaceAll('ObjectId("', '').replaceAll('")', '');
    }

    return UserModel(
      id: cleanId(json['id']) ?? cleanId(json['_id']) ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      idJurusan: cleanId(json['id_jurusan']),
      idProdi: cleanId(json['id_prodi']),
      kodeDosen: json['kode_dosen']?.toString(),
      kelas: json['kelas']?.toString(),
      angkatan: json['angkatan']?.toString(),
      deviceToken: json['device_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'email': email,
    'role': role,
    'id_jurusan': idJurusan,
    'id_prodi': idProdi,
    'kode_dosen': kodeDosen,
    'kelas': kelas,
    'angkatan': angkatan,
    'device_token': deviceToken,
  };

  bool get isMahasiswa => role == 'MAHASISWA';
  bool get isDosen => role == 'DOSEN';
  bool get isTimPenjadwalan => role == 'TIM_PENJADWALAN';
  bool get isAdminTu => role == 'ADMIN_TU';
  bool get isManajemen => role == 'MANAJEMEN';
}