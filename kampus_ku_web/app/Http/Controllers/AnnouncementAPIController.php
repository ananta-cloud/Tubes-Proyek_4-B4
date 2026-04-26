<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * API Controller khusus untuk Pengumuman (Flutter Mobile)
 * Menggunakan Laravel Sanctum — return response()->json()
 */
class AnnouncementApiController extends Controller
{
    /**
     * GET /api/announcements
     * Mengambil daftar pengumuman terbaru
     * Bisa difilter berdasarkan target_audience/kategori
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Announcement::query();

        // 🔥 FILTER OTOMATIS BERDASARKAN ROLE USER YANG LOGIN
        if ($user) {
            $role = strtoupper($user->role);

            if ($role === 'DOSEN') {
                // Dosen HANYA melihat pengumuman untuk Dosen, Umum, atau Semua
                $query->where(function ($q) {
                    $q->where('target_audience', 'like', '%dosen%')
                      ->orWhere('target_audience', 'like', '%umum%')
                      ->orWhere('target_audience', 'like', '%semua%')
                      ->orWhere('kategori', 'like', '%dosen%')
                      ->orWhere('kategori', 'like', '%umum%');
                });
            } elseif ($role === 'MAHASISWA') {
                // Mahasiswa HANYA melihat pengumuman untuk Mahasiswa, Umum, atau Semua
                $query->where(function ($q) {
                    $q->where('target_audience', 'like', '%mahasiswa%')
                      ->orWhere('target_audience', 'like', '%umum%')
                      ->orWhere('target_audience', 'like', '%semua%')
                      ->orWhere('kategori', 'like', '%mahasiswa%')
                      ->orWhere('kategori', 'like', '%umum%');
                });
            }
        }

        // Jika Flutter mengirimkan parameter filter tambahan (misal: pencarian)
        if ($request->filled('kategori')) {
            $query->where(function ($q) use ($request) {
                $q->where('kategori', 'like', '%' . $request->kategori . '%')
                  ->orWhere('target_audience', 'like', '%' . $request->kategori . '%');
            });
        }

        // Urutkan dari yang paling baru
        $announcements = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data'   => $announcements
        ], 200);
    }

    /**
     * GET /api/announcements/{id}
     * Mengambil detail satu pengumuman berdasarkan ID
     */
    public function show($id)
    {
        $announcement = Announcement::find($id);

        if (!$announcement) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Pengumuman tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data'   => $announcement
        ], 200);
    }

    /**
     * POST /api/announcements
     * (Opsional) Jika Dosen/Kajur diizinkan membuat pengumuman via Mobile
     */
    public function store(Request $request)
    {
        $user = Auth::user();

        // Batasi siapa yang bisa membuat pengumuman
        if (!in_array($user->role, ['KAJUR', 'DOSEN', 'ADMIN'])) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Akses ditolak. Anda tidak memiliki izin membuat pengumuman.'
            ], 403);
        }

        $validated = $request->validate([
            'judul'           => 'required|string|max:255',
            'isi'             => 'required|string',
            'kategori'        => 'required|string', // atau target_audience
            // Tambahkan validasi lain sesuai kolom di database Anda
        ]);

        $announcement = Announcement::create([
            'judul'           => $validated['judul'],
            'isi'             => $validated['isi'],
            'kategori'        => $validated['kategori'],
            'id_pembuat'      => $user->_id ?? $user->id,
            'nama_pembuat'    => $user->nama,
            'created_at'      => now(),
            'updated_at'      => now(),
        ]);

        return response()->json([
            'status'  => 'success',
            'message' => 'Pengumuman berhasil dibuat.',
            'data'    => $announcement
        ], 201);
    }
}
