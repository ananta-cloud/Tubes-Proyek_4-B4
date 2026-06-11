import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

// Sesuaikan path import ini jika berbeda di struktur folder Anda
import 'package:sigma/features/dosen/tasks/viewmodels/task_form_viewmodel.dart';
import 'package:sigma/data/models/task_model.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/pengajaran_model.dart'; 

void main() {
  group('White-Box Testing: TaskFormViewModel', () {
    late TaskFormViewModel viewModel;
    late Directory tempDir;

    // =========================================================================
    // SETUP ALL: Dijalankan 1 kali sebelum semua test dimulai (Khusus Mock Hive)
    // =========================================================================
    setUpAll(() async {
      // 1. Buat folder temporary untuk simulasi database Hive di memori PC/Laptop
      tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);

      // 2. Daftarkan Adapter agar Hive mengenali tipe data model Anda
      // (Pastikan nama adapter sesuai dengan yang di-generate di file .g.dart)
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(TaskModelAdapter());
      }
      // Asumsikan kita juga perlu Pengajaran adapter
      Hive.registerAdapter(PengajaranModelAdapter());

      // 3. Buka semua Box yang dipanggil secara synchronous oleh Repository & ViewModel
      await Hive.openBox<PengajaranModel>('pengajaran');
      await Hive.openBox<TaskModel>('tasks');
      await Hive.openBox<String>('kelasCacheBox');
    });

    // =========================================================================
    // TEARDOWN ALL: Bersihkan memori dan hapus folder Hive setelah selesai
    // =========================================================================
    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // Setup & TearDown per-test
    setUp(() {
      viewModel = TaskFormViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    // ---------------------------------------------------------
    // TC_WB_TF_01 (Positif): toggleKelas (Branching If-Else)
    // ---------------------------------------------------------
    test('[TC_WB_TF_01] Method toggleKelas mengeksekusi penambahan array (Positif)', () {
      // SETUP
      expect(viewModel.selectedTargetKelas.isEmpty, true, reason: 'State awal harus kosong');

      // EXERCISE
      viewModel.toggleKelas('1A-D3');

      // VERIFY
      expect(viewModel.selectedTargetKelas.contains('1A-D3'), true);
      expect(viewModel.selectedTargetKelas.length, 1);
    });

    // ---------------------------------------------------------
    // TC_WB_TF_02 (Positif): initializeForEdit memetakan state
    // ---------------------------------------------------------
    test('[TC_WB_TF_02] Method initializeForEdit memetakan data model (Positif)', () {
      // SETUP - Buat mock TaskModel
      final mockTask = TaskModel(
        id: 'task_123',
        idUser: 'user_1',
        namaTugas: 'Proyek Akhir',
        deskripsi: 'Deskripsi singkat',
        kodeMk: 'IF101',
        deadline: DateTime(2026, 12, 1),
        status: 'BELUM',
        isSynced: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lampiran: [{'name': 'dokumen.pdf', 'data': 'base64'}],
      );

      // EXERCISE
      viewModel.initializeForEdit(mockTask);

      // VERIFY
      expect(viewModel.namaTugasController.text, 'Proyek Akhir');
      expect(viewModel.deskripsiController.text, 'Deskripsi singkat');
      expect(viewModel.selectedDeadline, DateTime(2026, 12, 1));
      expect(viewModel.lampiran.length, 1);
    });

    // ---------------------------------------------------------
    // TC_WB_TF_03 (Negatif): createTaskForStudents return false jika wajib kosong
    // ---------------------------------------------------------
    test('[TC_WB_TF_03] Method createTaskForStudents return false jika field wajib kosong (Negatif)', () async {
      // SETUP - Nama kosong
      viewModel.namaTugasController.text = '';
      final mockUser = UserModel(
        id: '123', 
        nama: 'Dosen A', 
        email: 'a@polban.ac.id', 
        role: 'DOSEN'
      );

      // EXERCISE
      bool result = await viewModel.createTaskForStudents(mockUser);

      // VERIFY
      expect(result, false, reason: 'Validasi harus menahan form jika nama tugas kosong');
    });

    // ---------------------------------------------------------
    // TC_WB_TF_04 (Negatif): removeAttachment memicu RangeError
    // ---------------------------------------------------------
    test('[TC_WB_TF_04] Method removeAttachment memicu RangeError jika array kosong (Negatif)', () {
      // SETUP
      expect(viewModel.lampiran.isEmpty, true);

      // EXERCISE & VERIFY
      expect(() => viewModel.removeAttachment(0), throwsRangeError, 
          reason: 'Harus melempar exception karena array belum memiliki elemen');
    });
  });
}