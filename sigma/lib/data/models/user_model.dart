import 'mahasiswa_model.dart';

class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role;  
  final String? deviceToken;
  final MahasiswaModel? profilMahasiswa;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.deviceToken,
    this.profilMahasiswa,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {

    final String currentRole = json['role'] ?? '';
    final dynamic profilData = json['profil'];

    return UserModel(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      deviceToken: json['device_token'],
      profilMahasiswa: (currentRole == 'MAHASISWA' && profilData != null) 
          ? MahasiswaModel.fromJson(profilData) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {

    dynamic profilJson;
    if (role == 'MAHASISWA') profilJson = profilMahasiswa?.toJson();
    // else if (role == 'DOSEN') profilJson = profilDosen?.toJson();

    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': role,
      'device_token': deviceToken,
      'profil': profilJson,
    };
  }

  // Helper role checks
  bool get isMahasiswa => role == 'MAHASISWA';
  bool get isDosen => role == 'DOSEN';
  bool get isTimPenjadwalan => role == 'TIM_PENJADWALAN';
  bool get isAdminTu => role == 'ADMIN_TU';
  bool get isManajemen => role == 'MANAJEMEN';
}
