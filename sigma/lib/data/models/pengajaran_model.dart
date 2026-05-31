import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'pengajaran_model.g.dart';

@HiveType(typeId: 9)
class PengajaranModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String kodeDosen;

  @HiveField(2)
  final String kodeMk;

  @HiveField(3)
  final String namaMk;

  @HiveField(4)
  final List<String> targetKelas;

  PengajaranModel({
    required this.id,
    required this.kodeDosen,
    required this.kodeMk,
    required this.namaMk,
    required this.targetKelas,
  });

  factory PengajaranModel.fromMongo(Map<String, dynamic> json) {
    // Helper ekstraksi ID yang lebih tangguh (kebal terhadap format aneh)
    String extractId(dynamic field) {
      if (field == null) return '';
      if (field is ObjectId) return field.toHexString();
      return field.toString().replaceAll('ObjectId("', '').replaceAll('")', '').trim();
    }

    List<String> parsedKelasIds = [];
    var targetData = json['target_kelas'];

    if (targetData is List) {
      for (var item in targetData) {
        if (item is ObjectId) {
          parsedKelasIds.add(item.toHexString()); // Ubah ObjectId ke String Hex
        } else if (item != null) {
          parsedKelasIds.add(item.toString());
        }
      }
    }

    return PengajaranModel(
      id: extractId(json['_id']),
      kodeDosen: json['kode_dosen']?.toString() ?? '',
      kodeMk: json['kode_mk']?.toString() ?? '',
      namaMk: json['nama_mk']?.toString() ?? '',
      targetKelas: parsedKelasIds, // Menyimpan kumpulan ID kelas berbentuk String Hex
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Sangat disarankan menyertakan _id jika toJson ini dipakai untuk UPDATE data ke MongoDB
      if (id.isNotEmpty && id.length == 24) 
        '_id': ObjectId.fromHexString(id),
        
      'kode_dosen': kodeDosen,
      'kode_mk': kodeMk,
      'nama_mk': namaMk,
      'target_kelas': targetKelas.map((kelasId) {
        try {
          if (kelasId.length == 24) {
            return ObjectId.fromHexString(kelasId);
          }
          return kelasId; 
        } catch (e) {
          return kelasId; 
        }
      }).toList(),
    };
  }
}
