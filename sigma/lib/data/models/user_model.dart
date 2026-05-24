class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role;
  final String? idJurusan;
  final String? idProdi;
  final String? kelas;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.idJurusan,
    this.idProdi,
    this.kelas,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'email': email,
    'role': role,
  };

  // Helper role checks
  bool get isMahasiswa => role == 'MAHASISWA';
  bool get isDosen => role == 'DOSEN';
  bool get isTimPenjadwalan => role == 'TIM_PENJADWALAN';
  bool get isAdminTu => role == 'ADMIN_TU';
  bool get isManajemen => role == 'MANAJEMEN';
}
