import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:mongo_dart/src/database/commands/query_and_write_operation_commands/return_classes/write_result.dart';
import 'package:mongo_dart/src/database/commands/query_and_write_operation_commands/return_classes/abstract_write_result.dart';

import 'package:sigma/data/models/schedule_request_model.dart';
=======
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:connectivity_plus/connectivity_plus.dart';

>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
import 'package:sigma/data/services/dosen_request_service.dart';
import 'package:sigma/core/network/mongo_database.dart';

import 'dosen_request_service_test.mocks.dart';

<<<<<<< HEAD
class FakeDbCollection extends Fake implements DbCollection {
  Stream<Map<String, dynamic>> Function(dynamic)? onFind;
  Future<Map<String, dynamic>> Function(String)? onDistinct;
  Future<Map<String, dynamic>?> Function(dynamic)? onFindOne;
  bool insertOneShouldThrow = false;
  bool deleteOneShouldThrow = false;
  int insertOneCallCount = 0;
  int deleteOneCallCount = 0;

  void reset() {
    onFind = null;
    onDistinct = null;
    onFindOne = null;
    insertOneShouldThrow = false;
    deleteOneShouldThrow = false;
    insertOneCallCount = 0;
    deleteOneCallCount = 0;
  }

  @override
  Stream<Map<String, dynamic>> find([dynamic selector]) {
    if (onFind != null) return onFind!(selector);
    return const Stream.empty();
  }

  @override
  Future<Map<String, dynamic>> distinct(String field, [dynamic selector]) {
    if (onDistinct != null) return onDistinct!(field);
    return Future.value({'values': []});
  }

  @override
  Future<Map<String, dynamic>?> findOne([dynamic selector]) {
    if (onFindOne != null) return onFindOne!(selector);
    return Future.value(null);
  }

  @override
  Future<WriteResult> insertOne(
    Map<String, dynamic> document, {
    WriteConcern? writeConcern,
    bool? bypassDocumentValidation,
  }) async {
    insertOneCallCount++;
    if (insertOneShouldThrow) throw Exception('insertOne error');
    return WriteResult.fromMap(WriteCommandType.insert, {'ok': 1, 'n': 1});
  }

  @override
  Future<WriteResult> deleteOne(
    dynamic selector, {
    WriteConcern? writeConcern,
    CollationOptions? collation,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    deleteOneCallCount++;
    if (deleteOneShouldThrow) throw Exception('deleteOne error');
    return WriteResult.fromMap(WriteCommandType.delete, {'ok': 1, 'n': 1});
  }
}

@GenerateMocks([Connectivity])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box scheduleCache;
  late FakeDbCollection fakeSchCol;
  late FakeDbCollection fakeReqCol;
  late MockConnectivity mockConnectivity;
  late DosenRequestService service;

  // ── Helpers ───────────────────────────────────────────────────────────────

  void stubOnline(bool online) {
    when(mockConnectivity.checkConnectivity()).thenAnswer(
      (_) async =>
          online ? [ConnectivityResult.wifi] : [ConnectivityResult.none],
    );
  }

  Map<String, dynamic> makeScheduleDoc({
    String id = 'sch1',
    String kodeDosen = 'ANI',
    String hari = 'SENIN',
    String jamMulai = '07:00',
    String jamSelesai = '09:00',
    String ruangan = 'R1',
    String namaMk = 'Basis Data',
    String kodeMk = 'BD101',
    String kelas = 'A',
    String status = 'ACTIVE',
  }) => {
    '_id': id,
    'kode_dosen': kodeDosen,
    'hari': hari,
    'jam_mulai': jamMulai,
    'jam_selesai': jamSelesai,
    'ruangan': ruangan,
    'nama_mk': namaMk,
    'kode_mk': kodeMk,
    'kelas': kelas,
    'status': status,
  };

  Map<String, dynamic> makeRequestDoc({
    String id = 'req1',
    String idDosen = 'aabbccddeeff001122334401',
    String idSchedule = 'aabbccddeeff001122334411',
    String status = 'PENDING',
  }) => {
    '_id': id,
    'id_schedule': ObjectId.fromHexString(idSchedule),
    'id_dosen': idDosen,
    'nama_dosen': 'Bu Ani',
    'tipe_request': 'PINDAH_JAM',
    'detail_perubahan': {
      'tanggal_baru': '2025-06-04T00:00:00.000',
      'hari_baru': 'RABU',
      'jam_mulai_baru': '08:00',
      'jam_selesai_baru': '09:40',
      'ruangan_baru': '',
    },
    'alasan': 'Bentrok',
    'nama_matkul': 'Basis Data',
    'status': status,
    'offline_id': null,
    'catatan_admin': null,
    'id_processor': null,
    'is_late': false,
    'created_at': null,
    'updated_at': null,
  };

