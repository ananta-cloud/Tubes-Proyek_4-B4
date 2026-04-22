<?php

namespace App\Http\Controllers;

use App\Models\Schedule;
use Illuminate\Http\Request;
use App\Models\MataKuliah;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

class ScheduleController extends Controller
{

    public function index()
    {
        $user = Auth::user();

        // 1. Ambil semua jadwal yang HANYA milik jurusan user yang sedang login
        // Diurutkan berdasarkan hari dan jam mulai agar rapi
        $schedules = Schedule::where('id_jurusan', $user->id_jurusan)
            ->orderBy('hari', 'asc')
            ->orderBy('jam_mulai', 'asc')
            ->get();

        // 2. Hitung statistik untuk Dashboard Tracking (Berdasarkan Jurusan)
        $count_draft = Schedule::where('id_jurusan', $user->id_jurusan)
            ->where('status', 'DRAFT')
            ->count();

        $count_final = Schedule::where('id_jurusan', $user->id_jurusan)
            ->where('status', 'FINAL')
            ->count();

        $count_published = Schedule::where('id_jurusan', $user->id_jurusan)
            ->where('status', 'PUBLISHED')
            ->count();

        // 3. Kirim data ke view admin/jadwal/index.blade.php
        return view('admin.jadwal.index', compact(
            'schedules',
            'count_draft',
            'count_final',
            'count_published'
        ));
    }

    /**
     * MUST HAVE DOCX: Input Jadwal & Collision Detection
     */
    public function store(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'id_mk' => 'required|string',
            'tipe' => 'required|in:KULIAH,UTS,UAS',
            'hari' => 'required_if:tipe,KULIAH|string',
            'jam_mulai' => 'required|date_format:H:i',
            'jam_selesai' => 'required|date_format:H:i|after:jam_mulai',
            'ruangan' => 'required|string',
            'nama_dosen' => 'required|string',
        ]);

        $mk = MataKuliah::findOrFail($validated['id_mk']);

        $jamMulai = Carbon::createFromFormat('H:i', $validated['jam_mulai']);
        $jamSelesai = Carbon::createFromFormat('H:i', $validated['jam_selesai']);

        // LOGIKA COLLISION DETECTION (Bab 4.2 PDF & DOCX)
        $conflictQuery = Schedule::where('status', '!=', 'DRAFT')
            ->where('hari', $validated['hari'] ?? null)
            ->where('jam_mulai', '<', $jamSelesai)
            ->where('jam_selesai', '>', $jamMulai)
            ->where(function($q) use ($validated, $mk, $user) {
                $q->where('ruangan', $validated['ruangan']) // Ruangan bentrok
                  ->orWhere('nama_dosen', $validated['nama_dosen']) // Dosen bentrok
                  ->orWhere(function($subQ) use ($mk, $user) {
                      // Matkul sama dijadwalkan 2x di prodi yang sama pada jam yang sama
                      $subQ->where('id_mk', $mk->_id)
                           ->where('id_prodi', $user->id_prodi);
                  });
            });

        $conflict = $conflictQuery->first();

        if ($conflict) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bentrok Jadwal Terdeteksi!',
                'conflict' => $conflict
            ], 409);
        }

        // Menyimpan Jadwal dengan Partial Embed untuk nama_mk dan kode_mk
        $schedule = Schedule::create([
            ...$validated,
            'nama_mk' => $mk->nama_mk,
            'kode_mk' => $mk->kode_mk,
            'id_prodi' => $user->id_prodi,
            'id_jurusan' => $user->id_jurusan,
            'jam_mulai' => $jamMulai,
            'jam_selesai' => $jamSelesai,
            'status' => 'DRAFT',
        ]);

        return response()->json(['status' => 'success', 'data' => $schedule]);
    }

    /**
     * MUST HAVE DOCX: Finalisasi (Draft -> Final)
     */
    public function finalize($id)
    {
        $schedule = Schedule::findOrFail($id);
        $schedule->update(['status' => 'FINAL']);
        return response()->json(['message' => 'Jadwal berhasil difinalisasi.']);
    }

    /**
     * MUST HAVE DOCX: Publikasi (Hanya Kajur) + Wajib Isi Pesan Pengantar
     */
    public function publish(Request $request, $id)
    {
        $user = Auth::user();

        // RBAC: Hanya KAJUR yang bisa mempublikasikan jadwal
        if ($user->role !== 'KAJUR') {
            return response()->json(['message' => 'Akses ditolak. Hanya Kajur yang dapat mempublikasi jadwal.'], 403);
        }

        $request->validate([
            'pesan_pengantar' => 'required|string|min:5'
        ]);

        $schedule = Schedule::findOrFail($id);
        $schedule->update([
            'status' => 'PUBLISHED',
            'pesan_pengantar' => $request->pesan_pengantar
        ]);

        // Memicu Notifikasi Push via Firebase Cloud Messaging (FCM)
        // FcmService::sendToTopic('prodi_' . $schedule->id_prodi, 'Jadwal Baru Dipublikasikan', $request->pesan_pengantar);

        return response()->json(['status' => 'success', 'message' => 'Jadwal resmi dipublikasikan ke Mahasiswa!']);
    }
}
