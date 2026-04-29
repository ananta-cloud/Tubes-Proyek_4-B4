class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"].toString(),
      nama: json["nama"] ?? "",
      email: json["email"],
      role: json["role"] ?? "",
    );
  }
}
