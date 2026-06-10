import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/schedule_request_service.dart';
import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/features/penjadwalan/viewmodels/schedule_request_controller.dart';

import 'schedule_request_controller_test.mocks.dart';

@GenerateMocks([ScheduleRequestService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockScheduleRequestService mockService;
  late ScheduleRequestController controller;
  late Directory tempDir;
  late Box<Map> cacheBox;
  late Box<Map> queueBox;

  // ── Helper ──────────────────────────────────────────────────────────────
  ScheduleRequestModel makeModel({
    String id = 'req1',
    String status = 'PENDING',
  }) {
    final m = {
      '_id': id,
      'id_schedule': 'sch1',
      'id_dosen': 'dos1',
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
      'nama_mk': 'Basis Data',
      'kode_mk': 'BD101',
      'status': status,
      'offline_id': null,
      'catatan_admin': null,
      'id_processor': null,
      'is_late': false,
      'created_at': null,
      'updated_at': null,
      'hari': 'SENIN',
      'jam_mulai': '07:30',
      'jam_selesai': '09:10',
      'ruangan': 'Lab A',
      'kelas': 'A',
    };
    return ScheduleRequestModel.fromJson(m, jadwal: m);
  }

  // stub loadRequests helper
  void stubLoadRequests({
    String idJurusan = 'J01',
    String? status,
    List<ScheduleRequestModel>? items,
    Map<String, int>? stats,
  }) {
    when(
      mockService.getRequests(idJurusan: idJurusan, status: status),
    ).thenAnswer((_) async => items ?? []);
    when(mockService.getStats(idJurusan)).thenAnswer(
      (_) async => stats ?? {'pending': 0, 'approved': 0, 'rejected': 0},
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_src_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(DetailPerubahanAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(ScheduleRequestModelAdapter());

    cacheBox = await Hive.openBox<Map>('tpj_requests_cache');
    queueBox = await Hive.openBox<Map>('tpj_action_queue');

    MongoDatabase.isOffline = false;
    mockService = MockScheduleRequestService();
    controller = ScheduleRequestController(mockService);
  });

  tearDown(() async {
    await cacheBox.close();
    await queueBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ── TC01 ─────────────────────────────────────────────────────────────────
  group('TC01 - loadRequests berhasil memuat daftar request dari service', () {
    test('requests 4 item, stats benar, isLoading false', () async {
      stubLoadRequests(
        items: List.generate(4, (i) => makeModel(id: 'r$i')),
        stats: {'pending': 2, 'approved': 1, 'rejected': 1},
      );

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.loadRequests('J01');

      expect(controller.requests.length, 4);
      expect(controller.countPending, 2);
      expect(controller.countApproved, 1);
      expect(controller.countRejected, 1);
      expect(controller.isLoading, false);
      expect(notifyCount, greaterThan(0));
    });
  });

  // ── TC02 ─────────────────────────────────────────────────────────────────
  group('TC02 - loadRequests dengan filter status PENDING', () {
    test('requests 2 item, service dipanggil dengan status=PENDING', () async {
      controller.filterStatus = 'PENDING';
      stubLoadRequests(
        status: 'PENDING',
        items: [
          makeModel(id: 'r1', status: 'PENDING'),
          makeModel(id: 'r2', status: 'PENDING'),
        ],
      );

      await controller.loadRequests('J01');

      expect(controller.requests.length, 2);
      verify(
        mockService.getRequests(idJurusan: 'J01', status: 'PENDING'),
      ).called(1);
    });
  });

  // ── TC03 ─────────────────────────────────────────────────────────────────
  group('TC03 - loadRequests menangkap exception, set isOffline = true', () {
    test('isOffline = true, isLoading false, errorMsg tidak null', () async {
      MongoDatabase.isOffline = true;
      when(
        mockService.getRequests(idJurusan: 'J01', status: null),
      ).thenThrow(Exception('timeout'));
      when(
        mockService.getStats('J01'),
      ).thenAnswer((_) async => {'pending': 0, 'approved': 0, 'rejected': 0});

      await controller.loadRequests('J01');

      expect(controller.isOffline, true);
      expect(controller.isLoading, false);
      expect(controller.errorMsg, isNotNull);

      MongoDatabase.isOffline = false;
    });
  });

  // ── TC04 ─────────────────────────────────────────────────────────────────
  group('TC04 - setFilter mengubah filterStatus dan memicu loadRequests', () {
    test(
      'filterStatus = APPROVED, service dipanggil dengan status=APPROVED',
      () async {
        stubLoadRequests(status: 'APPROVED');

        controller.setFilter('APPROVED', 'J01');
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        expect(controller.filterStatus, 'APPROVED');
        verify(
          mockService.getRequests(idJurusan: 'J01', status: 'APPROVED'),
        ).called(1);
      },
    );
  });

  // ── TC05 ─────────────────────────────────────────────────────────────────
  group('TC05 - approve berhasil dan memuat ulang daftar request', () {
    test(
      'return true, approveRequest dipanggil 1x, loadRequests dipanggil ulang',
      () async {
        final mockRequest = makeModel();

        when(
          mockService.approveRequest(
            requestId: anyNamed('requestId'),
            processorId: anyNamed('processorId'),
            catatanAdmin: anyNamed('catatanAdmin'),
            request: anyNamed('request'),
          ),
        ).thenAnswer((_) async => true);

        // stub loadRequests yang dipanggil setelah approve
        stubLoadRequests(items: List.generate(3, (i) => makeModel(id: 'r$i')));

        final result = await controller.approve(
          requestId: 'req1',
          processorId: 'adm1',
          idJurusan: 'J01',
          request: mockRequest,
        );

        expect(result, true);
        verify(
          mockService.approveRequest(
            requestId: anyNamed('requestId'),
            processorId: anyNamed('processorId'),
            catatanAdmin: anyNamed('catatanAdmin'),
            request: anyNamed('request'),
          ),
        ).called(1);
        // getRequests dipanggil oleh loadRequests setelah approve
        verify(mockService.getStats('J01')).called(1);
      },
    );
  });

  // ── TC06 ─────────────────────────────────────────────────────────────────
  group('TC06 - approve return false jika service.approveRequest gagal', () {
    test('return false, loadRequests tidak dipanggil', () async {
      final mockRequest = makeModel();

      when(
        mockService.approveRequest(
          requestId: anyNamed('requestId'),
          processorId: anyNamed('processorId'),
          catatanAdmin: anyNamed('catatanAdmin'),
          request: anyNamed('request'),
        ),
      ).thenAnswer((_) async => false);

      final result = await controller.approve(
        requestId: 'req1',
        processorId: 'adm1',
        idJurusan: 'J01',
        request: mockRequest,
      );

      expect(result, false);
      verifyNever(
        mockService.getRequests(
          idJurusan: anyNamed('idJurusan'),
          status: anyNamed('status'),
        ),
      );
    });
  });

  // ── TC07 ─────────────────────────────────────────────────────────────────
  group('TC07 - reject berhasil dan memuat ulang daftar request', () {
    test(
      'return true, rejectRequest dipanggil dengan catatan, loadRequests dipanggil ulang',
      () async {
        when(
          mockService.rejectRequest(
            requestId: anyNamed('requestId'),
            processorId: anyNamed('processorId'),
            catatanAdmin: anyNamed('catatanAdmin'),
          ),
        ).thenAnswer((_) async => true);

        stubLoadRequests(items: List.generate(3, (i) => makeModel(id: 'r$i')));

        final result = await controller.reject(
          requestId: 'req1',
          processorId: 'adm1',
          idJurusan: 'J01',
          catatan: 'Jadwal penuh',
        );

        expect(result, true);
        verify(
          mockService.rejectRequest(
            requestId: 'req1',
            processorId: 'adm1',
            catatanAdmin: 'Jadwal penuh',
          ),
        ).called(1);
        verify(mockService.getStats('J01')).called(1);
      },
    );
  });

  // ── TC08 ─────────────────────────────────────────────────────────────────
  group('TC08 - reject return false jika service.rejectRequest gagal', () {
    test('return false, loadRequests tidak dipanggil', () async {
      when(
        mockService.rejectRequest(
          requestId: anyNamed('requestId'),
          processorId: anyNamed('processorId'),
          catatanAdmin: anyNamed('catatanAdmin'),
        ),
      ).thenAnswer((_) async => false);

      final result = await controller.reject(
        requestId: 'req1',
        processorId: 'adm1',
        idJurusan: 'J01',
        catatan: 'Alasan',
      );

      expect(result, false);
      verifyNever(
        mockService.getRequests(
          idJurusan: anyNamed('idJurusan'),
          status: anyNamed('status'),
        ),
      );
    });
  });

  // ── TC09 ─────────────────────────────────────────────────────────────────
  group('TC09 - clearSyncFlag mereset justSynced ke false', () {
    test('justSynced = false, notifyListeners terpanggil', () {
      controller.justSynced = true;

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.clearSyncFlag();

      expect(controller.justSynced, false);
      expect(notifyCount, greaterThan(0));
    });
  });

  // ── TC10 ─────────────────────────────────────────────────────────────────
  group(
    'TC10 - setOffline mengubah isOffline dan notifyListeners jika nilai berbeda',
    () {
      test('isOffline true → notifyListeners terpanggil', () {
        // pastikan isOffline = false dulu
        controller.setOffline(false);

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setOffline(true);

        expect(controller.isOffline, true);
        expect(notifyCount, greaterThan(0));
      });
    },
  );

  // ── TC11 ─────────────────────────────────────────────────────────────────
  group(
    'TC11 - setOffline tidak memanggil notifyListeners jika nilai sama',
    () {
      test('isOffline tetap false, notifyListeners TIDAK dipanggil', () {
        controller.setOffline(false);

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setOffline(false); // nilai sama → early return

        expect(controller.isOffline, false);
        expect(notifyCount, 0);
      });
    },
  );
}
