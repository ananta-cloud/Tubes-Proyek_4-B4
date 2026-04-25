<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Announcement;
use Illuminate\Support\Facades\Auth;
use App\Models\ProgramStudi;


class AnnouncementController extends Controller
{

    public function index()
    {
        $user = Auth::user();

        // 1. Inisialisasi Query Builder
        $query = Announcement::query();

        // 2. Filter RBAC (Role-Based Access Control)
        if ($user->role === 'MANAJEMEN') {
            // Manajemen melihat semua pengumuman umum
            $query->where('target_audience', 'UMUM');

            // Manajemen tidak butuh dropdown prodi saat membuat pengumuman
            $prodiList = [];
        } else {
            // Kajur & TU hanya melihat pengumuman milik jurusannya sendiri
            $query->where('id_jurusan', $user->id_jurusan);

            // Tarik data Prodi HANYA di bawah jurusan ini untuk dropdown "Target Spesifik"
            $prodiList = ProgramStudi::where('id_jurusan', $user->id_jurusan)->get();
        }

        // 3. Eksekusi query: Ambil pengumuman terbaru diurutkan dari yang paling baru
        $announcements = $query->orderBy('created_at', 'desc')->get();

        // 4. Kirim data ke view admin/pengumuman/index.blade.php
        return view('manajemen.announcements.index', compact('announcements', 'prodiList'));
    }

    /**
     * MUST HAVE DOCX: Publikasi Pengumuman (Manajemen vs Jurusan)
     */
    public function store(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'judul' => 'required|string',
            'isi' => 'required|string',
            'kategori' => 'nullable|string', // Kategori: Akademik, Beasiswa, Lomba (Could Have DOCX)
        ]);

        // Filter Target Otomatis berdasarkan Role Pengguna
        if ($user->role === 'MANAJEMEN') {
            $targetAudience = 'UMUM';
            $idJurusan = null;
            $idProdi = null;
        } else {
            $targetAudience = 'PRODI';
            $idJurusan = $user->id_jurusan;
            $idProdi = $request->id_prodi ?? null; // Targeting spesifik prodi (Should Have)
        }

        $announcement = Announcement::create([
            ...$validated,
            'target_audience' => $targetAudience,
            'id_jurusan' => $idJurusan,
            'id_prodi' => $idProdi,
            'target_angkatan' => $request->target_angkatan,
            'id_publisher' => $user->id,
            'nama_publisher' => $user->name, // Partial Embed sesuai PDF Bab 4.2
            'role_publisher' => $user->role,
            'read_by_users' => [] // Array kosong untuk Read Confirmation
        ]);

        // FcmService::sendToTopic('all_mahasiswa', 'Pengumuman Baru: ' . $announcement->judul, $announcement->isi);

        return response()->json(['status' => 'success', 'data' => $announcement]);
    }

    /**
     * COULD HAVE DOCX: Cross-posting Helper (Generate format WA/IG)
     */
    public function crossPostFormat($id)
    {
        $announcement = Announcement::findOrFail($id);

        $text = "*[PENGUMUMAN POLBAN]*\n\n";
        $text .= "*" . strtoupper($announcement->judul) . "*\n\n";
        $text .= $announcement->isi . "\n\n";
        $text .= "_Cek detail lengkapnya dan simpan ke bookmark di Aplikasi SIGMA._";

        return response()->json(['whatsapp_format' => $text]);
    }
}

