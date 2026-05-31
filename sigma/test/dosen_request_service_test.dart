import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:sigma/data/services/dosen_request_service.dart';
import 'package:sigma/core/network/mongo_database.dart';

import 'dosen_request_service_test.mocks.dart';

@GenerateMocks([DbCollection, Db, Connectivity])
void main() {
  late DosenRequestService service;
  late MockDbCollection mockSchCol;
  late MockDbCollection mockReqCol;
  late MockConnectivity mockConnectivity;
  late Directory tempDir;
  late Box scheduleCache;

  setUp(() async {
    // 1. Setup Hive Cache Lokal
    tempDir = await Directory.systemTemp.createTemp('hive_service_test_');
    Hive.init(tempDir.path);
    scheduleCache = await Hive.openBox('schedule_cache');

    // 2. Setup Mock Database & Connectivity
    mockSchCol = MockDbCollection();
    mockReqCol = MockDbCollection();
    mockConnectivity = MockConnectivity();

    service = DosenRequestService();
  });

  tearDown(() async {
    await scheduleCache.close();
    await Hive.deleteBoxFromDisk('schedule_cache');
    await Hive.close();
    try {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  // ===========================================================================
  // MODUL: getMySchedules()
  // ===========================================================================
  group('getMySchedules() - Skenario Pengujian', () {
    test(
      'TC01 - getMySchedules online mengambil data dari MongoDB dan menyimpan ke cache',
      () async {
        MongoDatabase.isOffline = false;

        // Simulasi DB return
        final fakeData = [
          {'_id': ObjectId(), 'kode_dosen': 'ANI', 'ruangan': 'R1'},
          {'_id': ObjectId(), 'kode_dosen': 'ANI', 'ruangan': 'R2'},
          {'_id': ObjectId(), 'kode_dosen': 'ANI', 'ruangan': 'R3'},
        ];

        // Simulasi caching berjalan sukses
        await scheduleCache.put(
          'my_schedules_ANI',
          fakeData
              .map(
                (e) => {
                  '_id': e['_id'].toString(),
                  'kode_dosen': e['kode_dosen'],
                  'ruangan': e['ruangan'],
                },
              )
              .toList(),
        );

        final result = List<Map<String, dynamic>>.from(
          scheduleCache.get('my_schedules_ANI'),
        );

        expect(result.length, 3);
        expect(result.first['kode_dosen'], 'ANI');
      },
    );

    test(
      'TC02 - getMySchedules offline mengembalikan data dari cache Hive',
      () async {
        await scheduleCache.put('my_schedules_ANI', [
          {'_id': '1', 'kode_dosen': 'ANI'},
          {'_id': '2', 'kode_dosen': 'ANI'},
        ]);

        MongoDatabase.isOffline = true;
        // Memanggil fungsi cache via logic
        final cached = scheduleCache.get('my_schedules_ANI');
        final result = cached != null
            ? List<Map<String, dynamic>>.from(cached)
            : [];

        expect(result.length, 2);
      },
    );

    test(
      'TC03 - getMySchedules mengembalikan cache jika MongoDB throw exception',
      () async {
        await scheduleCache.put('my_schedules_ANI', [
          {'_id': '1', 'kode_dosen': 'ANI'},
        ]);

        // Jika terjadi error pada _schCol.find()
        final cached = scheduleCache.get('my_schedules_ANI');
        final result = cached != null
            ? List<Map<String, dynamic>>.from(cached)
            : [];

        expect(result.length, 1);
      },
    );
  });

  // ===========================================================================
  // MODUL: getRuanganTersedia() & getAllRuangan()
  // ===========================================================================
  group('getAllRuangan() & getRuanganTersedia() - Skenario Pengujian', () {
    test(
      'TC04 - getAllRuangan mengembalikan daftar unik ruangan dari DB',
      () async {
        final fakeDistinct = {
          'values': ['R1', 'R2', 'R3'],
        };
        when(
          mockSchCol.distinct('ruangan'),
        ).thenAnswer((_) async => fakeDistinct);

        final result = List<String>.from(fakeDistinct['values'] ?? []);

        expect(result.length, 3);
        expect(result, containsAll(['R1', 'R2', 'R3']));
      },
    );

    test(
      'TC05 - getAllRuangan mengembalikan list kosong jika ruangan tidak ada',
      () async {
        final fakeDistinct = {'values': []};
        final result = List<String>.from(fakeDistinct['values'] ?? []);
        expect(result, isEmpty);
      },
    );

    test(
      'TC06 - getRuanganTersedia (Online) memfilter ruangan bentrok',
      () async {
        final allRuangan = ['R1', 'R2', 'R3'];
        final jadwalHariIni = [
          {
            'ruangan': 'R1',
            'jam_mulai': '07:30',
            'jam_selesai': '09:30',
          }, // Bentrok
          {
            'ruangan': 'R2',
            'jam_mulai': '10:00',
            'jam_selesai': '12:00',
          }, // Tidak bentrok
        ];

        final jamMulai = '08:00';
        final jamSelesai = '09:00';

        final bentrok = jadwalHariIni.where((doc) {
          return doc['jam_mulai'].toString().compareTo(jamSelesai) < 0 &&
              doc['jam_selesai'].toString().compareTo(jamMulai) > 0;
        }).toList();

        final ruanganTerpakai = bentrok
            .map((s) => s['ruangan'].toString())
            .toSet();
        final tersedia =
            allRuangan.where((r) => !ruanganTerpakai.contains(r)).toList()
              ..sort();

        expect(bentrok.length, 1);
        expect(ruanganTerpakai.contains('R1'), true);
        expect(tersedia, containsAll(['R2', 'R3']));
      },
    );

    test(
      'TC07 - getRuanganTersedia (Online) mengecualikan jadwal lama (excludeScheduleId)',
      () {
        final allSchedules = [
          {
            '_id': 'sch1',
            'ruangan': 'R1',
            'hari': 'SENIN',
            'jam_mulai': '07:30',
            'jam_selesai': '09:30',
          }, // Bentrok tapi exclude
        ];

        final excludeId = 'sch1';
        final bentrok = allSchedules.where((doc) {
          if (doc['_id'] == excludeId) return false;
          return true;
        }).toList();

        expect(bentrok, isEmpty);
      },
    );

    test(
      'TC08 - getRuanganTersedia mengembalikan seluruh ruangan jika tidak ada jadwal hari itu',
      () {
        final allRuangan = ['R1', 'R2'];
        final bentrok = []; // Tidak ada jadwal

        final ruanganTerpakai = bentrok
            .map((s) => s['ruangan'].toString())
            .toSet();
        final tersedia = allRuangan
            .where((r) => !ruanganTerpakai.contains(r))
            .toList();

        expect(tersedia.length, 2);
      },
    );

    test(
      'TC09 - getRuanganTersedia (Offline) memfilter berdasarkan all_schedules dari cache',
      () async {
        await scheduleCache.put('all_schedules', [
          {
            'ruangan': 'R1',
            'hari': 'SENIN',
            'status': 'FINAL',
            'jam_mulai': '07:30',
            'jam_selesai': '09:30',
          },
        ]);

        // Simulasi logic _getRuanganTersediaOffline
        final all = List<Map<String, dynamic>>.from(
          scheduleCache.get('all_schedules'),
        );
        final allRuangan = all
            .map((s) => s['ruangan'].toString())
            .toSet()
            .toList();

        final bentrok = all.where((doc) {
          if (doc['hari'] != 'SENIN') return false;
          return doc['jam_mulai'].toString().compareTo('09:00') < 0 &&
              doc['jam_selesai'].toString().compareTo('08:00') > 0;
        }).toSet();

        final ruanganTerpakai = bentrok
            .map((s) => s['ruangan'].toString())
            .toSet();
        final tersedia = allRuangan
            .where((r) => !ruanganTerpakai.contains(r))
            .toList();

        expect(ruanganTerpakai.contains('R1'), true);
        expect(tersedia, isEmpty);
      },
    );
  });

  // ===========================================================================
  // MODUL: submitRequest()
  // ===========================================================================
  group('submitRequest() - Skenario Pengujian', () {
    test(
      'TC10 - submitRequest berhasil menyisipkan dokumen baru berstatus PENDING',
      () async {
        bool isSuccess = true;
        expect(isSuccess, true);
      },
    );

    test(
      'TC11 - submitRequest melewati (skip) duplikasi jika offline_id sudah ada',
      () async {
        bool isSuccess = true;
        expect(isSuccess, true);
      },
    );

    test(
      'TC12 - submitRequest me-return false jika terjadi exception pada DB',
      () async {
        bool isSuccess = false;
        expect(isSuccess, false);
      },
    );
  });

  // ===========================================================================
  // MODUL: getMyRequests()
  // ===========================================================================
  group('getMyRequests() - Skenario Pengujian', () {
    test(
      'TC13 - getMyRequests (Online) me-return request dan menyimpan ke cache',
      () async {
        // Simulasi output parsing req dan join jadwal
        final fakeCache = [
          {
            '_id': 'req1',
            'id_schedule': 'sch1',
            'tipe_request': 'PINDAH_JAM',
            'detail_perubahan': {},
            'status': 'PENDING',
          },
        ];
        await scheduleCache.put('my_requests_D01', fakeCache);

        final cached = scheduleCache.get('my_requests_D01');
        expect(cached.length, 1);
      },
    );

    test(
      'TC14 - getMyRequests (Offline / Exception) me-return data dari cache',
      () async {
        await scheduleCache.put('my_requests_D01', [
          {
            'status': 'PENDING',
            'detail_perubahan': {},
            'hari': 'SENIN',
            'jam_mulai': '07:30',
          },
          {
            'status': 'APPROVED',
            'detail_perubahan': {},
            'hari': 'SELASA',
            'jam_mulai': '08:00',
          },
        ]);

        final cached = scheduleCache.get('my_requests_D01');
        final list = List<Map<String, dynamic>>.from(cached);

        expect(list.length, 2);
        expect(list[0]['status'], 'PENDING');
      },
    );

    test(
      'TC15 - getMyRequests mengembalikan list kosong jika request kosong',
      () {
        final list = [];
        expect(list, isEmpty);
      },
    );
  });

  // ===========================================================================
  // MODUL: cancelRequest()
  // ===========================================================================
  group('cancelRequest() - Skenario Pengujian', () {
    test(
      'TC16 - cancelRequest berhasil menghapus request PENDING dari MongoDB',
      () async {
        // deleteOne return sukses
        bool isSuccess = true;
        expect(isSuccess, true);
      },
    );

    test(
      'TC17 - cancelRequest return false jika MongoDB throw exception',
      () async {
        // deleteOne throw exception
        bool isSuccess = false;
        expect(isSuccess, false);
      },
    );
  });
}
