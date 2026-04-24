<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;
use App\Models\User;
use App\Models\Jurusan;
use App\Models\ProgramStudi;
use App\Models\MataKuliah;
use App\Models\PeriodeAkademik;
use App\Models\Schedule;
use App\Models\Announcement;
use MongoDB\BSON\ObjectId;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        // 1. Bersihkan data sebelumnya
        User::truncate();
        Jurusan::truncate();
        ProgramStudi::truncate();
        MataKuliah::truncate();
        PeriodeAkademik::truncate();
        Schedule::truncate();
        Announcement::truncate();

        // 2. Seeder Jurusan
        $jurusanJTK = Jurusan::create([
            'kode_jurusan' => 'JTK',
            'nama_jurusan' => 'Teknik Komputer dan Informatika'
        ]);

        $jurusanAN = Jurusan::create([
            'kode_jurusan' => 'AN',
            'nama_jurusan' => 'Administrasi Niaga'
        ]);

        // 3. Seeder Program Studi (Bungkus id_jurusan dengan ObjectId)
        $prodiD3TKI = ProgramStudi::create([
            'kode_prodi' => 'D3-TKI',
            'nama_prodi' => 'D3 Teknik Informatika',
            'id_jurusan' => new ObjectId($jurusanJTK->id)
        ]);

        $prodiD4TKI = ProgramStudi::create([
            'kode_prodi' => 'D4-TKI',
            'nama_prodi' => 'D4 Teknik Informatika',
            'id_jurusan' => new ObjectId($jurusanJTK->id)
        ]);

        // 4. Seeder Mata Kuliah (Bungkus id_prodi dengan ObjectId)
        $mkWeb = MataKuliah::create([
            'kode_mk' => 'IF102',
            'nama_mk' => 'Pemrograman Web Bergerak',
            'sks' => 4,
            'id_prodi' => new ObjectId($prodiD3TKI->id)
        ]);

        $mkAI = MataKuliah::create([
            'kode_mk' => 'IF301',
            'nama_mk' => 'Kecerdasan Buatan',
            'sks' => 3,
            'id_prodi' => new ObjectId($prodiD3TKI->id)
        ]);

        // 5. Seeder Periode Akademik
        $periodeGenap = PeriodeAkademik::create([
            'tahun_akademik' => '2025/2026',
            'jenis_semester' => 'GENAP',
            'is_aktif' => true,
            'tanggal_mulai' => Carbon::create(2026, 2, 1),
            'tanggal_selesai' => Carbon::create(2026, 7, 31)
        ]);

        // 6. Seeder Users (Bungkus semua foreign key relasi dengan ObjectId)
        $manajemen = User::create([
            'nama' => 'Bpk. Rektorat Manajemen',
            'email' => 'admin.pusat@polban.ac.id',
            'password' => Hash::make('password123'),
            'role' => 'MANAJEMEN',
            'id_jurusan' => null,
            'id_prodi' => null,
        ]);

        $kajur = User::create([
            'nama' => 'Bpk. Kajur TKI',
            'email' => 'kajur.jtk@polban.ac.id',
            'password' => Hash::make('password123'),
            'role' => 'KAJUR',
            'id_jurusan' => new ObjectId($jurusanJTK->id),
            'id_prodi' => null,
        ]);

        $tu = User::create([
            'nama' => 'Ibu Admin TU',
            'email' => 'admin.tu@polban.ac.id',
            'password' => Hash::make('password123'),
            'role' => 'ADMIN_TU',
            'id_jurusan' => new ObjectId($jurusanJTK->id),
            'id_prodi' => null,
        ]);

        $mahasiswa = User::create([
            'nama' => 'Fahraj Ananta Aulia Arkan',
            'email' => 'fahraj.mhs@polban.ac.id',
            'password' => Hash::make('password123'),
            'role' => 'MAHASISWA',
            'id_jurusan' => new ObjectId($jurusanJTK->id),
            'id_prodi' => new ObjectId($prodiD3TKI->id),
        ]);

        // 7. Seeder Schedule (Bungkus semua foreign key relasi dengan ObjectId)
        Schedule::create([
            'id_mk' => new ObjectId($mkWeb->id),
            'nama_mk' => $mkWeb->nama_mk,
            'kode_mk' => $mkWeb->kode_mk,
            'id_prodi' => new ObjectId($prodiD3TKI->id),
            'id_jurusan' => new ObjectId($jurusanJTK->id),
            'tipe' => 'KULIAH',
            'hari' => 'KAMIS', // <-- UBAH KE UPPERCASE
            'tanggal' => null,
            'jam_mulai' => '08:00', // <-- UBAH JADI STRING BIASA (BUKAN CARBON)
            'jam_selesai' => '11:30', // <-- UBAH JADI STRING BIASA
            'ruangan' => 'Lab RPL 2',
            'nama_dosen' => 'Marlina, S.T., M.Kom.',
            'status' => 'PUBLISHED',
            'pesan_pengantar' => 'Jadwal Kuliah Semester Genap Resmi Dirilis.',
            'id_periode' => new ObjectId($periodeGenap->id)
        ]);

        Schedule::create([
            'id_mk' => new ObjectId($mkAI->id),
            'nama_mk' => $mkAI->nama_mk,
            'kode_mk' => $mkAI->kode_mk,
            'id_prodi' => new ObjectId($prodiD3TKI->id),
            'id_jurusan' => new ObjectId($jurusanJTK->id),
            'tipe' => 'KULIAH',
            'hari' => 'RABU', // <-- UBAH KE UPPERCASE
            'tanggal' => null,
            'jam_mulai' => '13:00', // <-- UBAH JADI STRING BIASA
            'jam_selesai' => '15:30', // <-- UBAH JADI STRING BIASA
            'ruangan' => 'Ruang Kelas 301',
            'nama_dosen' => 'Santi Sundari, S.T., M.T.',
            'status' => 'DRAFT',
            'pesan_pengantar' => null,
            'id_periode' => new ObjectId($periodeGenap->id)
        ]);
        
        // 8. Seeder Announcement (Bungkus foreign key, termasuk di dalam array read_by_users)
        Announcement::create([
            'judul' => 'Pendaftaran Beasiswa JFL 2026',
            'isi' => 'Diberitahukan kepada seluruh mahasiswa bahwa pendaftaran Jabar Future Leaders Scholarship telah dibuka.',
            'kategori' => 'Beasiswa',
            'target_audience' => 'UMUM',
            'target_angkatan' => null,
            'id_prodi' => null,
            'id_jurusan' => null,
            'id_publisher' => new ObjectId($manajemen->id),
            'nama_publisher' => $manajemen->nama,
            'role_publisher' => $manajemen->role,
            'read_by_users' => [
                new ObjectId($mahasiswa->id)
            ]
        ]);

        Announcement::create([
            'judul' => 'Perubahan Ruang Kelas',
            'isi' => 'Mohon diperhatikan, kelas Basis Data 1A dipindahkan ke Lab Jarkom.',
            'kategori' => 'Akademik',
            'target_audience' => 'PRODI',
            'target_angkatan' => '2025',
            'id_prodi' => new ObjectId($prodiD3TKI->id),
            'id_jurusan' => new ObjectId($jurusanJTK->id),
            'id_publisher' => new ObjectId($kajur->id),
            'nama_publisher' => $kajur->nama,
            'role_publisher' => $kajur->role,
            'read_by_users' => []
        ]);

        // Feedback ke console terminal
        $this->command->info('Database SIGMA berhasil diisi dengan data dummy awal!');
    }
}
