import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sigma/data/models/schedule_local_model.dart';
import 'package:sigma/data/services/schedule_service.dart';
import 'package:sigma/features/dosen/schedules/viewmodels/schedule_controller.dart';

import 'schedule_controller_test.mocks.dart';

@GenerateMocks([ScheduleService])
void main() {
  late MockScheduleService mockService;
  late ScheduleController controller;
  late Box<ScheduleLocalModel> box;
  late Directory tempDir;

  ScheduleLocalModel makeModel({
    String id = 'id1',
    String namaMk = 'Basis Data',
    String hari = 'SENIN',
    String jamMulai = '07:30',
    String jamSelesai = '09:10',
    String ruangan = 'Lab A',
    String dosen = 'Bu Ani',
  }) => ScheduleLocalModel(
    id: id,
    namaMk: namaMk,
    hari: hari,
    jamMulai: jamMulai,
    jamSelesai: jamSelesai,
    ruangan: ruangan,
    dosen: dosen,
  );

  Map<String, dynamic> makeRaw({
    String id = 'id1',
    String? namaMk = 'Basis Data',
    String? hari = 'SENIN',
    String? jamMulai = '07:30',
    String? jamSelesai = '09:10',
    String? ruangan = 'Lab A',
    String? namaDosen = 'Bu Ani',
  }) => {
    '_id': id,
    'nama_mk': namaMk,
    'hari': hari,
    'jam_mulai': jamMulai,
    'jam_selesai': jamSelesai,
    'ruangan': ruangan,
    'nama_dosen': namaDosen,
  };

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_sc_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScheduleLocalModelAdapter());
    }
    box = await Hive.openBox<ScheduleLocalModel>('schedules');
    mockService = MockScheduleService();
    controller = ScheduleController(mockService);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // TC01
  group(
    'TC01 - syncSchedules berhasil ambil data dari MongoDB dan simpan ke Hive',
    () {
      test(
        'schedules berisi 3 item, isLoading false, notifyListeners terpanggil',
        () async {
          when(mockService.getSchedules()).thenAnswer(
            (_) async => [
              makeRaw(id: 'id1', namaMk: 'Basis Data'),
              makeRaw(id: 'id2', namaMk: 'Pemrograman Web'),
              makeRaw(id: 'id3', namaMk: 'Jaringan Komputer'),
            ],
          );

          int notifyCount = 0;
          controller.addListener(() => notifyCount++);

          await controller.syncSchedules();

          expect(controller.schedules.length, 3);
          expect(box.length, 3);
          expect(controller.isLoading, false);
          expect(notifyCount, greaterThan(0));
        },
      );
    },
  );

  // TC02
  group(
    'TC02 - syncSchedules membersihkan cache lama sebelum mengisi data baru',
    () {
      test(
        'schedules berisi 4 item baru (bukan 6), box.clear() dipanggil',
        () async {
          await box.put('old1', makeModel(id: 'old1', namaMk: 'MK Lama 1'));
          await box.put('old2', makeModel(id: 'old2', namaMk: 'MK Lama 2'));

          when(mockService.getSchedules()).thenAnswer(
            (_) async => [
              makeRaw(id: 'new1', namaMk: 'Data Mining'),
              makeRaw(id: 'new2', namaMk: 'AI'),
              makeRaw(id: 'new3', namaMk: 'IoT'),
              makeRaw(id: 'new4', namaMk: 'Cloud Computing'),
            ],
          );

          await controller.syncSchedules();

          expect(controller.schedules.length, 4);
          expect(
            controller.schedules.any((s) => s.namaMk == 'MK Lama 1'),
            false,
          );
          expect(controller.isLoading, false);
        },
      );
    },
  );

  // TC03
  group(
    'TC03 - syncSchedules memetakan field MongoDB ke ScheduleLocalModel dengan benar',
    () {
      test('setiap field model sesuai dengan data MongoDB', () async {
        when(mockService.getSchedules()).thenAnswer(
          (_) async => [
            makeRaw(
              id: 'abc123',
              namaMk: 'Basis Data',
              hari: 'SENIN',
              jamMulai: '07:30',
              jamSelesai: '09:10',
              ruangan: 'Lab A',
              namaDosen: 'Bu Ani',
            ),
          ],
        );

        await controller.syncSchedules();

        final model = controller.schedules.first;
        expect(model.id, 'abc123');
        expect(model.namaMk, 'Basis Data');
        expect(model.hari, 'SENIN');
        expect(model.jamMulai, '07:30');
        expect(model.jamSelesai, '09:10');
        expect(model.ruangan, 'Lab A');
        expect(model.dosen, 'Bu Ani');
      });
    },
  );

  // TC04
  group(
    'TC04 - syncSchedules menggunakan nilai default \'-\' jika field null',
    () {
      test('semua field null menghasilkan "-" bukan null/crash', () async {
        when(mockService.getSchedules()).thenAnswer(
          (_) async => [
            makeRaw(
              id: 'nullId',
              namaMk: null,
              hari: null,
              jamMulai: null,
              jamSelesai: null,
              ruangan: null,
              namaDosen: null,
            ),
          ],
        );

        await controller.syncSchedules();

        final model = controller.schedules.first;
        expect(model.namaMk, '-');
        expect(model.hari, '-');
        expect(model.jamMulai, '-');
        expect(model.jamSelesai, '-');
        expect(model.ruangan, '-');
        expect(model.dosen, '-');
      });
    },
  );

  // TC05
  group(
    'TC05 - syncSchedules fallback ke Hive cache jika MongoDB throw exception',
    () {
      test(
        'schedules berisi 2 item dari cache, isLoading false, tidak crash',
        () async {
          await box.put('c1', makeModel(id: 'c1', namaMk: 'Cached MK 1'));
          await box.put('c2', makeModel(id: 'c2', namaMk: 'Cached MK 2'));
          when(mockService.getSchedules()).thenThrow(Exception('Mongo error'));

          await controller.syncSchedules();

          expect(controller.schedules.length, 2);
          expect(controller.isLoading, false);
        },
      );
    },
  );

  // TC06
  group(
    'TC06 - syncSchedules fallback ke Hive kosong jika cache tidak ada dan MongoDB gagal',
    () {
      test('schedules = [], isLoading false, tidak crash', () async {
        when(mockService.getSchedules()).thenThrow(Exception('Mongo error'));

        await controller.syncSchedules();

        expect(controller.schedules, isEmpty);
        expect(controller.isLoading, false);
      });
    },
  );

  // TC07
  group(
    'TC07 - syncSchedules return data kosong jika MongoDB return list kosong',
    () {
      test('box.clear() dipanggil, schedules = [], isLoading false', () async {
        await box.put('old1', makeModel(id: 'old1'));
        when(mockService.getSchedules()).thenAnswer((_) async => []);

        await controller.syncSchedules();

        expect(controller.schedules, isEmpty);
        expect(box.isEmpty, true);
        expect(controller.isLoading, false);
      });
    },
  );
}
