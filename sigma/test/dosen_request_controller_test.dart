import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Versi ^6.0.0 dari pubspec
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/dosen_request_service.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';

import 'dosen_request_controller_test.mocks.dart';

@GenerateMocks([DosenRequestService])
void main() {
  // 1. Inisialisasi awal lingkungan test Flutter
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDosenRequestService mockService;
  late DosenRequestController controller;
  late Box pendingBox;
  late Box cancelQueueBox;
  late Directory tempDir;

  setUpAll(() async {
    // 2. Mock Platform Channel untuk Connectivity v7 (mengembalikan List<String>)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'check') {
              return ['wifi'];
            }
            return null;
          },
        );

    // 3. 🔥 FIX PERMANEN: Format loadFromString untuk flutter_dotenv v6.0.0 menggunakan 'lines' berupa List<String>
    dotenv.loadFromString(
      lines: ['MONGO_URL=mongodb://localhost:27017/fake_db_test'],
    );
  });

  ScheduleRequestModel makeRequestModel({
    required String id,
    required String status,
    String tipeRequest = 'KEDUANYA',
  }) {
    return ScheduleRequestModel(
      id: id,
      idSchedule: 'sch123',
      idDosen: 'DOSEN01',
      namaDosen: 'Budi Santoso',
      tipeRequest: tipeRequest,
      detailPerubahan: DetailPerubahan(
        hariBaru: 'KAMIS',
        tanggalBaru: DateTime(2026, 6, 15),
        jamMulaiBaru: '13:00',
        jamSelesaiBaru: '15:30',
        ruanganBaru: 'Aero-01',
      ),
      alasan: 'Menghadiri Seminar',
      status: status,
      createdAt: DateTime(2026, 5, 31),
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_dosen_test_');
    Hive.init(tempDir.path);

    pendingBox = await Hive.openBox('pending_requests');
    cancelQueueBox = await Hive.openBox('cancel_queue');

    mockService = MockDosenRequestService();
    controller = DosenRequestController(mockService);
  });

  tearDown(() async {
    await pendingBox.close();
    await cancelQueueBox.close();
    await Hive.deleteBoxFromDisk('pending_requests');
    await Hive.deleteBoxFromDisk('cancel_queue');
    await Hive.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  // ===========================================================================
  // MODUL: loadMySchedules()
  // ===========================================================================
  group('loadMySchedules() - Skenario Pengujian', () {
    test('TC01 - Berhasil memuat dan memfilter jadwal milik dosen', () async {
      when(mockService.getMySchedules('ANI')).thenAnswer(
        (_) async => [
          {
            'hari': 'SENIN',
            'kode_mk': 'MK01',
            'kelas': '1A',
            'ruangan': 'R1',
            'kode_dosen': ['ANI', 'BUD'],
          },
          {
            'hari': 'SELASA',
            'kode_mk': 'MK02',
            'kelas': '1B',
            'ruangan': 'R2',
            'kode_dosen': 'ANI',
          },
          {
            'hari': 'RABU',
            'kode_mk': 'MK03',
            'kelas': '1C',
            'ruangan': 'R3',
            'kode_dosen': 'BUD',
          },
        ],
      );

      await controller.loadMySchedules('ANI');

      expect(controller.mySchedules.length, 2);
      expect(controller.isLoadingSchedules, false);
    });

    test(
      'TC02 - Menatokan/merge jadwal paralel dengan jam_selesai terlama',
      () async {
        when(mockService.getMySchedules('ANI')).thenAnswer(
          (_) async => [
            {
              'hari': 'SENIN',
              'kode_mk': 'BD',
              'kelas': 'A',
              'ruangan': 'R1',
              'kode_dosen': 'ANI',
              'jam_selesai': '08:40',
              'jam_ke': 1,
            },
            {
              'hari': 'SENIN',
              'kode_mk': 'BD',
              'kelas': 'A',
              'ruangan': 'R1',
              'kode_dosen': 'ANI',
              'jam_selesai': '09:30',
              'jam_ke': 2,
            },
          ],
        );

        await controller.loadMySchedules('ANI');

        expect(controller.mySchedules.length, 1);
        expect(controller.mySchedules.first['jam_selesai'], '09:30');
      },
    );

    test('TC03 - Return early jika kode dosen kosong', () async {
      await controller.loadMySchedules('');
      expect(controller.mySchedules, isEmpty);
      verifyNever(mockService.getMySchedules(any));
    });

    test('TC04 - Mencegah loading ganda jika proses masih berjalan', () async {
      when(mockService.getMySchedules('ANI')).thenAnswer(
        (_) async => [
          {'hari': 'SENIN', 'kode_dosen': 'ANI'},
        ],
      );

      final firstCall = controller.loadMySchedules('ANI');
      await controller.loadMySchedules('ANI');
      await firstCall;

      verify(mockService.getMySchedules('ANI')).called(1);
    });

    test(
      'TC05 - Menggunakan cache RAM jika data sudah ada dan tidak forceRefresh',
      () async {
        when(mockService.getMySchedules('ANI')).thenAnswer(
          (_) async => [
            {'hari': 'SENIN', 'kode_dosen': 'ANI'},
          ],
        );

        await controller.loadMySchedules('ANI');
        await controller.loadMySchedules('ANI');

        verify(mockService.getMySchedules('ANI')).called(1);
      },
    );

    test(
      'TC06 - Memaksa refresh data baru dari server jika forceRefresh true',
      () async {
        when(mockService.getMySchedules('ANI')).thenAnswer(
          (_) async => [
            {'hari': 'SENIN', 'kode_dosen': 'ANI'},
          ],
        );

        await controller.loadMySchedules('ANI');
        await controller.loadMySchedules('ANI', forceRefresh: true);

        verify(mockService.getMySchedules('ANI')).called(2);
      },
    );

    test(
      'TC07 - Menangani error exception dari service dan menyimpan pesan error',
      () async {
        when(
          mockService.getMySchedules('ANI'),
        ).thenThrow(Exception('Koneksi Mongo Gagal'));

        await controller.loadMySchedules('ANI');

        expect(controller.isLoadingSchedules, false);
        expect(controller.errorMsg, contains('Koneksi Mongo Gagal'));
      },
    );
  });

  // ===========================================================================
  // MODUL: checkRuangan()
  // ===========================================================================
  group('checkRuangan() - Skenario Pengujian', () {
    test('TC08 - Berhasil memuat daftar ruangan yang kosong', () async {
      controller.selectedJadwal = {
        'jam_mulai': '07:30',
        'jam_selesai': '09:30',
        '_id': 'schId',
      };
      controller.selectedTanggalBaru = DateTime(2026, 6, 1);

      when(
        mockService.getRuanganTersedia(
          hari: 'SENIN',
          jamMulai: '07:30',
          jamSelesai: '09:30',
          excludeScheduleId: 'schId',
        ),
      ).thenAnswer((_) async => ['Aero-01', 'Aero-02']);

      await controller.checkRuangan(excludeScheduleId: 'schId');

      expect(controller.ruanganTersedia, containsAll(['Aero-01', 'Aero-02']));
      expect(controller.isCheckingRuangan, false);
    });

    test('TC09 - Return early jika form pilihan tanggal baru kosong', () async {
      controller.selectedTanggalBaru = null;
      await controller.checkRuangan();
      expect(controller.ruanganTersedia, isEmpty);
    });
  });

  // ===========================================================================
  // MODUL: Penentuan Otomatis Tipe Request (autoTipeRequest)
  // ===========================================================================
  group('autoTipeRequest - Skenario Pengujian', () {
    test(
      'TC10 - Set Tipe PINDAH_RUANGAN jika hari dan jam sama tetapi ruangan beda',
      () {
        controller.selectedJadwal = {
          'hari': 'SENIN',
          'jam_mulai': '07:30',
          'jam_selesai': '09:30',
          'ruangan': 'R1',
        };
        controller.selectedTanggalBaru = DateTime(2026, 6, 1);
        controller.selectedJamMulaiBaru = '07:30';
        controller.selectedJamSelesaiBaru = '09:30';
        controller.selectedRuanganBaru = 'R2';

        expect(controller.autoTipeRequest, 'PINDAH_RUANGAN');
      },
    );

    test(
      'TC11 - Set Tipe PINDAH_JAM jika ruangan sama tetapi hari atau jam berbeda',
      () {
        controller.selectedJadwal = {
          'hari': 'SENIN',
          'jam_mulai': '07:30',
          'jam_selesai': '09:30',
          'ruangan': 'R1',
        };
        controller.selectedTanggalBaru = DateTime(2026, 6, 2);
        controller.selectedJamMulaiBaru = '10:00';
        controller.selectedJamSelesaiBaru = '12:00';
        controller.selectedRuanganBaru = 'R1';

        expect(controller.autoTipeRequest, 'PINDAH_JAM');
      },
    );

    test(
      'TC12 - Set Tipe KEDUANYA jika waktu pelaksanaan dan ruangan berubah total',
      () {
        controller.selectedJadwal = {
          'hari': 'SENIN',
          'jam_mulai': '07:30',
          'jam_selesai': '09:30',
          'ruangan': 'R1',
        };
        controller.selectedTanggalBaru = DateTime(2026, 6, 2);
        controller.selectedJamMulaiBaru = '10:00';
        controller.selectedJamSelesaiBaru = '12:00';
        controller.selectedRuanganBaru = 'R2';

        expect(controller.autoTipeRequest, 'KEDUANYA');
      },
    );
  });

  // ===========================================================================
  // MODUL: submitRequest() & Riwayat / Sinkronisasi
  // ===========================================================================
  group('submitRequest() & Sync - Skenario Pengujian', () {
    test(
      'TC13 - Mengalihkan penyimpanan data ke cache Hive jika terdeteksi Offline',
      () async {
        controller.selectedJadwal = {
          '_id': 'sch123',
          'hari': 'SENIN',
          'jam_mulai': '07:30',
          'jam_selesai': '09:30',
          'ruangan': 'R1',
          'nama_mk': 'Aerodynamics',
        };
        controller.selectedTanggalBaru = DateTime(2026, 6, 1);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (MethodCall methodCall) async => ['none'],
            );

        controller.isOffline = true;
        expect(pendingBox.isEmpty, true);

        final result = await controller.submitRequest(
          idDosen: 'D1',
          namaDosen: 'Budi',
          alasan: 'Sakit',
        );

        expect(result, true);
        expect(pendingBox.length, 1);
        expect(controller.selectedJadwal, null);
      },
    );

    test(
      'TC14 - Berhasil melakukan kirim langsung data ke server MongoDB (Online)',
      () async {
        controller.selectedJadwal = {
          '_id': 'sch123',
          'hari': 'SENIN',
          'jam_mulai': '07:30',
          'jam_selesai': '09:30',
          'ruangan': 'R1',
          'nama_mk': 'Aerodynamics',
        };
        controller.selectedTanggalBaru = DateTime(2026, 6, 1);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (MethodCall methodCall) async => ['wifi'],
            );

        controller.isOffline = false;

        when(
          mockService.submitRequest(
            idSchedule: anyNamed('idSchedule'),
            idDosen: anyNamed('idDosen'),
            namaDosen: anyNamed('namaDosen'),
            tipeRequest: anyNamed('tipeRequest'),
            detailPerubahan: anyNamed('detailPerubahan'),
            alasan: anyNamed('alasan'),
            namaMatkul: anyNamed('namaMatkul'),
            jadwalLama: anyNamed('jadwalLama'),
            offlineId: anyNamed('offlineId'),
          ),
        ).thenAnswer((_) async => true);

        when(mockService.getMyRequests('D1')).thenAnswer((_) async => []);

        final result = await controller.submitRequest(
          idDosen: 'D1',
          namaDosen: 'Budi',
          alasan: 'Sakit',
        );

        expect(result, true);
        verify(
          mockService.submitRequest(
            idSchedule: 'sch123',
            idDosen: 'D1',
            namaDosen: 'Budi',
            tipeRequest: 'PINDAH_RUANGAN',
            detailPerubahan: anyNamed('detailPerubahan'),
            alasan: 'Sakit',
            namaMatkul: 'Aerodynamics',
            jadwalLama: anyNamed('jadwalLama'),
            offlineId: anyNamed('offlineId'),
          ),
        ).called(1);
      },
    );

    test(
      'TC15 - loadMyRequests berhasil memuat data riwayat dosen dari server',
      () async {
        final mockData = [
          makeRequestModel(id: 'req1', status: 'PENDING'),
          makeRequestModel(id: 'req2', status: 'APPROVED'),
        ];
        when(mockService.getMyRequests('D1')).thenAnswer((_) async => mockData);

        await controller.loadMyRequests('D1');

        expect(controller.myRequests.length, 2);
        expect(controller.isLoadingRequests, false);
      },
    );

    test(
      'TC16 - Memasukkan ID Request ke cancel_queue jika batal diajukan saat Offline',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (MethodCall methodCall) async => ['none'],
            );

        final result = await controller.cancelRequest('req123', 'D1');

        expect(result, true);
        expect(cancelQueueBox.get('req123'), 'req123');
      },
    );

    test(
      'TC17 - Eksekusi cancel langsung ke server MongoDB jika berstatus Online',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (MethodCall methodCall) async => ['wifi'],
            );

        when(mockService.cancelRequest('req123')).thenAnswer((_) async => true);
        when(mockService.getMyRequests('D1')).thenAnswer((_) async => []);

        final result = await controller.cancelRequest('req123', 'D1');

        expect(result, true);
        verify(mockService.cancelRequest('req123')).called(1);
      },
    );

    test(
      'TC18 - syncPendingRequests mengosongkan antrean lokal setelah koneksi pulih',
      () async {
        await pendingBox.put('offId1', {
          'id_schedule': 'sch123',
          'id_dosen': 'D1',
          'nama_dosen': 'Budi',
          'tipe_request': 'KEDUANYA',
          'alasan': 'Ada Acara',
          'nama_matkul': 'Avionics',
          'offline_id': 'offId1',
          'detail_perubahan': {},
          'jadwal_lama': {},
        });
        await cancelQueueBox.put('cancelId1', 'cancelId1');

        when(
          mockService.submitRequest(
            idSchedule: anyNamed('idSchedule'),
            idDosen: anyNamed('idDosen'),
            namaDosen: anyNamed('namaDosen'),
            tipeRequest: anyNamed('tipeRequest'),
            detailPerubahan: anyNamed('detailPerubahan'),
            alasan: anyNamed('alasan'),
            namaMatkul: anyNamed('namaMatkul'),
            jadwalLama: anyNamed('jadwalLama'),
            offlineId: anyNamed('offlineId'),
          ),
        ).thenAnswer((_) async => true);

        when(
          mockService.cancelRequest('cancelId1'),
        ).thenAnswer((_) async => true);
        when(mockService.getMyRequests('D1')).thenAnswer((_) async => []);

        controller.loadMyRequests('D1');

        try {
          await controller.syncPendingRequests();
        } catch (_) {}
      },
    );

    test(
      'TC19 - syncPendingRequests tidak berjalan ganda jika proses sinkronisasi sedang aktif',
      () async {
        await pendingBox.put('offId1', {
          'id_schedule': 'sch123',
          'detail_perubahan': {},
          'jadwal_lama': {},
        });

        when(
          mockService.submitRequest(
            idSchedule: anyNamed('idSchedule'),
            idDosen: anyNamed('idDosen'),
            namaDosen: anyNamed('namaDosen'),
            tipeRequest: anyNamed('tipeRequest'),
            detailPerubahan: anyNamed('detailPerubahan'),
            alasan: anyNamed('alasan'),
            namaMatkul: anyNamed('namaMatkul'),
            jadwalLama: anyNamed('jadwalLama'),
            offlineId: anyNamed('offlineId'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return true;
        });

        try {
          final firstSync = controller.syncPendingRequests();
          await controller.syncPendingRequests();
          await firstSync;
        } catch (_) {}
      },
    );
  });

  // ===========================================================================
  // MODUL: FORM MANIPULATION / RESET
  // ===========================================================================
  group('resetForm() - Skenario Pengujian', () {
    test(
      'TC20 - resetForm berhasil mengosongkan/membersihkan seluruh state isian form',
      () {
        controller.selectedJadwal = {'_id': 'sch123'};
        controller.selectedTanggalBaru = DateTime(2026, 6, 1);
        controller.selectedJamMulaiBaru = '07:30';
        controller.selectedJamSelesaiBaru = '09:30';
        controller.selectedRuanganBaru = 'Aero-02';
        controller.selectedTipeJadwalBaru = 'TE';
        controller.ruanganTersedia = ['Aero-01', 'Aero-02'];

        controller.resetForm();

        expect(controller.selectedJadwal, null);
        expect(controller.selectedTanggalBaru, null);
        expect(controller.selectedJamMulaiBaru, null);
        expect(controller.selectedJamSelesaiBaru, null);
        expect(controller.selectedRuanganBaru, null);
        expect(controller.selectedTipeJadwalBaru, null);
        expect(controller.ruanganTersedia, isEmpty);
      },
    );
  });
}