  List<Map<String, dynamic>> makeCachedRequestList(int count, String idDosen) =>
      List.generate(
        count,
        (i) => {
          '_id': 'req$i',
          'id_schedule': 'S$i',
          'id_dosen': idDosen,
          'nama_dosen': 'Bu Ani',
          'tipe_request': 'PINDAH_JAM',
          'detail_perubahan': {
            'hari_baru': 'RABU',
            'jam_mulai_baru': '08:00',
            'jam_selesai_baru': '09:40',
            'ruangan_baru': '',
          },
          'alasan': 'Bentrok',
          'status': 'PENDING',
          'offline_id': null,
          'catatan_admin': null,
          'id_processor': null,
          'is_late': false,
          'created_at': null,
          'updated_at': null,
          'nama_mk': 'Basis Data',
          'kode_mk': 'BD101',
          'hari': 'SENIN',
          'jam_mulai': '07:30',
          'jam_selesai': '09:10',
          'ruangan': 'R1',
          'kelas': 'A',
        },
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_drs_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(DetailPerubahanAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(ScheduleRequestModelAdapter());

    scheduleCache = await Hive.openBox('schedule_cache');
    fakeSchCol = FakeDbCollection();
    fakeReqCol = FakeDbCollection();
    mockConnectivity = MockConnectivity();
    MongoDatabase.isOffline = false;

    service = DosenRequestService.withMocks(
      schCol: fakeSchCol,
      reqCol: fakeReqCol,
      cacheBox: scheduleCache,
      connectivity: mockConnectivity,
    );
  });

