import 'package:mongo_dart/mongo_dart.dart';
import '../../core/network/mongo_database.dart';

class PengajaranService {
  Future<List<Map<String, dynamic>>> getPengajaranByDosen(
    String kodeDosen,
  ) async {
    print(
      "DEBUG: Mencari pengajaran untuk kode_dosen: '$kodeDosen'",
    );

    var result = await MongoDatabase.db
        .collection('pengajaran')
        .find(where.eq('kode_dosen', kodeDosen))
        .toList();

    print(
      "DEBUG: Hasil ditemukan: ${result.length} dokumen",
    ); // Kalau 0, berarti filternya salah
    return result;
  }

  Future<bool> sinkronisasiMasterData() async {
    try {
      bool kelasSuccess = await generateKelasFromSchedules();
      if (!kelasSuccess) {
        print("🚨 DEBUG: generateKelasFromSchedules gagal!");
        return false;
      }

      bool pengajaranSuccess = await generatePengajaranFromSchedules();
      if (!pengajaranSuccess) {
        print("🚨 DEBUG: generatePengajaranFromSchedules gagal!");
        return false;
      }

      return true;
    } catch (e) {
      print("🚨 DEBUG: Fatal error di sinkronisasiMasterData: $e");
      return false;
    }
  }

  Future<bool> generateKelasFromSchedules() async {
    return await MongoDatabase.runSafe(() async {
      try {
        final schedulesColl = MongoDatabase.db.collection('schedules');
        final kelasColl = MongoDatabase.db.collection('kelas');
        final prodiColl = MongoDatabase.db.collection('prodi');

        final distinctKelas = await schedulesColl.aggregateToStream([
          {
            '\$group': {'_id': '\$kelas'},
          },
        ]).toList();

        final allProdi = await prodiColl.find().toList();
        final Map<String, ObjectId> prodiMap = {};
        for (var p in allProdi) {
          String n = p['nama_prodi']?.toString().toUpperCase() ?? '';
          if (n.contains('D3'))
            prodiMap['D3'] = p['_id'] as ObjectId;
          else if (n.contains('D4'))
            prodiMap['D4'] = p['_id'] as ObjectId;
        }

        final existing = await kelasColl.find().toList();
        final Set<String> existingSet = existing
            .map((k) => "${k['nama_kelas']}-${k['id_prodi']}")
            .toSet();

        List<Map<String, dynamic>> newKelas = [];
        for (var doc in distinctKelas) {
          String raw = doc['_id']?.toString().trim() ?? '';
          if (raw.isEmpty || !raw.contains('-')) continue;

          List<String> parts = raw.split('-');
          String nama = parts[0];
          String prodiKey = parts[1].toUpperCase();
          ObjectId? pId = prodiMap[prodiKey];

          // Memastikan pId ditemukan sebelum insert
          if (pId != null && !existingSet.contains("$nama-$pId")) {
            newKelas.add({
              'nama_kelas': nama,
              'id_prodi': pId,
              'created_at': DateTime.now(),
              'updated_at': DateTime.now(),
            });
            existingSet.add("$nama-$pId");
          }
        }

        if (newKelas.isNotEmpty) await kelasColl.insertAll(newKelas);
        return true;
      } catch (e) {
        print("❌ Error Generate Kelas: $e");
        return false;
      }
    });
  }

  Future<bool> generatePengajaranFromSchedules() async {
    return await MongoDatabase.runSafe(() async {
      try {
        final schedulesColl = MongoDatabase.db.collection('schedules');
        final kelasColl = MongoDatabase.db.collection('kelas');
        final pengajaranColl = MongoDatabase.db.collection('pengajaran');

        await pengajaranColl.remove(where.exists('_id'));

        final allKelasList = await kelasColl.find().toList();

        final pipeline = [
        // 1. Hubungkan schedules dengan collection mata_kuliah berdasarkan kode_mk
        {
          '\$lookup': {
            'from': 'mata_kuliah',
            'localField': 'kode_mk',
            'foreignField': 'kode_mk',
            'as': 'mk_info',
          },
        },
        // 2. Unwind agar data hasil lookup menjadi objek tunggal
        {
          '\$unwind': {
            'path': '\$mk_info',
            'preserveNullAndEmptyArrays': true, // Tetap simpan jadwal meski matkul tidak ketemu
          },
        },
        // 3. Grouping dengan nama yang benar dari collection mata_kuliah
        {
          '\$group': {
            '_id': {
              'kode_mk': '\$kode_mk',
              'kode_dosen': { '\$arrayElemAt': ['\$kode_dosen', 0] },
              'nama_mk': { '\$ifNull': ['\$mk_info.nama_mk', '\$nama_matkul'] },
            },
            'kelas_list': {'\$addToSet': '\$kelas'},
          },
        },
      ];

        final aggregated = await schedulesColl
            .aggregateToStream(pipeline)
            .toList();
        List<Map<String, dynamic>> toInsert = [];

        for (var doc in aggregated) {
          final idGroup = doc['_id'] as Map<String, dynamic>;
          List<ObjectId> targetIds = [];

          for (var item in doc['kelas_list']) {
            String raw = item.toString().trim(); // misal "2B-D3"

            // Cari kelas yang namanya ada di dalam string jadwal
            // Contoh: "2B" ada di dalam "2B-D3" -> MATCH!
            final match = allKelasList.firstWhere(
              (k) => raw.contains(k['nama_kelas'].toString()),
              orElse: () => {},
            );

            if (match.isNotEmpty) targetIds.add(match['_id'] as ObjectId);
          }

          if (idGroup['kode_dosen'] != null && targetIds.isNotEmpty) {
            toInsert.add({
              'kode_dosen': idGroup['kode_dosen'].toString(),
              'kode_mk': idGroup['kode_mk'].toString(),
              'nama_mk': idGroup['nama_mk'].toString(),
              'target_kelas': targetIds,
              'created_at': DateTime.now(),
            });
          }
        }

        if (toInsert.isNotEmpty) {
          await pengajaranColl.insertAll(toInsert);
          return true;
        }
        return false;
      } catch (e) {
        print("❌ Error Fatal: $e");
        return false;
      }
    });
  }
}
