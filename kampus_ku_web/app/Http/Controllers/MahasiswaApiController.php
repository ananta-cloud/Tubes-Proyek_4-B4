<?php

namespace App\Http\Controllers;

use App\Models\Schedule;
use App\Models\Announcement;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

class MahasiswaApiController extends Controller
{
    /**
     * MUST HAVE DOCX: Auto Sync (Offline Cache Pull untuk Flutter Hive)
     */
    public function syncData()
    {
        $user = Auth::user();

        // 1. Tarik Jadwal Kuliah & Ujian (Sesuai Prodi, Status PUBLISHED)
        $schedules = Schedule::where('id_prodi', $user->id_prodi)
            ->where('status', 'PUBLISHED')
            ->get();

        // 2. Tarik Pengumuman (Target UMUM + Target Spesifik PRODI mahasiswa)
        $announcements = Announcement::where(function($q) use ($user) {
            $q->where('target_audience', 'UMUM')
              ->orWhere(function($sub) use ($user) {
                  $sub->where('target_audience', 'PRODI')
                      ->where('id_jurusan', $user->id_jurusan)
                      ->where(function($prodiQ) use ($user) {
                          $prodiQ->whereNull('id_prodi')
                                 ->orWhere('id_prodi', $user->id_prodi);
                      });
              });
        })->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'last_sync' => Carbon::now()->toIso8601String(),
            'data' => [
                'schedules' => $schedules,
                'announcements' => $announcements,
            ]
        ]);
    }

    /**
     * SHOULD HAVE DOCX: Read Confirmation
     */
    public function markAsRead($id)
    {
        $user = Auth::user();

        // Memasukkan ID Mahasiswa ke dalam array 'read_by_users' (Fitur MongoDB Push)
        Announcement::where('_id', $id)->push('read_by_users', $user->id, true);

        return response()->json(['status' => 'success']);
    }
}
