<?php

namespace App\Http\Controllers;

use App\Models\Schedule;
use App\Models\ScheduleRequests;
use App\Models\MataKuliah;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * API Controller khusus untuk Dosen (Flutter Mobile)
 * Menggunakan Laravel Sanctum — return response()->json()
 */
class ScheduleApiController extends Controller
{
    /**
     * GET /api/schedules
     * Semua jadwal published (bisa difilter per prodi/jurusan)
     * Dipakai dosen untuk melihat jadwal umum
     */
    public function index(Request $request)
    {
        $query = Schedule::where('status', 'PUBLISHED');

        if ($request->filled('id_prodi')) {
            $query->where('id_prodi', $request->id_prodi);
        }

        if ($request->filled('id_jurusan')) {
            $query->where('id_jurusan', $request->id_jurusan);
        }

        if ($request->filled('hari')) {
            $query->where('hari', $request->hari);
        }

        $schedules = $query->orderBy('hari')->orderBy('jam_mulai')->get();

        return response()->json([
            'status' => 'success',
            'data'   => $schedules
        ]);
    }

    /**
     * GET /api/schedules/my
     * Jadwal mengajar dosen yang sedang login (berdasarkan nama_dosen)
     * Dipakai dosen untuk melihat jadwal miliknya sendiri
     */
    public function mySchedules(Request $request)
    {
        $user = Auth::user();

        $query = Schedule::where('nama_dosen', $user->nama)
            ->where('status', 'PUBLISHED');

        if ($request->filled('tipe')) {
            $query->where('tipe', $request->tipe);
        }

        $schedules = $query->orderBy('hari')->orderBy('jam_mulai')->get();

        return response()->json([
            'status' => 'success',
            'data'   => $schedules
        ]);
    }

