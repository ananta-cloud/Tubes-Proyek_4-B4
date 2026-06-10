<<<<<<< HEAD
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mongo_dart/mongo_dart.dart';
// import 'package:hive/hive.dart';
// import 'package:hive_test/hive_test.dart';
// import 'package:sigma/core/network/mongo_database.dart';
// import 'package:sigma/data/services/schedule_request_service.dart';
// import 'package:sigma/data/models/schedule_request_model.dart';

// // ── Fake WriteResult ──────────────────────────────────────
// class FakeWriteResult implements WriteResult {
//   final bool _success;
//   FakeWriteResult(this._success);
//   @override
//   bool get isSuccess => _success;
//   @override
//   dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
// }

// // ── Fake DbCollection ─────────────────────────────────────
// // Semua method return nilai default aman; test override via callback.
// class FakeDbCollection implements DbCollection {
//   Stream<Map<String, dynamic>> Function(dynamic)? onFind;
//   Future<WriteResult> Function(dynamic, dynamic)? onUpdateOne;
//   Future<int> Function(dynamic)? onCount;
//   Future<Map<String, dynamic>?> Function(dynamic)? onFindOne;

//   @override
//   Stream<Map<String, dynamic>> find([dynamic selector]) {
//     if (onFind != null) return onFind!(selector);
//     return const Stream.empty();
//   }

//   @override
//   Future<WriteResult> updateOne(
//     dynamic selector,
//     dynamic update, {
//     dynamic writeConcern,
//     dynamic collectionSafe,
//   }) async {
//     if (onUpdateOne != null) return onUpdateOne!(selector, update);
//     return FakeWriteResult(false);
//   }

//   @override
//   Future<int> count([dynamic selector]) async {
//     if (onCount != null) return onCount!(selector);
//     return 0;
//   }

//   @override
//   Future<Map<String, dynamic>?> findOne([dynamic selector]) async {
//     if (onFindOne != null) return onFindOne!(selector);
//     return null;
//   }

//   @override
//   dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
// }

// // ── Helpers ───────────────────────────────────────────────

// Map<String, dynamic> _fakeDosen(String kode, String jurusanId) => {
//   '_id': ObjectId(),
//   'kode_dosen': kode,
//   'id_jurusan': ObjectId.fromHexString(jurusanId),
// };

// Map<String, dynamic> _fakeJadwal(ObjectId id, String kodeDosen) => {
//   '_id': id,
//   'kode_dosen': kodeDosen,
//   'nama_matkul': 'Algoritma',
//   'hari': 'Senin',
//   'jam_mulai': '08:00',
//   'jam_selesai': '10:00',
//   'ruangan': 'R101',
//   'kelas': 'A',
// };

// // Semua value primitif/String — aman untuk Hive cache
// Map<String, dynamic> _fakeRequest(String scheduleId, String dosenId) => {
//   '_id': ObjectId().toHexString(),
//   'id_schedule': scheduleId,
//   'id_dosen': dosenId,
//   'tipe_request': 'RESCHEDULE',
//   'detail_perubahan': {
//     'hari_baru': 'Selasa',
//     'jam_mulai_baru': '10:00',
//     'jam_selesai_baru': '12:00',
//     'ruangan_baru': 'R202',
//   },
//   'alasan': 'Bentrok',
//   'status': 'PENDING',
//   'offline_id': null,
//   'catatan_admin': null,
//   'id_processor': null,
//   'is_late': false,
//   'created_at': DateTime.now().toIso8601String(),
//   'updated_at': DateTime.now().toIso8601String(),
// };

// ScheduleRequestModel _fakeSRM() {
//   final schId = ObjectId();
//   return ScheduleRequestModel.fromJson(
//     _fakeRequest(schId.toHexString(), ObjectId().toHexString()),
//     jadwal: _fakeJadwal(schId, 'ANI'),
//   );
// }

// Future<void> _seedCache(String key, List<Map<String, dynamic>> items) async {
//   final box = Hive.box<Map>('tpj_requests_cache');
//   await box.put(key, {
//     'data': items,
//     'cachedAt': DateTime.now().toIso8601String(),
//   });
// }

