import 'package:mongo_dart/mongo_dart.dart';
import '../../../../core/network/mongo_database.dart';

class AuthService {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    // 1. Cek kredensial di collection users
    final user = await MongoDatabase.runSafe(
      () => MongoDatabase.usersCollection.findOne(
        where.eq("email", email).eq("password", password),
      ),
    );

    // 2. Jika user ditemukan dan dia adalah MAHASISWA, ambil data relasinya
    if (user != null && user['role'] == 'MAHASISWA') {
      
      final profilMahasiswa = await MongoDatabase.runSafe(
        () => MongoDatabase.mahasiswaCollection.findOne(
          where.eq("user_id", user['_id']),
        ),
      );

      if (profilMahasiswa != null) {
        if (profilMahasiswa['id_kelas'] != null) {
          final dataKelas = await MongoDatabase.runSafe(
            () => MongoDatabase.kelasCollection.findOne(
              where.eq("_id", profilMahasiswa['id_kelas']),
            ),
          );
          
          profilMahasiswa['kelas'] = dataKelas;
        }

        user['profil'] = profilMahasiswa;
      }
    }
    
    // TODO: Kalau collection dosen ditambah, tambahin blok if (user['role'] == 'DOSEN') di sini

    return user;
  }
}