    /**
     * POST /api/schedules
     * Input jadwal baru via API (dengan collision detection)
     * Opsional — jika Tim Penjadwalan juga butuh akses via API
     */
    public function store(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'id_mk'       => 'required|string',
            'tipe'        => 'required|in:KULIAH,UTS,UAS',
            'hari'        => 'required_if:tipe,KULIAH|string',
            'jam_mulai'   => 'required|date_format:H:i',
            'jam_selesai' => 'required|date_format:H:i|after:jam_mulai',
            'ruangan'     => 'required|string',
            'nama_dosen'  => 'required|string',
        ]);

        $mk = MataKuliah::findOrFail($validated['id_mk']);

        $jamMulai   = Carbon::createFromFormat('H:i', $validated['jam_mulai']);
        $jamSelesai = Carbon::createFromFormat('H:i', $validated['jam_selesai']);

        // Collision Detection
        $conflict = Schedule::where('status', '!=', 'DRAFT')
            ->where('hari', $validated['hari'] ?? null)
            ->where('jam_mulai', '<', $jamSelesai)
            ->where('jam_selesai', '>', $jamMulai)
            ->where(function ($q) use ($validated, $mk, $user) {
                $q->where('ruangan', $validated['ruangan'])
                  ->orWhere('nama_dosen', $validated['nama_dosen'])
                  ->orWhere(function ($sub) use ($mk, $user) {
                      $sub->where('id_mk', $mk->_id)
                          ->where('id_prodi', $user->id_prodi);
                  });
            })->first();

        if ($conflict) {
            return response()->json([
                'status'   => 'error',
                'message'  => 'Bentrok Jadwal Terdeteksi!',
                'conflict' => $conflict
            ], 409);
        }

        $schedule = Schedule::create([
            ...$validated,
            'nama_mk'    => $mk->nama_mk,
            'kode_mk'    => $mk->kode_mk,
            'id_prodi'   => $user->id_prodi,
            'id_jurusan' => $user->id_jurusan,
            'jam_mulai'  => $jamMulai,
            'jam_selesai'=> $jamSelesai,
            'status'     => 'DRAFT',
        ]);

        return response()->json([
            'status' => 'success',
            'data'   => $schedule
        ], 201);
    }

    /**
     * PATCH /api/schedules/{id}/finalize
     * Finalisasi jadwal: DRAFT → FINAL
     */
    public function finalize($id)
    {
        $schedule = Schedule::findOrFail($id);

        if ($schedule->status !== 'DRAFT') {
            return response()->json([
                'status'  => 'error',
                'message' => 'Hanya jadwal berstatus DRAFT yang bisa difinalisasi.'
            ], 422);
        }

        $schedule->update(['status' => 'FINAL']);

        return response()->json([
            'status'  => 'success',
            'message' => 'Jadwal berhasil difinalisasi.'
        ]);
    }

    /**
     * PATCH /api/schedules/{id}/publish
     * Publikasi jadwal: FINAL → PUBLISHED (hanya KAJUR)
     */
    public function publish(Request $request, $id)
    {
        $user = Auth::user();

        if ($user->role !== 'KAJUR') {
            return response()->json([
                'status'  => 'error',
                'message' => 'Akses ditolak. Hanya Kajur yang dapat mempublikasi jadwal.'
            ], 403);
        }

        $request->validate([
            'pesan_pengantar' => 'required|string|min:5'
        ]);

        $schedule = Schedule::findOrFail($id);

        if ($schedule->status !== 'FINAL') {
            return response()->json([
                'status'  => 'error',
                'message' => 'Hanya jadwal berstatus FINAL yang bisa dipublikasikan.'
            ], 422);
        }

        $schedule->update([
            'status'          => 'PUBLISHED',
            'pesan_pengantar' => $request->pesan_pengantar
        ]);

        // TODO: FcmService::sendToTopic('prodi_' . $schedule->id_prodi, '...', $request->pesan_pengantar);

        return response()->json([
            'status'  => 'success',
            'message' => 'Jadwal resmi dipublikasikan ke Mahasiswa!'
        ]);
    }

    // ============================================================
    // SCHEDULE REQUESTS — Khusus Dosen Flutter
    // ============================================================

    /**
     * GET /api/schedule-requests/my
     * Riwayat semua request yang pernah diajukan dosen ini
     */
    public function myRequests()
    {
        $user = Auth::user();

        $requests = ScheduleRequests::where('id_dosen', $user->_id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($req) {
                // Attach data jadwal terkait
                $req->jadwal = Schedule::find($req->id_schedule);
                return $req;
            });

        return response()->json([
            'status' => 'success',
            'data'   => $requests
        ]);
    }

    /**
     * POST /api/schedule-requests
     * Dosen mengajukan request perubahan jadwal
     *
     * Body JSON:
     * {
     *   "id_schedule": "...",
     *   "tipe_request": "Perubahan Ruangan",
     *   "detail_perubahan": { "ruangan": "Lab RPL 2" },
     *   "alasan": "Ruangan sebelumnya sedang direnovasi"
     * }
     */
    public function storeRequest(Request $request)
    {
        $user = Auth::user();

        // Hanya dosen yang bisa mengajukan request
        if ($user->role !== 'DOSEN') {
            return response()->json([
                'status'  => 'error',
                'message' => 'Akses ditolak. Hanya Dosen yang dapat mengajukan request perubahan jadwal.'
            ], 403);
        }

        $request->validate([
            'id_schedule'       => 'required|string',
            'tipe_request'      => 'required|string|max:100',
            'detail_perubahan'  => 'required|array',
            'alasan'            => 'required|string|min:10|max:500',
        ]);

        // Pastikan jadwal yang dimaksud ada dan memang diampu dosen ini
        $jadwal = Schedule::where('_id', $request->id_schedule)
            ->where('nama_dosen', $user->nama)
            ->first();

        if (!$jadwal) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Jadwal tidak ditemukan atau bukan jadwal Anda.'
            ], 404);
        }

        // Cegah duplikasi request pending untuk jadwal yang sama
        $existingPending = ScheduleRequests::where('id_schedule', $request->id_schedule)
            ->where('id_dosen', $user->_id)
            ->where('status', 'PENDING')
            ->first();

        if ($existingPending) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Anda sudah memiliki request yang sedang menunggu untuk jadwal ini. Tunggu hingga diproses terlebih dahulu.'
            ], 422);
        }

        $scheduleRequest = ScheduleRequests::create([
            'id_schedule'      => $request->id_schedule,
            'id_dosen'         => $user->_id,
            'nama_dosen'       => $user->nama,
            'tipe_request'     => $request->tipe_request,
            'detail_perubahan' => $request->detail_perubahan,
            'alasan'           => $request->alasan,
            'status'           => 'PENDING',
            'catatan_admin'    => null,
            'id_processor'     => null,
            'created_at'       => now(),
            'updated_at'       => now(),
        ]);

        return response()->json([
            'status'  => 'success',
            'message' => 'Request perubahan jadwal berhasil diajukan. Menunggu validasi Tim Penjadwalan.',
            'data'    => $scheduleRequest
        ], 201);
    }

    /**
     * DELETE /api/schedule-requests/{id}
     * Dosen membatalkan request yang masih PENDING
     */
    public function cancelRequest($id)
    {
        $user = Auth::user();

        $scheduleRequest = ScheduleRequests::where('_id', $id)
            ->where('id_dosen', $user->_id)
            ->firstOrFail();

        if ($scheduleRequest->status !== 'PENDING') {
            return response()->json([
                'status'  => 'error',
                'message' => 'Hanya request berstatus PENDING yang bisa dibatalkan.'
            ], 422);
        }

        $scheduleRequest->delete();

        return response()->json([
            'status'  => 'success',
            'message' => 'Request berhasil dibatalkan.'
        ]);
    }
}