// Future<void> _seedQueue(List<Map<String, dynamic>> actions) async {
//   final box = Hive.box<Map>('tpj_action_queue');
//   for (final a in actions) {
//     await box.add(a);
//   }
// }

// // ── Buat service + fake collections baru setiap test ──────
// ({
//   ScheduleRequestService service,
//   FakeDbCollection req,
//   FakeDbCollection sch,
//   FakeDbCollection dosen,
// })
// _makeService() {
//   final req = FakeDbCollection();
//   final sch = FakeDbCollection();
//   final dosen = FakeDbCollection();
//   final svc = ScheduleRequestService();
//   svc.onEnsureConnected = () async {};
//   svc.injectCollections(reqCol: req, schCol: sch, dosenCol: dosen);
//   return (service: svc, req: req, sch: sch, dosen: dosen);
// }

// void main() {
//   setUpAll(() async {
//     await setUpTestHive();
//   });

//   tearDownAll(() async {
//     await tearDownTestHive();
//   });

//   setUp(() async {
//     await Hive.openBox<Map>('tpj_requests_cache');
//     await Hive.openBox<Map>('tpj_action_queue');
//     await Hive.box<Map>('tpj_requests_cache').clear();
//     await Hive.box<Map>('tpj_action_queue').clear();
//   });

//   // ─────────────────────────────────────────
//   // getRequests()
//   // ─────────────────────────────────────────

//   group('getRequests()', () {
//     const jurusanId = '64b0000000000000000000a1';

//     test('TC01 - online berhasil gabungkan data jadwal', () async {
//       final d1 = _fakeDosen('ANI', jurusanId);
//       final d2 = _fakeDosen('BUD', jurusanId);
//       final schId1 = ObjectId();
//       final schId2 = ObjectId();
//       final jadwals = [
//         _fakeJadwal(schId1, 'ANI'),
//         _fakeJadwal(schId2, 'BUD'),
//         _fakeJadwal(ObjectId(), 'ANI'),
//       ];
//       final requests = [
//         _fakeRequest(
//           schId1.toHexString(),
//           (d1['_id'] as ObjectId).toHexString(),
//         ),
//         _fakeRequest(
//           schId2.toHexString(),
//           (d2['_id'] as ObjectId).toHexString(),
//         ),
//       ];

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) => Stream.fromIterable([d1, d2]);
//       env.sch.onFind = (_) => Stream.fromIterable(jadwals);
//       env.req.onFind = (_) => Stream.fromIterable(requests);

//       final result = await env.service.getRequests(idJurusan: jurusanId);

//       expect(result.length, 2);
//       expect(result.first.hariJadwal, isNotNull);
//       expect(
//         Hive.box<Map>('tpj_requests_cache').get('${jurusanId}_SEMUA'),
//         isNotNull,
//       );
//     });

//     test('TC02 - filter status PENDING hanya return 1 item', () async {
//       final d = _fakeDosen('ANI', jurusanId);
//       final schId = ObjectId();
//       var findCallCount = 0;

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) => Stream.fromIterable([d]);
//       env.sch.onFind = (_) => Stream.fromIterable([_fakeJadwal(schId, 'ANI')]);
//       env.req.onFind = (_) {
//         findCallCount++;
//         return Stream.fromIterable([
//           {
//             ..._fakeRequest(
//               schId.toHexString(),
//               (d['_id'] as ObjectId).toHexString(),
//             ),
//             'status': 'PENDING',
//           },
//         ]);
//       };

//       final result = await env.service.getRequests(
//         idJurusan: jurusanId,
//         status: 'PENDING',
//       );

//       expect(result.length, 1);
//       expect(findCallCount, 1);
//     });

//     test('TC03 - offline setelah retry → return cache', () async {
//       await _seedCache('${jurusanId}_SEMUA', [
//         _fakeRequest(ObjectId().toHexString(), ObjectId().toHexString()),
//         _fakeRequest(ObjectId().toHexString(), ObjectId().toHexString()),
//       ]);

