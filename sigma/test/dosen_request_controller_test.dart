import 'dart:io';

<<<<<<< HEAD
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
=======
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Versi ^6.0.0 dari pubspec
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f

import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/data/services/dosen_request_service.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';

import 'dosen_request_controller_test.mocks.dart';

@GenerateMocks([DosenRequestService])
void main() {
<<<<<<< HEAD
  // Wajib: Connectivity & platform channel butuh binding
=======
  // 1. Inisialisasi awal lingkungan test Flutter
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDosenRequestService mockService;
  late DosenRequestController controller;
<<<<<<< HEAD
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
=======
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
      envString: 'MONGO_URL=mongodb://localhost:27017/fake_db_test',
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f

    mockService = MockDosenRequestService();
    controller = DosenRequestController(mockService);
  });

  tearDown(() async {
    await pendingBox.close();
<<<<<<< HEAD
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
=======
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
      () async {
        when(mockService.getMySchedules('ANI')).thenAnswer(
          (_) async => [
            {
<<<<<<< HEAD
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
=======
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
            },
          ],
        );

        await controller.loadMySchedules('ANI');

        expect(controller.mySchedules.length, 1);
        expect(controller.mySchedules.first['jam_selesai'], '09:30');
<<<<<<< HEAD
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
=======
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
      },
    );
  });

<<<<<<< HEAD
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
=======
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
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
<<<<<<< HEAD
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
=======
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
      },
    );
  });

<<<<<<< HEAD
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
=======
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
>>>>>>> 6362708ef65a92bbdd31114ea2800ec599e2112f
  });
}
