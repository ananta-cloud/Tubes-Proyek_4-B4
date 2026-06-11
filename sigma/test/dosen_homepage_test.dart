import 'package:flutter_test/flutter_test.dart';
import 'package:sigma/features/dosen/dashboard/viewmodels/home_page_viewmodel.dart';

void main() {
  group('White-Box Testing: DosenHomeViewModel', () {
    late DosenHomeViewModel viewModel;

    setUp(() {
      viewModel = DosenHomeViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('[TC_WB_HM_01] Inisialisasi state currentIndex (Positif)', () {
      /*
       * PREKONDISI: Objek DosenHomeViewModel belum diinisialisasi.
       * DATA TEST : -
       * EKSPEKTASI: Nilai currentIndex secara default (awal) bernilai 0.
       */

      // SETUP: Buat instance baru (sudah di setUp)

      // EXERCISE: Akses getter currentIndex
      final initialIndex = viewModel.currentIndex;

      // VERIFY: Periksa nilai variabel
      expect(initialIndex, 0, reason: 'Current index awal harus 0');
    });

    test(
      '[TC_WB_HM_02] Method setIndex mengubah state dan memicu listener (Positif)',
      () {
        /*
       * PREKONDISI: Instance ViewModel tersedia, attach listener untuk memantau perubahan.
       * DATA TEST : index = 2
       * EKSPEKTASI: currentIndex berubah menjadi 2, dan notifyListeners() tereksekusi.
       */

        // SETUP: Tambahkan addListener pada ViewModel
        bool isListenerTriggered = false;
        viewModel.addListener(() {
          isListenerTriggered = true;
        });

        // EXERCISE: Panggil viewModel.setIndex(2)
        viewModel.setIndex(2);

        // VERIFY: Cek currentIndex dan pastikan listener tertrigger
        expect(
          viewModel.currentIndex,
          2,
          reason: 'Index harus berubah menjadi 2',
        );
        expect(
          isListenerTriggered,
          true,
          reason: 'Listener harus terpanggil saat index diubah',
        );
      },
    );

    test(
      '[TC_WB_HM_03] Getter greeting merespon parameter waktu saat ini (Positif)',
      () {
        /*
       * PREKONDISI: Instance ViewModel tersedia.
       * DATA TEST : Jam sistem (Local time)
       * EKSPEKTASI: Mengembalikan string "Selamat Pagi/Siang/Malam" sesuai jam saat testing.
       */

        // SETUP: Ambil waktu sistem
        final currentHour = DateTime.now().hour;

        // EXERCISE: Akses properti viewModel.greeting
        final greetingMessage = viewModel.greeting;

        // VERIFY: Cocokkan string berdasarkan rentang jam
        if (currentHour < 12) {
          expect(greetingMessage, 'Selamat Pagi, Bapak/Ibu');
        } else if (currentHour < 17) {
          expect(greetingMessage, 'Selamat Siang, Bapak/Ibu');
        } else {
          expect(greetingMessage, 'Selamat Malam, Bapak/Ibu');
        }
      },
    );
  });
}
