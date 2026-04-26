<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class AnnouncementAPIController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $user = Auth::user();
        $query = Announcement::query();

        if ($user && $user->role === 'MAHASISWA') {
            $allowed = ['SEMUA', 'SEMUA_MAHASISWA'];

            // Tambahkan PRODI jika user punya id_jurusan
            if ($user->id_jurusan) {
                $query->where(function($q) use ($user, $allowed) {
                    $q->whereIn('target_audience', $allowed)
                    ->orWhere(function($sub) use ($user) {
                        $sub->whereIn('target_audience', ['PRODI_MAHASISWA', 'PRODI_SEMUA'])
                            ->where('id_jurusan', $user->id_jurusan);
                    });
                });
            } else {
                // Jika tidak ada id_jurusan, hanya tampilkan yang SEMUA
                $query->whereIn('target_audience', $allowed);
            }

        } elseif ($user && $user->role === 'DOSEN') {
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
        // Jika $user null → tidak ada filter, semua data tampil

        $announcements = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data'    => $announcements,
        ], 200);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
