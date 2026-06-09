import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/dosen_request_service.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';

import 'dosen_request_controller_test.mocks.dart';

@GenerateMocks([DosenRequestService])
void main() {
  // Wajib: Connectivity & platform channel butuh binding
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDosenRequestService mockService;
  late DosenRequestController controller;
  late Directory tempDir;
  late Box pendingBox;
  late Box cancelQueue;
  late Box scheduleCache;

  // ── Helper ──────────────────────────────────────────────────────────────
  Map<String, dynamic> makeJadwal({
    String id = 'sch1',
    String hari = 'SENIN',
    String jamMulai = '07:30',
    String jamSelesai = '09:10',
    String ruangan = 'R1',
    String kodeMk = 'BD',
    String kelas = 'A',
    String namaMk = 'Basis Data',
  }) => {
    '_id': id,
    'hari': hari,
    'jam_mulai': jamMulai,
    'jam_selesai': jamSelesai,
    'ruangan': ruangan,
    'kode_mk': kodeMk,
    'kode_dosen': ['ANI'],
    'kelas': kelas,
    'nama_mk': namaMk,
  };

  ScheduleRequestModel makeRequestModel({String id = 'req1'}) {
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
      'status': 'PENDING',
      'offline_id': null,
      'catatan_admin': null,
      'id_processor': null,
      'is_late': false,
      'created_at': null,
      'updated_at': null,
    };
    return ScheduleRequestModel.fromJson(m);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_drc_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(DetailPerubahanAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(ScheduleRequestModelAdapter());

    pendingBox = await Hive.openBox('pending_requests');
    cancelQueue = await Hive.openBox('cancel_queue');
    scheduleCache = await Hive.openBox('schedule_cache');

    mockService = MockDosenRequestService();
    controller = DosenRequestController(mockService);
  });

  tearDown(() async {
    await pendingBox.close();
    await cancelQueue.close();
    await scheduleCache.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ── TC01 ─────────────────────────────────────────────────────────────────
  group(
    'TC01 - loadMySchedules berhasil memuat dan memfilter jadwal milik dosen',
    () {
      test(
        'mySchedules berisi 2 item (hanya milik ANI), isLoadingSchedules false',
        () async {
          when(mockService.getMySchedules('ANI')).thenAnswer(
            (_) async => [
              {
                ...makeJadwal(id: 's1'),
                'kode_dosen': ['ANI', 'BUD'],
              },
              {
                ...makeJadwal(id: 's2'),
                'kode_dosen': ['ANI'],
              },
              {
                ...makeJadwal(id: 's3'),
                'kode_dosen': ['BUD'],
              },
            ],
          );

          int notifyCount = 0;
          controller.addListener(() => notifyCount++);

          await controller.loadMySchedules('ANI');

          expect(controller.mySchedules.length, 2);
          expect(controller.isLoadingSchedules, false);
          expect(notifyCount, greaterThan(0));
        },
      );
    },
  );

  // ── TC02 ─────────────────────────────────────────────────────────────────
  group('TC02 - loadMySchedules menyatukan jadwal dengan key sama (merge)', () {
    test(
      '2 item key sama → 1 item, jam_selesai terbesar, jam_ke range',
      () async {
        when(mockService.getMySchedules('ANI')).thenAnswer(
          (_) async => [
            {
              '_id': 's1',
              'hari': 'SENIN',
              'kode_mk': 'BD',
              'kode_dosen': ['ANI'],
              'kelas': 'A',
              'ruangan': 'R1',
              'jam_ke': 1,
              'jam_mulai': '07:30',
              'jam_selesai': '08:40',
              'nama_mk': 'Basis Data',
            },
            {
              '_id': 's2',
              'hari': 'SENIN',
              'kode_mk': 'BD',
              'kode_dosen': ['ANI'],
              'kelas': 'A',
              'ruangan': 'R1',
              'jam_ke': 2,
              'jam_mulai': '08:40',
              'jam_selesai': '09:30',
              'nama_mk': 'Basis Data',
            },
          ],
        );

        await controller.loadMySchedules('ANI');

        expect(controller.mySchedules.length, 1);
        expect(controller.mySchedules.first['jam_selesai'], '09:30');
        expect(
          controller.mySchedules.first['jam_ke'].toString(),
          contains('1'),
        );
        expect(
          controller.mySchedules.first['jam_ke'].toString(),
          contains('2'),
        );
      },
    );
  });

  // ── TC03 ─────────────────────────────────────────────────────────────────
  group('TC03 - loadMySchedules tidak fetch jika kodeDosen kosong', () {
    test('service tidak dipanggil, isLoadingSchedules tetap false', () async {
      await controller.loadMySchedules('');

      verifyNever(mockService.getMySchedules(any));
      expect(controller.mySchedules, isEmpty);
      expect(controller.isLoadingSchedules, false);
    });
  });

  // ── TC04 ─────────────────────────────────────────────────────────────────
  group('TC04 - loadMySchedules menangkap exception dan set errorMsg', () {
    test(
      'errorMsg tidak null, isLoadingSchedules false, mySchedules tetap []',
      () async {
        when(
          mockService.getMySchedules('ANI'),
        ).thenThrow(Exception('DB error'));

        await controller.loadMySchedules('ANI');

        expect(controller.errorMsg, isNotNull);
        expect(controller.isLoadingSchedules, false);
        expect(controller.mySchedules, isEmpty);
      },
    );
  });

  // ── TC05 ─────────────────────────────────────────────────────────────────
  group('TC05 - checkRuangan berhasil mengambil daftar ruangan tersedia', () {
    test('ruanganTersedia = [R1,R2], isCheckingRuangan false', () async {
      controller.selectJadwal(
        makeJadwal(
          hari: 'SENIN',
          jamMulai: '07:30',
          jamSelesai: '09:10',
          ruangan: 'R3',
        ),
      );
      controller.selectTanggal(DateTime(2025, 6, 2)); // Senin

      when(
        mockService.getRuanganTersedia(
          hari: anyNamed('hari'),
          jamMulai: anyNamed('jamMulai'),
          jamSelesai: anyNamed('jamSelesai'),
          excludeScheduleId: anyNamed('excludeScheduleId'),
        ),
      ).thenAnswer((_) async => ['R1', 'R2']);

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.checkRuangan();

      expect(controller.ruanganTersedia, ['R1', 'R2']);
      expect(controller.isCheckingRuangan, false);
      expect(notifyCount, greaterThan(0));
    });
  });

  // ── TC06 ─────────────────────────────────────────────────────────────────
  group('TC06 - checkRuangan tidak fetch jika selectedTanggalBaru null', () {
    test('service tidak dipanggil, ruanganTersedia tetap []', () async {
      await controller.checkRuangan();

      verifyNever(
        mockService.getRuanganTersedia(
          hari: anyNamed('hari'),
          jamMulai: anyNamed('jamMulai'),
          jamSelesai: anyNamed('jamSelesai'),
        ),
      );
      expect(controller.ruanganTersedia, isEmpty);
      expect(controller.isCheckingRuangan, false);
    });
  });

  // ── TC07 ─────────────────────────────────────────────────────────────────
  // submitRequest memanggil Connectivity().checkConnectivity() secara internal.
  // Agar tidak crash, mock Connectivity via TestDefaultBinaryMessengerBinding
  // dengan hasil online (tidak ada ConnectivityResult.none).
  group('TC07 - submitRequest online berhasil mengirim request ke service', () {
    test('return true, form direset, isSubmitting false', () async {
      controller.selectJadwal(
        makeJadwal(
          id: 'abc',
          hari: 'SENIN',
          jamMulai: '07:30',
          jamSelesai: '09:10',
          ruangan: 'R1',
          namaMk: 'BD',
        ),
      );
      controller.selectTanggal(DateTime(2025, 6, 4)); // Rabu

      // Mock platform channel connectivity → online
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/connectivity'),
            (call) async {
              if (call.method == 'check') return ['wifi'];
              return null;
            },
          );

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

      final result = await controller.submitRequest(
        idDosen: 'D01',
        namaDosen: 'Bu Ani',
        alasan: 'Bentrok',
      );

      expect(result, true);
      expect(controller.selectedJadwal, isNull);
      expect(controller.isSubmitting, false);
    });
  });

  // ── TC08 ─────────────────────────────────────────────────────────────────
  group(
    'TC08 - submitRequest offline menyimpan ke pendingBox tanpa menghubungi service',
    () {
      test('pendingBox berisi 1 item, service tidak dipanggil', () async {
        controller.selectJadwal(
          makeJadwal(
            id: 'abc',
            hari: 'SENIN',
            jamMulai: '07:30',
            jamSelesai: '09:10',
            ruangan: 'R1',
            namaMk: 'BD',
          ),
        );
        controller.selectTanggal(DateTime(2025, 6, 4));

        // Mock platform channel connectivity → offline
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (call) async {
                if (call.method == 'check') return ['none'];
                return null;
              },
            );

        final result = await controller.submitRequest(
          idDosen: 'D01',
          namaDosen: 'Bu Ani',
          alasan: 'Bentrok',
        );

        expect(result, true);
        expect(pendingBox.isNotEmpty, true);
        verifyNever(
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
        );
      });
    },
  );

  // ── TC09 ─────────────────────────────────────────────────────────────────
  group(
    'TC09 - submitRequest return false jika selectedJadwal atau selectedTanggalBaru null',
    () {
      test(
        'return false, service tidak dipanggil, isSubmitting false',
        () async {
          final result = await controller.submitRequest(
            idDosen: 'D01',
            namaDosen: 'Bu Ani',
            alasan: 'Test',
          );

          expect(result, false);
          verifyNever(
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
          );
          expect(controller.isSubmitting, false);
        },
      );
    },
  );

  // ── TC10 ─────────────────────────────────────────────────────────────────
  group(
    'TC10 - autoTipeRequest = PINDAH_RUANGAN jika hari dan jam sama, ruangan beda',
    () {
      test('autoTipeRequest = PINDAH_RUANGAN', () {
        controller.selectJadwal(
          makeJadwal(
            hari: 'SENIN',
            jamMulai: '07:30',
            jamSelesai: '09:10',
            ruangan: 'R1',
          ),
        );
        controller.selectTanggal(DateTime(2025, 6, 2)); // Senin
        controller.selectRuangan('R2');

        expect(controller.autoTipeRequest, 'PINDAH_RUANGAN');
      });
    },
  );

  // ── TC11 ─────────────────────────────────────────────────────────────────
  group(
    'TC11 - autoTipeRequest = PINDAH_JAM jika hari/jam beda, ruangan sama',
    () {
      test('autoTipeRequest = PINDAH_JAM', () {
        controller.selectJadwal(
          makeJadwal(
            hari: 'SENIN',
            jamMulai: '07:30',
            jamSelesai: '09:10',
            ruangan: 'R1',
          ),
        );
        controller.selectTanggal(DateTime(2025, 6, 4)); // Rabu

        expect(controller.autoTipeRequest, 'PINDAH_JAM');
      });
    },
  );

  // ── TC12 ─────────────────────────────────────────────────────────────────
  group('TC12 - autoTipeRequest = KEDUANYA jika hari/jam dan ruangan beda', () {
    test('autoTipeRequest = KEDUANYA', () {
      controller.selectJadwal(
        makeJadwal(
          hari: 'SENIN',
          jamMulai: '07:30',
          jamSelesai: '09:10',
          ruangan: 'R1',
        ),
      );
      controller.selectTanggal(DateTime(2025, 6, 4)); // Rabu
      controller.selectRuangan('R2');

      expect(controller.autoTipeRequest, 'KEDUANYA');
    });
  });

  // ── TC13 ─────────────────────────────────────────────────────────────────
  group(
    'TC13 - autoTipeRequest return null jika selectedJadwal atau selectedTanggalBaru null',
    () {
      test('autoTipeRequest = null', () {
        expect(controller.autoTipeRequest, isNull);
      });
    },
  );

  // ── TC14 ─────────────────────────────────────────────────────────────────
  group('TC14 - loadMyRequests berhasil memuat daftar request milik dosen', () {
    test('myRequests berisi 3 item, isLoadingRequests false', () async {
      final items = [
        makeRequestModel(id: 'r1'),
        makeRequestModel(id: 'r2'),
        makeRequestModel(id: 'r3'),
      ];
      when(mockService.getMyRequests('D01')).thenAnswer((_) async => items);

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.loadMyRequests('D01');

      expect(controller.myRequests.length, 3);
      expect(controller.isLoadingRequests, false);
      expect(notifyCount, greaterThan(0));
    });
  });

  // ── TC15 ─────────────────────────────────────────────────────────────────
  group('TC15 - loadMyRequests menangkap exception dan set errorMsg', () {
    test(
      'errorMsg tidak null, isLoadingRequests false, myRequests tetap []',
      () async {
        when(mockService.getMyRequests('D01')).thenThrow(Exception('Error'));

        await controller.loadMyRequests('D01');

        expect(controller.errorMsg, isNotNull);
        expect(controller.isLoadingRequests, false);
        expect(controller.myRequests, isEmpty);
      },
    );
  });

  // ── TC16 ─────────────────────────────────────────────────────────────────
  group('TC16 - cancelRequest online berhasil dan reload daftar request', () {
    test(
      'return true, service.cancelRequest dipanggil 1x, loadMyRequests dipanggil ulang',
      () async {
        // Mock connectivity → online
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (call) async {
                if (call.method == 'check') return ['wifi'];
                return null;
              },
            );

        when(mockService.cancelRequest('req123')).thenAnswer((_) async => true);
        when(mockService.getMyRequests('D01')).thenAnswer(
          (_) async => [makeRequestModel(), makeRequestModel(id: 'r2')],
        );

        final result = await controller.cancelRequest('req123', 'D01');

        expect(result, true);
        verify(mockService.cancelRequest('req123')).called(1);
        verify(mockService.getMyRequests('D01')).called(1);
      },
    );
  });

  // ── TC17 ─────────────────────────────────────────────────────────────────
  group(
    'TC17 - cancelRequest offline menyimpan ke cancelQueue tanpa menghubungi service',
    () {
      test('cancelQueue berisi requestId, service tidak dipanggil', () async {
        // Mock connectivity → offline
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (call) async {
                if (call.method == 'check') return ['none'];
                return null;
              },
            );

        final result = await controller.cancelRequest('req123', 'D01');

        expect(result, true);
        expect(cancelQueue.containsKey('req123'), true);
        verifyNever(mockService.cancelRequest(any));
      });
    },
  );

  // ── TC18 ─────────────────────────────────────────────────────────────────
  group('TC18 - resetForm mengosongkan semua state form', () {
    test('semua field form null/kosong setelah resetForm', () {
      controller.selectJadwal(makeJadwal());
      controller.selectTanggal(DateTime(2025, 6, 4));
      controller.selectJam('08:00', '09:40');
      controller.selectRuangan('R2');
      controller.selectTipeJadwal('PR');

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.resetForm();

      expect(controller.selectedJadwal, isNull);
      expect(controller.selectedTanggalBaru, isNull);
      expect(controller.selectedJamMulaiBaru, isNull);
      expect(controller.selectedJamSelesaiBaru, isNull);
      expect(controller.selectedRuanganBaru, isNull);
      expect(controller.selectedTipeJadwalBaru, isNull);
      expect(controller.ruanganTersedia, isEmpty);
      expect(notifyCount, greaterThan(0));
    });
  });
}
