<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class AnnouncementAPIController extends Controller
{
    /**
     * GET /api/announcements
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Announcement::query();

        // FILTER OTOMATIS BERDASARKAN ROLE & JURUSAN USER YANG LOGIN
        if ($user) {
            $role = strtoupper($user->role);

            if ($role === 'MAHASISWA') {
                $allowed = ['SEMUA', 'SEMUA_MAHASISWA'];

                // Tambahkan filter PRODI jika user punya id_jurusan
                if ($user->id_jurusan) {
                    $query->where(function($q) use ($user, $allowed) {
                        $q->whereIn('target_audience', $allowed)
                          ->orWhere(function($sub) use ($user) {
                              $sub->whereIn('target_audience', ['PRODI_MAHASISWA', 'PRODI_SEMUA'])
                                  ->where('id_jurusan', $user->id_jurusan);
                          });
                    });
                } else {
                    // Jika tidak ada id_jurusan, hanya tampilkan yang scope global
                    $query->whereIn('target_audience', $allowed);
                }

            } elseif ($role === 'DOSEN') {
                $allowed = ['SEMUA', 'SEMUA_DOSEN'];

                if ($user->id_jurusan) {
                    $query->where(function($q) use ($user, $allowed) {
                        $q->whereIn('target_audience', $allowed)
                          ->orWhere(function($sub) use ($user) {
                              $sub->whereIn('target_audience', ['PRODI_DOSEN', 'PRODI_SEMUA'])
                                  ->where('id_jurusan', $user->id_jurusan);
                          });
                    });
                } else {
                    $query->whereIn('target_audience', $allowed);
                }
            }
        }
        // Jika $user null → tidak ada filter target_audience, semua data tampil

        // Jika Flutter mengirimkan parameter filter pencarian tambahan
        if ($request->filled('kategori')) {
            $query->where(function ($q) use ($request) {
                $q->where('kategori', 'like', '%' . $request->kategori . '%')
                  ->orWhere('judul', 'like', '%' . $request->kategori . '%')
                  ->orWhere('isi', 'like', '%' . $request->kategori . '%');
            });
        }

        // Urutkan dari yang paling baru
        $announcements = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data'   => $announcements,
        ], 200);
    }

    /**
     * GET /api/announcements/{id}
     * Mengambil detail satu pengumuman berdasarkan ID
     */
    public function show(string $id)
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
     * Jika Dosen/Kajur diizinkan membuat pengumuman via Mobile
     */
    public function store(Request $request)
    {
        $user = Auth::user();

        // Batasi siapa yang bisa membuat pengumuman
        if (!in_array(strtoupper($user->role), ['KAJUR', 'DOSEN', 'ADMIN', 'MANAJEMEN'])) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Akses ditolak. Anda tidak memiliki izin membuat pengumuman.'
            ], 403);
        }

        $validated = $request->validate([
            'judul'           => 'required|string|max:255',
            'isi'             => 'required|string',
            'kategori'        => 'required|string',
            'target_audience' => 'required|string',
        ]);

        $announcement = Announcement::create([
            'judul'           => $validated['judul'],
            'isi'             => $validated['isi'],
            'kategori'        => $validated['kategori'],
            'target_audience' => $validated['target_audience'],
            'id_jurusan'      => $user->id_jurusan ?? null,
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

    /**
     * PUT/PATCH /api/announcements/{id}
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        // Logika update jika diperlukan
    }

    /**
     * DELETE /api/announcements/{id}
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        // Logika delete jika diperlukan
    }
}
