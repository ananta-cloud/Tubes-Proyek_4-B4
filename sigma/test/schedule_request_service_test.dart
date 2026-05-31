import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

// Sesuaikan path import dengan struktur proyek Anda
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

  setUp(() async {
    // 1. Setup Hive (Cache & Queue Box)
    tempDir = await Directory.systemTemp.createTemp('hive_tpj_service_test_');
    Hive.init(tempDir.path);
    await ScheduleRequestService.openBoxes();

    // 2. Setup Mock Database & Collections
    mockDb = MockDb();
    mockReqCol = MockDbCollection();
    mockSchCol = MockDbCollection();
    mockDosenCol = MockDbCollection();

    when(mockDb.collection('schedule_requests')).thenReturn(mockReqCol);
    when(mockDb.collection('schedules')).thenReturn(mockSchCol);
    when(mockDb.collection('dosen')).thenReturn(mockDosenCol);

    // Injeksi mock ke dalam statik property MongoDatabase
    MongoDatabase.db = mockDb;
    MongoDatabase.isOffline = false; // Default online

    service = ScheduleRequestService();
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
      idSchedule: 'sch1',
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

        // 🔥 PERBAIKAN: Hapus parameter `_` pada callback pencarian Stream jika melempar error positional
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
          'requestJson': service.modelToMapTestWrapper(dummyReq),
        });
        queueBox.add({
          'type': 'REJECT',
          'requestId': ObjectId().toHexString(),
          'processorId': ObjectId().toHexString(),
          'catatanAdmin': 'Tolak',
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
          'requestId': 'r1',
          'processorId': 'p1',
          'catatanAdmin': 'X',
        });
        queueBox.add({
          'type': 'REJECT',
          'requestId': 'r2',
          'processorId': 'p2',
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
