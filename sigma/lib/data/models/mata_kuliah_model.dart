class MataKuliahModel {
  final String id;
  final String namaMk;
  final String kodeMk;
  final int sks;
  final String? idProdi;
  final String? idJurusan;

  MataKuliahModel({
    required this.id,
    required this.namaMk,
    required this.kodeMk,
    required this.sks,
    this.idProdi,
    this.idJurusan,
  });

  factory MataKuliahModel.fromJson(Map<String, dynamic> json) {
    return MataKuliahModel(
      id: json["_id"].toString(),
      namaMk: json["nama_mk"] ?? "",
      kodeMk: json["kode_mk"] ?? "",
      sks: json["sks"] ?? 0,
      idProdi: json["id_prodi"]?.toString(),
      idJurusan: json["id_jurusan"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "nama_mk": namaMk,
      "kode_mk": kodeMk,
      "sks": sks,
      "id_prodi": idProdi,
      "id_jurusan": idJurusan,
    };
  }

  @override
  String toString() => namaMk;
}
