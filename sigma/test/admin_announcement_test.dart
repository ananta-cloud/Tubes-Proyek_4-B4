import 'package:flutter_test/flutter_test.dart';
import 'package:sigma/features/announcements/viewmodels/admin_announcement_viewmodel.dart';

void main() {
  group('White-Box Testing: AdminAnnouncementViewModel', () {
    late AdminAnnouncementViewModel viewModel;

    setUp(() {
      viewModel = AdminAnnouncementViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('[TC_WB_AA_01] Method setProdi menyimpan value pada state lokal (Positif)', () {
      /*
       * PREKONDISI: Instance ViewModel Manajemen siap.
       * DATA TEST : parameter = "ID_PRODI_1"
       * EKSPEKTASI: State selectedProdiId berhasil berganti menjadi "ID_PRODI_1".
       */

      // SETUP: Cek state (Awal null)
      expect(viewModel.selectedProdiId, null);

      // EXERCISE 1: Panggil setProdi
      viewModel.setProdi('ID_PRODI_1');
      
      // VERIFY 1: Cek pergantian state
      expect(viewModel.selectedProdiId, 'ID_PRODI_1');

      // EXERCISE 2: Reset
      viewModel.setProdi(null);

      // VERIFY 2: Kembali null
      expect(viewModel.selectedProdiId, null);
    });

    test('[TC_WB_AA_02] Method clearManajemenSelections mereset filter (Positif)', () {
      /*
       * PREKONDISI: Pilihan filter jurusan dan prodi dalam kondisi terisi string.
       * DATA TEST : -
       * EKSPEKTASI: Variabel reset ke null dan array listProdi dikosongkan.
       */

      // SETUP: Injeksi data sementara ke state lokal
      viewModel.setProdi('PRODI_KOTOR');
      
      // EXERCISE: Panggil clearManajemenSelections()
      viewModel.clearManajemenSelections();

      // VERIFY: Cek state dikosongkan
      expect(viewModel.selectedJurusanId, null);
      expect(viewModel.selectedProdiId, null);
      expect(viewModel.listProdi.isEmpty, true);
    });

    test('[TC_WB_AA_03] Method setJurusan diinjeksi dengan argument null (Negatif)', () {
      /*
       * PREKONDISI: Instance ViewModel siap.
       * DATA TEST : parameter = null
       * EKSPEKTASI: Argumen null menahan sistem menembak fetch DB (mencegah NullPointer).
       */

      // SETUP: (Bisa dibiarkan kondisi default)

      // EXERCISE: Panggil setJurusan dengan null
      viewModel.setJurusan(null);

      // VERIFY: Cek blok else yang dieksekusi mematikan filter prodi
      expect(viewModel.selectedJurusanId, null);
      expect(viewModel.selectedProdiId, null);
      expect(viewModel.listProdi.isEmpty, true, reason: 'Prodi harus ikut terhapus jika jurusan null');
    });

    test('[TC_WB_AA_04] Getter list mengembalikan array kosong pada inisiasi awal (Edge Case/Negatif)', () {
      /*
       * PREKONDISI: Instance ViewModel baru diinisialisasi, belum ada data yang di-fetch.
       * DATA TEST : (Kosong)
       * EKSPEKTASI: listJurusan dan listProdi tidak boleh null (harus berupa array kosong []) 
       * untuk mencegah Null Pointer Exception (NPE) saat UI melakukan rendering / iterasi .map().
       */

      // EXERCISE
      final jurusan = viewModel.listJurusan;
      final prodi = viewModel.listProdi;

      // VERIFY
      expect(jurusan, isNotNull, reason: 'listJurusan tidak boleh mereturn null');
      expect(jurusan, isEmpty, reason: 'listJurusan harus berupa array kosong di awal');
      
      expect(prodi, isNotNull, reason: 'listProdi tidak boleh mereturn null');
      expect(prodi, isEmpty, reason: 'listProdi harus berupa array kosong di awal');
    });
  });
}