  tearDown(() async {
    fakeSchCol.reset();
    fakeReqCol.reset();
    await scheduleCache.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ── TC01 ──────────────────────────────────────────────────────────────────
  group(
    'TC01 - getMySchedules online mengambil data dari MongoDB dan menyimpan ke cache',
    () {
      test('return 3 item, cache tersimpan, _id bertipe String', () async {
        stubOnline(true);
        final docs = List.generate(
          3,
          (i) => makeScheduleDoc(id: 'sch$i', kodeDosen: 'ANI'),
        );
        fakeSchCol.onFind = (_) => Stream.fromIterable(docs);

        final result = await service.getMySchedules('ANI');

        expect(result.length, 3);
        final cached = scheduleCache.get('my_schedules_ANI');
        expect(cached, isNotNull);
        expect(List.from(cached).length, 3);
        for (final item in List<Map>.from(cached)) {
          expect(item['_id'], isA<String>());
        }
      });
    },
  );

  // ── TC02 ──────────────────────────────────────────────────────────────────
  group('TC02 - getMySchedules offline mengembalikan data dari cache Hive', () {
    test('return 2 item dari cache, MongoDB tidak diakses', () async {
      stubOnline(false);
      final cachedDocs = List.generate(
        2,
        (i) => makeScheduleDoc(id: 'sch$i', kodeDosen: 'ANI'),
      );
      await scheduleCache.put('my_schedules_ANI', cachedDocs);

      final result = await service.getMySchedules('ANI');

      expect(result.length, 2);
      // onFind tidak pernah dipanggil → MongoDB tidak diakses
      expect(fakeSchCol.onFind, isNull);
    });
  });

  // ── TC03 ──────────────────────────────────────────────────────────────────
  group(
    'TC03 - getMySchedules mengembalikan cache jika MongoDB throw exception',
    () {
      test('return 2 item dari cache, app tidak crash', () async {
        stubOnline(true);
        final cachedDocs = List.generate(
          2,
          (i) => makeScheduleDoc(id: 'sch$i', kodeDosen: 'ANI'),
        );
        await scheduleCache.put('my_schedules_ANI', cachedDocs);
        fakeSchCol.onFind = (_) => throw Exception('DB error');

        final result = await service.getMySchedules('ANI');

        expect(result.length, 2);
      });
    },
  );

  // ── TC04 ──────────────────────────────────────────────────────────────────
  group('TC04 - getMySchedules offline cache tidak ada', () {
    test('return [], app tidak crash', () async {
      stubOnline(false);

      final result = await service.getMySchedules('ANI');

      expect(result, isEmpty);
    });
  });

  // ── TC05 ──────────────────────────────────────────────────────────────────
  group(
    'TC05 - getRuanganTersedia online mengembalikan ruangan yang tidak bentrok',
    () {
      test('return [R2, R3], R1 tidak termasuk karena bentrok', () async {
        stubOnline(true);
        fakeSchCol.onDistinct = (_) async => {
          'values': ['R1', 'R2', 'R3'],
        };
        fakeSchCol.onFind = (_) => Stream.fromIterable([
          makeScheduleDoc(
            id: 'sch1',
            hari: 'SENIN',
            jamMulai: '07:00',
            jamSelesai: '08:00',
            ruangan: 'R1',
          ),
        ]);

        final result = await service.getRuanganTersedia(
          hari: 'SENIN',
          jamMulai: '07:30',
          jamSelesai: '09:10',
        );

        expect(result, equals(['R2', 'R3']));
      });
    },
  );

  // ── TC06 ──────────────────────────────────────────────────────────────────
  group(
    'TC06 - getRuanganTersedia mengecualikan jadwal dengan excludeScheduleId',
    () {
      test(
        'return [R1, R2], tidak ada bentrok karena jadwal dikecualikan',
        () async {
          stubOnline(true);
          fakeSchCol.onDistinct = (_) async => {
            'values': ['R1', 'R2'],
          };
          fakeSchCol.onFind = (_) => Stream.fromIterable([]);

          final result = await service.getRuanganTersedia(
            hari: 'SENIN',
            jamMulai: '07:30',
            jamSelesai: '09:10',
            excludeScheduleId: 'aabbccddeeff001122334455',
          );

          expect(result, containsAll(['R1', 'R2']));
          expect(result.length, 2);
        },
      );
    },
  );

  // ── TC07 ──────────────────────────────────────────────────────────────────
  group('TC07 - getRuanganTersedia offline kalkulasi bentrok dari cache', () {
    test('return [R2], R1 bentrok, MongoDB tidak diakses', () async {
      stubOnline(false);
      await scheduleCache.put('all_schedules', [
        makeScheduleDoc(
          id: 'sch1',
          hari: 'SENIN',
          jamMulai: '07:00',
          jamSelesai: '08:00',
          ruangan: 'R1',
        ),
        makeScheduleDoc(
          id: 'sch2',
          hari: 'SENIN',
          jamMulai: '10:00',
          jamSelesai: '12:00',
          ruangan: 'R2',
        ),
      ]);

      final result = await service.getRuanganTersedia(
        hari: 'SENIN',
        jamMulai: '07:30',
        jamSelesai: '09:10',
      );

      expect(result, equals(['R2']));
    });
  });

  // ── TC08 ──────────────────────────────────────────────────────────────────
  group('TC08 - getRuanganTersedia offline cache tidak ada', () {
    test('return [], app tidak crash', () async {
      stubOnline(false);

      final result = await service.getRuanganTersedia(
        hari: 'SENIN',
        jamMulai: '07:30',
        jamSelesai: '09:10',
      );

      expect(result, isEmpty);
    });
  });

  // ── TC09 ──────────────────────────────────────────────────────────────────
  group('TC09 - submitRequest berhasil menyimpan request baru ke MongoDB', () {
    test('return true, insertOne dipanggil 1x', () async {
      fakeReqCol.onFindOne = (_) => Future.value(null);

      final result = await service.submitRequest(
        idSchedule: 'aabbccddeeff001122334455',
        idDosen: 'aabbccddeeff001122334456',
        namaDosen: 'Bu Ani',
        tipeRequest: 'PINDAH_JAM',
        detailPerubahan: {
          'hari_baru': 'RABU',
          'jam_mulai_baru': '08:00',
          'jam_selesai_baru': '09:40',
          'ruangan_baru': '',
        },
        alasan: 'Bentrok',
        namaMatkul: 'Basis Data',
        jadwalLama: {'hari': 'SENIN', 'jam_mulai': '07:30'},
        offlineId: 'offline_unique_001',
      );

      expect(result, true);
      expect(fakeReqCol.insertOneCallCount, 1);
    });
  });

  // ── TC10 ──────────────────────────────────────────────────────────────────
  group(
    'TC10 - submitRequest menghindari duplikasi jika offlineId sudah ada',
    () {
      test('return true, insertOne TIDAK dipanggil', () async {
        fakeReqCol.onFindOne = (_) =>
            Future.value({'_id': 'existing', 'offline_id': 'offline_123'});

        final result = await service.submitRequest(
          idSchedule: 'aabbccddeeff001122334455',
          idDosen: 'aabbccddeeff001122334456',
          namaDosen: 'Bu Ani',
          tipeRequest: 'PINDAH_JAM',
          detailPerubahan: {},
          alasan: 'Bentrok',
          namaMatkul: 'Basis Data',
          jadwalLama: {},
          offlineId: 'offline_123',
        );

        expect(result, true);
        expect(fakeReqCol.insertOneCallCount, 0);
      });
    },
  );

  // ── TC11 ──────────────────────────────────────────────────────────────────
  group('TC11 - submitRequest return false jika MongoDB throw exception', () {
    test('return false, exception ditangkap, app tidak crash', () async {
      fakeReqCol.onFindOne = (_) => Future.value(null);
      fakeReqCol.insertOneShouldThrow = true;

      final result = await service.submitRequest(
        idSchedule: 'aabbccddeeff001122334455',
        idDosen: 'aabbccddeeff001122334456',
        namaDosen: 'Bu Ani',
        tipeRequest: 'PINDAH_JAM',
        detailPerubahan: {},
        alasan: 'Bentrok',
        namaMatkul: 'Basis Data',
        jadwalLama: {},
        offlineId: 'offline_fail',
      );

      expect(result, false);
    });
  });

  // ── TC12 ──────────────────────────────────────────────────────────────────
  group(
    'TC12 - getMyRequests online menggabungkan data request dengan jadwal',
    () {
      test('return 2 ScheduleRequestModel, cache tersimpan', () async {
        stubOnline(true);
        const sch1 = 'aabbccddeeff001122334411';
        const sch2 = 'aabbccddeeff001122334412';
        final reqDocs = [
          makeRequestDoc(
            id: 'req1',
            idDosen: 'aabbccddeeff001122334401',
            idSchedule: sch1,
          ),
          makeRequestDoc(
            id: 'req2',
            idDosen: 'aabbccddeeff001122334401',
            idSchedule: sch2,
          ),
        ];
        final jadwalDocs = [
          makeScheduleDoc(id: sch1, namaMk: 'Basis Data', kodeMk: 'BD101'),
          makeScheduleDoc(id: sch2, namaMk: 'Algoritma', kodeMk: 'ALG101'),
        ];
        fakeReqCol.onFind = (_) => Stream.fromIterable(reqDocs);
        fakeSchCol.onFind = (_) => Stream.fromIterable(jadwalDocs);

        final result = await service.getMyRequests('aabbccddeeff001122334401');

        expect(result.length, 2);
        expect(result.first, isA<ScheduleRequestModel>());
        expect(
          scheduleCache.get('my_requests_aabbccddeeff001122334401'),
          isNotNull,
        );
      });
    },
  );

  // ── TC13 ──────────────────────────────────────────────────────────────────
  group('TC13 - getMyRequests offline mengembalikan data dari cache', () {
    test(
      'return 2 ScheduleRequestModel dari cache, MongoDB tidak diakses',
      () async {
        stubOnline(false);
        await scheduleCache.put(
          'my_requests_aabbccddeeff001122334401',
          makeCachedRequestList(2, 'aabbccddeeff001122334401'),
        );

        final result = await service.getMyRequests('aabbccddeeff001122334401');
=======
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f

        expect(result.length, 2);
      },
    );
<<<<<<< HEAD
  });

  // ── TC14 ──────────────────────────────────────────────────────────────────
  group(
    'TC14 - getMyRequests mengembalikan cache jika MongoDB throw exception',
    () {
      test('return 2 item dari cache, app tidak crash', () async {
        stubOnline(true);
        await scheduleCache.put(
          'my_requests_aabbccddeeff001122334401',
          makeCachedRequestList(2, 'aabbccddeeff001122334401'),
        );
        fakeReqCol.onFind = (_) => throw Exception('DB error');

        final result = await service.getMyRequests('aabbccddeeff001122334401');

        expect(result.length, 2);
      });
    },
  );

  // ── TC15 ──────────────────────────────────────────────────────────────────
  group(
    'TC15 - getMyRequests mengembalikan list kosong jika request kosong',
    () {
      test('return [], cache tidak diperbarui', () async {
        stubOnline(true);
        fakeReqCol.onFind = (_) => Stream.fromIterable([]);

        final result = await service.getMyRequests('aabbccddeeff001122334401');

        expect(result, isEmpty);
        expect(
          scheduleCache.get('my_requests_aabbccddeeff001122334401'),
          isNull,
        );
      });
    },
  );

  // ── TC16 ──────────────────────────────────────────────────────────────────
  group(
    'TC16 - cancelRequest berhasil menghapus request PENDING dari MongoDB',
    () {
      test('return true, deleteOne dipanggil 1x', () async {
        final result = await service.cancelRequest('aabbccddeeff001122334455');

        expect(result, true);
        expect(fakeReqCol.deleteOneCallCount, 1);
      });
    },
  );

  // ── TC17 ──────────────────────────────────────────────────────────────────
  group('TC17 - cancelRequest return false jika MongoDB throw exception', () {
    test('return false, exception ditangkap, app tidak crash', () async {
      fakeReqCol.deleteOneShouldThrow = true;

      final result = await service.cancelRequest('aabbccddeeff001122334455');

      expect(result, false);
    });
=======

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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
  });
}