//       MongoDatabase.isOffline = true;
//       final env = _makeService();
//       env.service.onEnsureConnected = () async => throw Exception('timeout');
//       var findCalled = false;
//       env.req.onFind = (_) {
//         findCalled = true;
//         return const Stream.empty();
//       };

//       final result = await env.service.getRequests(idJurusan: jurusanId);

//       expect(result.length, 2);
//       expect(findCalled, false);
//     });

//     test('TC04 - dosen kosong → return cache', () async {
//       await _seedCache('${jurusanId}_SEMUA', [
//         _fakeRequest(ObjectId().toHexString(), ObjectId().toHexString()),
//       ]);

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) => Stream.fromIterable([]);
//       var reqFindCalled = false;
//       env.req.onFind = (_) {
//         reqFindCalled = true;
//         return const Stream.empty();
//       };

//       final result = await env.service.getRequests(idJurusan: jurusanId);

//       expect(result.length, 1);
//       expect(reqFindCalled, false);
//     });

//     test('TC05 - schedules kosong → return cache', () async {
//       await _seedCache('${jurusanId}_SEMUA', [
//         _fakeRequest(ObjectId().toHexString(), ObjectId().toHexString()),
//       ]);

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) =>
//           Stream.fromIterable([_fakeDosen('ANI', jurusanId)]);
//       env.sch.onFind = (_) => Stream.fromIterable([]);
//       var reqFindCalled = false;
//       env.req.onFind = (_) {
//         reqFindCalled = true;
//         return const Stream.empty();
//       };

//       final result = await env.service.getRequests(idJurusan: jurusanId);

//       expect(result.length, 1);
//       expect(reqFindCalled, false);
//     });

//     test('TC06 - MongoDB throw exception → return cache', () async {
//       await _seedCache('${jurusanId}_SEMUA', [
//         _fakeRequest(ObjectId().toHexString(), ObjectId().toHexString()),
//         _fakeRequest(ObjectId().toHexString(), ObjectId().toHexString()),
//       ]);

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) => throw Exception('DB error');

//       final result = await env.service.getRequests(idJurusan: jurusanId);

//       expect(result.length, 2);
//     });
//   });

//   // ─────────────────────────────────────────
//   // getStats()
//   // ─────────────────────────────────────────

//   group('getStats()', () {
//     const jurusanId = '64b0000000000000000000a1';

