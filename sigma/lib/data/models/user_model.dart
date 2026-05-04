class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role;
<<<<<<< HEAD
  final String? idJurusan;
  final String? idProdi;
  final String? kodeDosen; // DOSEN — untuk match ke schedules.kode_dosen
  final String? kelas; // MAHASISWA — untuk filter jadwal
  final String? angkatan; // MAHASISWA
  final String? deviceToken;
=======
>>>>>>> nazriel

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
<<<<<<< HEAD
    this.idJurusan,
    this.idProdi,
    this.kodeDosen,
    this.kelas,
    this.angkatan,
    this.deviceToken,
=======
>>>>>>> nazriel
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
<<<<<<< HEAD
      id: json['id'] ?? json['_id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      idJurusan: json['id_jurusan']?.toString(),
      idProdi: json['id_prodi']?.toString(),
      kodeDosen: json['kode_dosen'],
      kelas: json['kelas'],
      angkatan: json['angkatan'],
      deviceToken: json['device_token'],
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

  // Helper role checks
  bool get isMahasiswa => role == 'MAHASISWA';
  bool get isDosen => role == 'DOSEN';
  bool get isTimPenjadwalan => role == 'TIM_PENJADWALAN';
  bool get isAdminTu => role == 'ADMIN_TU';
  bool get isManajemen => role == 'MANAJEMEN';
=======
      id: json["_id"].toString(),
      nama: json["nama"] ?? "",
      email: json["email"],
      role: json["role"] ?? "",
    );
  }
>>>>>>> nazriel
}
