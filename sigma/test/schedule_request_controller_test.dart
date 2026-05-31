import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/schedule_request_service.dart';
import 'package:sigma/features/penjadwalan/viewmodels/schedule_request_controller.dart';

import 'schedule_request_controller_test.mocks.dart';

@GenerateMocks([ScheduleRequestService])
void main() {
  late MockScheduleRequestService mockService;
  late ScheduleRequestController controller;

  ScheduleRequestModel makeReq(String id, String status) {
    return ScheduleRequestModel(
      id: id,
      idSchedule: 'sch$id',
      idDosen: 'dos1',
      namaDosen: 'Dosen A',
      tipeRequest: 'KEDUANYA',
      detailPerubahan: DetailPerubahan(hariBaru: 'JUMAT'),
      alasan: 'Alasan A',
      status: status,
    );
  }

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(
      envString: 'MONGO_URL=mongodb://localhost:27017/fake_db_test',
    );
  });

  setUp(() {
    mockService = MockScheduleRequestService();
    MongoDatabase.isOffline = false;
    controller = ScheduleRequestController(mockService);
    controller.onEnsureConnected = () async {};
  });

  // ===========================================================================
  // MODUL: loadRequests() & Filter
  // ===========================================================================
  group('loadRequests() & setFilter() - Skenario Pengujian', () {
    test(
      'TC01 - Berhasil memuat daftar request dan set nilai statistik',
      () async {
        final mockData = [
          makeReq('1', 'PENDING'),
          makeReq('2', 'PENDING'),
          makeReq('3', 'APPROVED'),
          makeReq('4', 'REJECTED'),
        ];

        when(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).thenAnswer((_) async => mockData);
        when(
          mockService.getStats('J01'),
        ).thenAnswer((_) async => {'pending': 2, 'approved': 1, 'rejected': 1});

        await controller.loadRequests('J01');

        expect(controller.requests.length, 4);
        expect(controller.countPending, 2);
        expect(controller.countApproved, 1);
        expect(controller.countRejected, 1);
        expect(controller.isLoading, false);
      },
    );

    test(
      'TC02 - Filter status hanya mengembalikan request sesuai filter',
      () async {
        final mockData = [makeReq('1', 'PENDING'), makeReq('2', 'PENDING')];

        when(
          mockService.getRequests(idJurusan: 'J01', status: 'PENDING'),
        ).thenAnswer((_) async => mockData);
        when(
          mockService.getStats('J01'),
        ).thenAnswer((_) async => {'pending': 2, 'approved': 0, 'rejected': 0});

        controller.setFilter('PENDING', 'J01');
        await Future.delayed(Duration.zero);

        expect(controller.filterStatus, 'PENDING');
        expect(controller.requests.length, 2);
        expect(controller.requests.every((r) => r.status == 'PENDING'), true);
      },
    );

    test(
      'TC03 - Exception dari service memicu mode offline dan menghitung fallback stat lokal',
      () async {
        when(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).thenThrow(Exception('Koneksi Gagal'));
        when(mockService.getStats('J01')).thenThrow(Exception('Koneksi Gagal'));

        controller.requests = [
          makeReq('1', 'PENDING'),
          makeReq('2', 'APPROVED'),
          makeReq('3', 'REJECTED'),
          makeReq('4', 'REJECTED'),
        ];

        await controller.loadRequests('J01');

        expect(controller.isOffline, true);
        expect(controller.errorMsg, contains('Koneksi Gagal'));
        expect(controller.countPending, 1);
        expect(controller.countApproved, 1);
        expect(controller.countRejected, 2);
      },
    );
  });

  // ===========================================================================
  // MODUL: Action Approve / Reject
  // ===========================================================================
  group('approve() & reject() - Skenario Pengujian', () {
    test(
      'TC04 - Approve memanggil service dan me-refresh data jika berhasil',
      () async {
        final dummyReq = makeReq('1', 'PENDING');

        when(
          mockService.approveRequest(
            requestId: '1',
            processorId: 'PROC_01',
            catatanAdmin: 'OK',
            request: dummyReq,
          ),
        ).thenAnswer((_) async => true);

        when(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).thenAnswer((_) async => []);
        when(
          mockService.getStats('J01'),
        ).thenAnswer((_) async => {'pending': 0, 'approved': 0, 'rejected': 0});

        final result = await controller.approve(
          requestId: '1',
          processorId: 'PROC_01',
          idJurusan: 'J01',
          catatan: 'OK',
          request: dummyReq,
        );

        expect(result, true);
        verify(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).called(1);
      },
    );

    test(
      'TC05 - Approve mengembalikan false dan TIDAK merefresh data jika gagal',
      () async {
        final dummyReq = makeReq('1', 'PENDING');

        when(
          mockService.approveRequest(
            requestId: '1',
            processorId: 'PROC_01',
            catatanAdmin: 'OK',
            request: dummyReq,
          ),
        ).thenAnswer((_) async => false);

        final result = await controller.approve(
          requestId: '1',
          processorId: 'PROC_01',
          idJurusan: 'J01',
          catatan: 'OK',
          request: dummyReq,
        );

        expect(result, false);
        verifyNever(
          mockService.getRequests(
            idJurusan: anyNamed('idJurusan'),
            status: anyNamed('status'),
          ),
        );
      },
    );

    test(
      'TC06 - Reject memanggil service dan me-refresh data jika berhasil',
      () async {
        when(
          mockService.rejectRequest(
            requestId: '1',
            processorId: 'PROC_01',
            catatanAdmin: 'Ditolak, jadwal bentrok',
          ),
        ).thenAnswer((_) async => true);

        when(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).thenAnswer((_) async => []);
        when(
          mockService.getStats('J01'),
        ).thenAnswer((_) async => {'pending': 0, 'approved': 0, 'rejected': 0});

        final result = await controller.reject(
          requestId: '1',
          processorId: 'PROC_01',
          idJurusan: 'J01',
          catatan: 'Ditolak, jadwal bentrok',
        );

        expect(result, true);
        verify(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).called(1);
      },
    );

    test(
      'TC07 - Reject mengembalikan false dan TIDAK merefresh data jika gagal',
      () async {
        when(
          mockService.rejectRequest(
            requestId: '1',
            processorId: 'PROC_01',
            catatanAdmin: 'Gagal',
          ),
        ).thenAnswer((_) async => false);

        final result = await controller.reject(
          requestId: '1',
          processorId: 'PROC_01',
          idJurusan: 'J01',
          catatan: 'Gagal',
        );

        expect(result, false);
        verifyNever(
          mockService.getRequests(
            idJurusan: anyNamed('idJurusan'),
            status: anyNamed('status'),
          ),
        );
      },
    );
  });

  // ===========================================================================
  // MODUL: onConnectionRestored & clearSyncFlag
  // ===========================================================================
  group('onConnectionRestored() & Syncing - Skenario Pengujian', () {
    test(
      'TC08 - Memulai proses sinkronisasi dan tidak reload request karena _lastIdJurusan kosong',
      () async {
        MongoDatabase.isOffline = true;
        controller.isOffline = true;
        controller.onEnsureConnected = () async {};

        when(mockService.flushQueue()).thenAnswer((_) async => 0);

        await controller.onConnectionRestored();

        expect(controller.isSyncing, false);
        expect(controller.isOffline, false);
        expect(controller.justSynced, false);
        verifyNever(
          mockService.getRequests(
            idJurusan: anyNamed('idJurusan'),
            status: anyNamed('status'),
          ),
        );
      },
    );

    test(
      'TC09 - Menyelesaikan sinkronisasi dengan hasil > 0 dan merefresh data karena idJurusan tersedia',
      () async {
        controller.onEnsureConnected = () async {};

        // loadRequests saat ONLINE agar _lastIdJurusan terisi
        MongoDatabase.isOffline = false;
        controller.isOffline = false;

        when(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).thenAnswer((_) async => []);
        when(mockService.getStats('J01')).thenAnswer((_) async => {});
        await controller.loadRequests('J01');

        // Simulasikan offline → restored
        MongoDatabase.isOffline = false;
        controller.isOffline = true;

        when(mockService.flushQueue()).thenAnswer((_) async => 2);

        await controller.onConnectionRestored();

        expect(controller.isSyncing, false);
        expect(controller.isOffline, false);
        expect(controller.justSynced, true);
        verify(
          mockService.getRequests(idJurusan: 'J01', status: null),
        ).called(2);
      },
    );

    test(
      'TC10 - Exception saat flushQueue ditangkap dan flag reset berjalan aman (no-crash)',
      () async {
        MongoDatabase.isOffline = true;
        controller.isOffline = true;
        controller.onEnsureConnected = () async {};

        when(mockService.flushQueue()).thenThrow(Exception('Sync error'));

        await controller.onConnectionRestored();

        expect(controller.isSyncing, false);
        expect(controller.justSynced, false);
      },
    );

    test('TC11 - clearSyncFlag mereset state penanda notifikasi sukses', () {
      controller.justSynced = true;
      controller.clearSyncFlag();
      expect(controller.justSynced, false);
    });
  });

  // ===========================================================================
  // MODUL: Offline Status Management
  // ===========================================================================
  group('setOffline() - Skenario Pengujian', () {
    test('TC12 - Mengubah isOffline dan memicu notifyListeners', () {
      bool isNotified = false;
      controller.addListener(() {
        isNotified = true;
      });

      controller.isOffline = false;
      controller.setOffline(true);

      expect(controller.isOffline, true);
      expect(isNotified, true);
    });

    test(
      'TC13 - Tidak memicu notifyListeners jika nilai offline sama dengan yang lama',
      () {
        bool isNotified = false;
        controller.addListener(() {
          isNotified = true;
        });

        controller.isOffline = false;
        controller.setOffline(false);

        expect(controller.isOffline, false);
        expect(isNotified, false);
      },
    );
  });
}