//     test('TC07 - return jumlah per status dengan benar', () async {
//       final schId = ObjectId();
//       var countCall = 0;

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) => Stream.fromIterable([
//         _fakeDosen('ANI', jurusanId),
//         _fakeDosen('BUD', jurusanId),
//       ]);
//       env.sch.onFind = (_) => Stream.fromIterable([_fakeJadwal(schId, 'ANI')]);
//       env.req.onCount = (_) async {
//         countCall++;
//         if (countCall == 1) return 3; // PENDING
//         if (countCall == 2) return 2; // APPROVED
//         return 1; // REJECTED
//       };

//       final result = await env.service.getStats(jurusanId);

//       expect(result['pending'], 3);
//       expect(result['approved'], 2);
//       expect(result['rejected'], 1);
//     });

//     test('TC08 - dosen kosong → return semua 0', () async {
//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) => Stream.fromIterable([]);

//       final result = await env.service.getStats(jurusanId);

//       expect(result, {'pending': 0, 'approved': 0, 'rejected': 0});
//     });

//     test('TC09 - dosen.find() throw exception → return semua 0', () async {
//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.dosen.onFind = (_) => throw Exception('DB error');

//       final result = await env.service.getStats(jurusanId);

//       expect(result, {'pending': 0, 'approved': 0, 'rejected': 0});
//     });
//   });

//   // ─────────────────────────────────────────
//   // approveRequest()
//   // ─────────────────────────────────────────

//   group('approveRequest()', () {
//     const requestId = '64b0000000000000000000b1';
//     const processorId = '64b0000000000000000000c1';

//     test('TC10 - online update status APPROVED dan update jadwal', () async {
//       var reqUpdateCount = 0;
//       var schUpdateCount = 0;

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async {
//         reqUpdateCount++;
//         return FakeWriteResult(true);
//       };
//       env.sch.onUpdateOne = (_, __) async {
//         schUpdateCount++;
//         return FakeWriteResult(true);
//       };

//       final result = await env.service.approveRequest(
//         requestId: requestId,
//         processorId: processorId,
//         request: _fakeSRM(),
//       );

//       expect(result, true);
//       expect(reqUpdateCount, 1);
//       expect(schUpdateCount, 1);
//     });

//     test('TC11 - offline → masuk queue, tidak panggil MongoDB', () async {
//       MongoDatabase.isOffline = true;
//       var updateCalled = false;

//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async {
//         updateCalled = true;
//         return FakeWriteResult(true);
//       };

//       final result = await env.service.approveRequest(
//         requestId: requestId,
//         processorId: processorId,
//         request: _fakeSRM(),
//       );

//       expect(result, true);
//       final queue = Hive.box<Map>('tpj_action_queue');
//       expect(queue.length, 1);
//       expect(queue.values.first['type'], 'APPROVE');
//       expect(updateCalled, false);
//     });

//     test('TC12 - _reqCol.updateOne() throw exception → return false', () async {
//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async => throw Exception('DB error');

//       final result = await env.service.approveRequest(
//         requestId: requestId,
//         processorId: processorId,
//         request: _fakeSRM(),
//       );

//       expect(result, false);
//     });
//   });

//   // ─────────────────────────────────────────
//   // rejectRequest()
//   // ─────────────────────────────────────────

//   group('rejectRequest()', () {
//     const requestId = '64b0000000000000000000b1';
//     const processorId = '64b0000000000000000000c1';

//     test('TC13 - online update status REJECTED', () async {
//       var updateCount = 0;

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async {
//         updateCount++;
//         return FakeWriteResult(true);
//       };

//       final result = await env.service.rejectRequest(
//         requestId: requestId,
//         processorId: processorId,
//         catatanAdmin: 'Jadwal penuh',
//       );

//       expect(result, true);
//       expect(updateCount, 1);
//     });

//     test('TC14 - offline → masuk queue, tidak panggil MongoDB', () async {
//       MongoDatabase.isOffline = true;
//       var updateCalled = false;

//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async {
//         updateCalled = true;
//         return FakeWriteResult(true);
//       };

//       final result = await env.service.rejectRequest(
//         requestId: requestId,
//         processorId: processorId,
//         catatanAdmin: 'Alasan',
//       );

//       expect(result, true);
//       final queue = Hive.box<Map>('tpj_action_queue');
//       expect(queue.length, 1);
//       expect(queue.values.first['type'], 'REJECT');
//       expect(updateCalled, false);
//     });

//     test('TC15 - _reqCol.updateOne() throw exception → return false', () async {
//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async => throw Exception('DB error');

//       final result = await env.service.rejectRequest(
//         requestId: requestId,
//         processorId: processorId,
//         catatanAdmin: 'Alasan',
//       );

//       expect(result, false);
//     });
//   });

//   // ─────────────────────────────────────────
//   // flushQueue()
//   // ─────────────────────────────────────────

//   group('flushQueue()', () {
//     const requestId = '64b0000000000000000000b1';
//     const processorId = '64b0000000000000000000c1';

//     test('TC16 - proses 1 APPROVE + 1 REJECT → return 2', () async {
//       await _seedQueue([
//         {
//           'type': 'APPROVE',
//           'requestId': requestId,
//           'processorId': processorId,
//           'catatanAdmin': null,
//           'requestJson': {
//             '_id': ObjectId().toHexString(),
//             'id_schedule': ObjectId().toHexString(),
//             'id_dosen': ObjectId().toHexString(),
//             'nama_dosen': 'Dosen A',
//             'tipe_request': 'RESCHEDULE',
//             'detail_perubahan': {
//               'hari_baru': 'Selasa',
//               'jam_mulai_baru': '10:00',
//               'jam_selesai_baru': '12:00',
//               'ruangan_baru': 'R202',
//             },
//             'alasan': 'Bentrok',
//             'status': 'PENDING',
//             'offline_id': null,
//             'catatan_admin': null,
//             'id_processor': null,
//             'is_late': false,
//             'created_at': DateTime.now().toIso8601String(),
//             'updated_at': DateTime.now().toIso8601String(),
//             'nama_matkul': 'Algoritma',
//             'nama_mk': 'Algoritma',
//             'kode_mk': 'TI101',
//             'hari': 'Senin',
//             'jam_mulai': '08:00',
//             'jam_selesai': '10:00',
//             'ruangan': 'R101',
//             'kelas': 'A',
//           },
//           'queuedAt': DateTime.now().toIso8601String(),
//         },
//         {
//           'type': 'REJECT',
//           'requestId': requestId,
//           'processorId': processorId,
//           'catatanAdmin': 'Tolak',
//           'queuedAt': DateTime.now().toIso8601String(),
//         },
//       ]);

//       var reqUpdateCount = 0;

//       MongoDatabase.isOffline = false;
//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async {
//         reqUpdateCount++;
//         return FakeWriteResult(true);
//       };
//       env.sch.onUpdateOne = (_, __) async => FakeWriteResult(true);

//       final synced = await env.service.flushQueue();

//       expect(synced, 2);
//       expect(Hive.box<Map>('tpj_action_queue').isEmpty, true);
//       expect(reqUpdateCount, 2);
//     });

//     test('TC17 - queue kosong → return 0', () async {
//       var updateCalled = false;

//       final env = _makeService();
//       env.req.onUpdateOne = (_, __) async {
//         updateCalled = true;
//         return FakeWriteResult(true);
//       };

//       final synced = await env.service.flushQueue();

//       expect(synced, 0);
//       expect(updateCalled, false);
//     });

//     test(
//       'TC18 - aksi pertama throw exception, kedua sukses → return 1',
//       () async {
//         await _seedQueue([
//           {
//             'type': 'REJECT',
//             'requestId': '64b0000000000000000000b1',
//             'processorId': processorId,
//             'catatanAdmin': 'Alasan 1',
//             'queuedAt': DateTime.now().toIso8601String(),
//           },
//           {
//             'type': 'REJECT',
//             'requestId': '64b0000000000000000000b2',
//             'processorId': processorId,
//             'catatanAdmin': 'Alasan 2',
//             'queuedAt': DateTime.now().toIso8601String(),
//           },
//         ]);

//         var callCount = 0;
//         MongoDatabase.isOffline = false;
//         final env = _makeService();
//         env.req.onUpdateOne = (_, __) async {
//           callCount++;
//           if (callCount == 1) throw Exception('DB error');
//           return FakeWriteResult(true);
//         };

//         final synced = await env.service.flushQueue();

//         expect(synced, 1);
//         expect(Hive.box<Map>('tpj_action_queue').isEmpty, true);
//       },
//     );
//   });
// }
=======
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/schedule_request_service.dart';

import 'schedule_request_service_test.mocks.dart';

// Fake class untuk mengakali return type WriteResult dari mongo_dart
class FakeWriteResult extends Fake implements WriteResult {}

@GenerateMocks([Db, DbCollection])
void main() {
  late ScheduleRequestService service;
  late MockDb mockDb;
  late MockDbCollection mockReqCol;
  late MockDbCollection mockSchCol;
  late MockDbCollection mockDosenCol;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(
      envString: 'MONGO_URL=mongodb://localhost:27017/fake_db_test',
    );
  });

  setUp(() async {
    // 1. Setup Hive
    tempDir = await Directory.systemTemp.createTemp('hive_tpj_service_test_');
    Hive.init(tempDir.path);
    await ScheduleRequestService.openBoxes();

    // 2. Setup Mock
    mockDb = MockDb();
    mockReqCol = MockDbCollection();
    mockSchCol = MockDbCollection();
    mockDosenCol = MockDbCollection();

    when(mockDb.collection('schedule_requests')).thenReturn(mockReqCol);
    when(mockDb.collection('schedules')).thenReturn(mockSchCol);
    when(mockDb.collection('dosen')).thenReturn(mockDosenCol);

    MongoDatabase.db = mockDb;
    MongoDatabase.isOffline = false;

    service = ScheduleRequestService();
    service.onEnsureConnected = () async {};
  });

  tearDown(() async {
    await Hive.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  ScheduleRequestModel generateMockRequest(String id, String tipe) {
    return ScheduleRequestModel(
      id: id,
      idSchedule: ObjectId().toHexString(),
      idDosen: 'dos1',
      namaDosen: 'Dosen A',
      tipeRequest: tipe,
      detailPerubahan: DetailPerubahan(ruanganBaru: 'Aero-01'),
      alasan: 'Rapat',
      status: 'PENDING',
    );
  }

  // ===========================================================================
  // MODUL: getRequests()
  // ===========================================================================
  group('getRequests() - Skenario Pengujian', () {
    test(
      'TC01 - getRequests online berhasil mengambil request dan menggabungkan data jadwal',
      () async {
        MongoDatabase.isOffline = false;

        final idJurusanHex = ObjectId().toHexString();

        when(mockDosenCol.find(any)).thenAnswer(
          (invocation) => Stream.fromIterable([
            {'_id': ObjectId(), 'kode_dosen': 'DOS01'},
          ]),
        );

        final schId = ObjectId();
        when(mockSchCol.find(any)).thenAnswer(
          (invocation) => Stream.fromIterable([
            {'_id': schId, 'kode_dosen': 'DOS01', 'nama_mk': 'Aerodinamika'},
          ]),
        );

        when(mockReqCol.find(any)).thenAnswer(
          (invocation) => Stream.fromIterable([
            {
              '_id': ObjectId(),
              'id_schedule': schId,
              'status': 'PENDING',
              'detail_perubahan': {},
            },
          ]),
        );

        final result = await service.getRequests(idJurusan: idJurusanHex);

        expect(result.length, 1);
        expect(result.first.status, 'PENDING');
        expect(result.first.namaMk, 'Aerodinamika');
      },
    );

    test(
      'TC02 - getRequests offline / exception membaca dari cache Hive',
      () async {
        MongoDatabase.isOffline = true;

        final cacheBox = Hive.box<Map>('tpj_requests_cache');
        cacheBox.put('JURUSAN1_SEMUA', {
          'data': [
            {
              '_id': 'req1',
              'status': 'APPROVED',
              'detail_perubahan': {},
              'nama_mk': 'Propulsi',
            },
          ],
        });

        final result = await service.getRequests(idJurusan: 'JURUSAN1');

        expect(result.length, 1);
        expect(result.first.status, 'APPROVED');
        expect(result.first.namaMk, 'Propulsi');
      },
    );

    test(
      'TC03 - getRequests mengembalikan cache/kosong jika tidak ada dosen di jurusan tersebut',
      () async {
        MongoDatabase.isOffline = false;
        when(
          mockDosenCol.find(any),
        ).thenAnswer((invocation) => Stream.fromIterable([]));

        final result = await service.getRequests(
          idJurusan: ObjectId().toHexString(),
        );

        expect(result, isEmpty);
      },
    );
  });

  // ===========================================================================
  // MODUL: getRequestById()
  // ===========================================================================
  group('getRequestById() - Skenario Pengujian', () {
    test(
      'TC04 - getRequestById berhasil memuat 1 request beserta jadwalnya',
      () async {
        final reqId = ObjectId();
        final schId = ObjectId();

        when(mockReqCol.findOne(any)).thenAnswer(
          (invocation) async => {
            '_id': reqId,
            'id_schedule': schId,
            'detail_perubahan': {},
          },
        );
        when(mockSchCol.findOne(any)).thenAnswer(
          (invocation) async => {'_id': schId, 'nama_mk': 'Struktur Pesawat'},
        );

        final result = await service.getRequestById(reqId.toHexString());

        expect(result, isNotNull);
        expect(result!.namaMk, 'Struktur Pesawat');
      },
    );

    test(
      'TC05 - getRequestById mengembalikan null jika ID tidak ditemukan',
      () async {
        when(mockReqCol.findOne(any)).thenAnswer((invocation) async => null);

        final result = await service.getRequestById(ObjectId().toHexString());

        expect(result, isNull);
      },
    );
  });

  // ===========================================================================
  // MODUL: getStats()
  // ===========================================================================
  group('getStats() - Skenario Pengujian', () {
    test(
      'TC06 - getStats berhasil mengembalikan hitungan pending, approved, dan rejected',
      () async {
        when(mockDosenCol.find(any)).thenAnswer(
          (invocation) => Stream.fromIterable([
            {'kode_dosen': 'DOS01'},
          ]),
        );
        when(mockSchCol.find(any)).thenAnswer(
          (invocation) => Stream.fromIterable([
            {'_id': ObjectId(), 'kode_dosen': 'DOS01'},
          ]),
        );

        int callCount = 0;
        when(mockReqCol.count(any)).thenAnswer((invocation) async {
          callCount++;
          if (callCount == 1) return 5; // PENDING
          if (callCount == 2) return 3; // APPROVED
          return 1; // REJECTED
        });

        final stats = await service.getStats(ObjectId().toHexString());

        expect(stats['pending'], 5);
        expect(stats['approved'], 3);
        expect(stats['rejected'], 1);
      },
    );

    test(
      'TC07 - getStats mengembalikan 0 jika koneksi gagal atau data tidak ditemukan',
      () async {
        when(mockDosenCol.find(any)).thenThrow(Exception('DB Error'));

        final stats = await service.getStats(ObjectId().toHexString());

        expect(stats['pending'], 0);
        expect(stats['approved'], 0);
        expect(stats['rejected'], 0);
      },
    );
  });

  // ===========================================================================
  // MODUL: Approve / Reject (Online & Offline)
  // ===========================================================================
  group('approveRequest() & rejectRequest() - Skenario Pengujian', () {
    test(
      'TC08 - approveRequest OFFLINE menyimpan aksi ke queue (tpj_action_queue)',
      () async {
        MongoDatabase.isOffline = true;
        final dummyReq = generateMockRequest('req1', 'PINDAH_RUANGAN');

        final result = await service.approveRequest(
          requestId: 'req1',
          processorId: 'proc1',
          request: dummyReq,
        );

        expect(result, true);

        final queue = Hive.box<Map>('tpj_action_queue').values.toList();
        expect(queue.length, 1);
        expect(queue.first['type'], 'APPROVE');
        expect(queue.first['requestId'], 'req1');
      },
    );

    test(
      'TC09 - approveRequest ONLINE memanggil updateOne pada reqCol dan schCol',
      () async {
        MongoDatabase.isOffline = false;
        final dummyReq = generateMockRequest(
          ObjectId().toHexString(),
          'PINDAH_RUANGAN',
        );

        when(
          mockReqCol.updateOne(any, any),
        ).thenAnswer((invocation) async => FakeWriteResult());
        when(
          mockSchCol.updateOne(any, any),
        ).thenAnswer((invocation) async => FakeWriteResult());

        final result = await service.approveRequest(
          requestId: ObjectId().toHexString(),
          processorId: ObjectId().toHexString(),
          request: dummyReq,
        );

        expect(result, true);
        verify(mockReqCol.updateOne(any, any)).called(1);
        verify(mockSchCol.updateOne(any, any)).called(1);
      },
    );

    test('TC10 - rejectRequest OFFLINE menyimpan aksi ke queue', () async {
      MongoDatabase.isOffline = true;

      final result = await service.rejectRequest(
        requestId: 'req2',
        processorId: 'proc1',
        catatanAdmin: 'Ditolak',
      );

      expect(result, true);

      final queue = Hive.box<Map>('tpj_action_queue').values.toList();
      expect(queue.length, 1);
      expect(queue.first['type'], 'REJECT');
      expect(queue.first['catatanAdmin'], 'Ditolak');
    });

    test(
      'TC11 - rejectRequest ONLINE hanya memanggil updateOne pada reqCol',
      () async {
        MongoDatabase.isOffline = false;

        when(
          mockReqCol.updateOne(any, any),
        ).thenAnswer((invocation) async => FakeWriteResult());

        final result = await service.rejectRequest(
          requestId: ObjectId().toHexString(),
          processorId: ObjectId().toHexString(),
          catatanAdmin: 'Tidak bisa',
        );

        expect(result, true);
        verify(mockReqCol.updateOne(any, any)).called(1);
        verifyNever(mockSchCol.updateOne(any, any));
      },
    );
  });

  // ===========================================================================
  // MODUL: flushQueue() (Sinkronisasi Background)
  // ===========================================================================
  group('flushQueue() - Skenario Pengujian', () {
    test('TC12 - flushQueue mengembalikan 0 jika queue kosong', () async {
      final result = await service.flushQueue();
      expect(result, 0);
    });

    test(
      'TC13 - flushQueue memproses semua item queue (APPROVE dan REJECT)',
      () async {
        final queueBox = Hive.box<Map>('tpj_action_queue');
        final dummyReq = generateMockRequest(
          ObjectId().toHexString(),
          'KEDUANYA',
        );

        queueBox.add({
          'type': 'APPROVE',
          'requestId': ObjectId().toHexString(),
          'processorId': ObjectId().toHexString(),
          'catatanAdmin': null,
          'requestJson': service.modelToMapTestWrapper(dummyReq),
        });
        queueBox.add({
          'type': 'REJECT',
          'requestId': ObjectId().toHexString(),
          'processorId': ObjectId().toHexString(),
          'catatanAdmin': 'Y',
        });

        when(
          mockReqCol.updateOne(any, any),
        ).thenAnswer((invocation) async => FakeWriteResult());
        when(
          mockSchCol.updateOne(any, any),
        ).thenAnswer((invocation) async => FakeWriteResult());

        final syncedCount = await service.flushQueue();

        expect(syncedCount, 2);
        expect(queueBox.isEmpty, true);
        verify(mockReqCol.updateOne(any, any)).called(2);
        verify(mockSchCol.updateOne(any, any)).called(1);
      },
    );

    test(
      'TC14 - flushQueue tetap melanjutkan memproses antrean lain meskipun salah satu gagal',
      () async {
        final queueBox = Hive.box<Map>('tpj_action_queue');

        queueBox.add({
          'type': 'REJECT',
          'requestId': ObjectId().toHexString(),
          'processorId': ObjectId().toHexString(),
          'catatanAdmin': 'X',
        });
        queueBox.add({
          'type': 'REJECT',
          'requestId': ObjectId().toHexString(),
          'processorId': ObjectId().toHexString(),
          'catatanAdmin': 'Y',
        });

        int callCount = 0;
        when(mockReqCol.updateOne(any, any)).thenAnswer((invocation) async {
          callCount++;
          if (callCount == 1) throw Exception('Simulasi Error MongoDB');
          return FakeWriteResult();
        });

        final syncedCount = await service.flushQueue();

        expect(syncedCount, 1);
        expect(queueBox.isEmpty, true);
      },
    );
  });
}

extension TestWrapper on ScheduleRequestService {
  Map<String, dynamic> modelToMapTestWrapper(ScheduleRequestModel r) {
    return {
      '_id': r.id,
      'id_schedule': r.idSchedule,
      'id_dosen': r.idDosen,
      'nama_dosen': r.namaDosen,
      'tipe_request': r.tipeRequest,
      'detail_perubahan': r.detailPerubahan.toJson(),
      'alasan': r.alasan,
      'status': r.status,
    };
  }
}
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
