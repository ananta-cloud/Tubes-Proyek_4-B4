<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Schedule;
use App\Models\ScheduleRequests;
use App\Models\MataKuliah;
use Carbon\Carbon;

class ScheduleController extends Controller
{

    /**
     * Dashboard utama Tim Penjadwalan
     */
    public function dashboard()
    {
        $user      = Auth::user();
        $idJurusan = $user->id_jurusan;

        $count_draft     = Schedule::where('id_jurusan', $idJurusan)->where('status', 'DRAFT')->count();
        $count_final     = Schedule::where('id_jurusan', $idJurusan)->where('status', 'FINAL')->count();
        $count_published = Schedule::where('id_jurusan', $idJurusan)->where('status', 'PUBLISHED')->count();
        $total           = $count_draft + $count_final + $count_published;

        $scheduleIds      = Schedule::where('id_jurusan', $idJurusan)->pluck('_id')->toArray();
        $pending_requests = ScheduleRequests::whereIn('id_schedule', $scheduleIds)->where('status', 'PENDING')->count();

        $schedules = Schedule::where('id_jurusan', $idJurusan)
            ->orderBy('updated_at', 'desc')
            ->limit(5)
            ->get();

        return view('penjadwalan.dashboard', compact(
            'schedules', 'count_draft', 'count_final', 'count_published', 'total', 'pending_requests'
        ));
    }

    /**
     * Daftar jadwal lengkap + filter & search
     */
    public function index(Request $request)
    {
        $user      = Auth::user();
        $idJurusan = $user->id_jurusan;

        $query = Schedule::where('id_jurusan', $idJurusan);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nama_mk', 'like', "%{$search}%")
                  ->orWhere('nama_dosen', 'like', "%{$search}%")
                  ->orWhere('ruangan', 'like', "%{$search}%");
            });
        }

        if ($request->filled('hari'))   $query->where('hari', $request->hari);
        if ($request->filled('status')) $query->where('status', $request->status);
        if ($request->filled('tipe'))   $query->where('tipe', $request->tipe);

        $schedules = $query->orderBy('hari')->orderBy('jam_mulai')->get();

        $count_draft     = Schedule::where('id_jurusan', $idJurusan)->where('status', 'DRAFT')->count();
        $count_final     = Schedule::where('id_jurusan', $idJurusan)->where('status', 'FINAL')->count();
        $count_published = Schedule::where('id_jurusan', $idJurusan)->where('status', 'PUBLISHED')->count();
        $total           = $count_draft + $count_final + $count_published;

        $scheduleIds      = Schedule::where('id_jurusan', $idJurusan)->pluck('_id')->toArray();
        $pending_requests = ScheduleRequests::whereIn('id_schedule', $scheduleIds)->where('status', 'PENDING')->count();

        return view('penjadwalan.schedules.index', compact(
            'schedules', 'count_draft', 'count_final', 'count_published', 'total', 'pending_requests'
        ));
    }

    /**
     * Form input jadwal baru
     */
    public function create()
    {
        $user = Auth::user();

        $masterMatkul = MataKuliah::where('id_prodi', $user->id_prodi)->get();

        return view('penjadwalan.schedules.create', compact('masterMatkul'));
    }

    /**
     * Simpan jadwal baru + Collision Detection
     */
    public function store(Request $request)
    {
        $request->validate([
            'id_mk'       => 'required',
            'nama_mk'     => 'required|string|max:255',
            'kode_mk'     => 'required|string|max:20',
            'tipe'        => 'required|in:KULIAH,UTS,UAS',
            'hari'        => 'required|string',
            'jam_mulai'   => 'required',
            'jam_selesai' => 'required|after:jam_mulai',
            'ruangan'     => 'required|string|max:100',
            'nama_dosen'  => 'required|string|max:255',
            'id_periode'  => 'required',
        ]);

        $user = Auth::user();

        $collision = $this->detectCollision(
            $request->hari, $request->jam_mulai, $request->jam_selesai,
            $request->ruangan, $request->nama_dosen, $request->nama_mk, null
        );

        if ($collision) {
            return redirect()->back()->withInput()
                ->with('error', 'Terjadi bentrok jadwal! Silakan periksa detail di bawah.')
                ->with('conflict_detail', $collision);
        }

        Schedule::create([
            'id_mk'       => $request->id_mk,
            'nama_mk'     => $request->nama_mk,
            'kode_mk'     => $request->kode_mk,
            'id_prodi'    => $user->id_prodi,
            'id_jurusan'  => $user->id_jurusan,
            'id_periode'  => $request->id_periode,
            'tipe'        => $request->tipe,
            'hari'        => $request->hari,
            'jam_mulai'   => $request->jam_mulai,
            'jam_selesai' => $request->jam_selesai,
            'ruangan'     => $request->ruangan,
            'nama_dosen'  => $request->nama_dosen,
            'status'      => 'DRAFT',
        ]);

        return redirect()->route('penjadwalan.schedules.index')
            ->with('success', 'Jadwal berhasil ditambahkan dengan status DRAFT.');
    }

    /**
     * Form edit jadwal
     */
    public function edit(string $id)
    {
        $user   = Auth::user();
        $jadwal = Schedule::where('id_jurusan', $user->id_jurusan)->findOrFail($id);

        $masterMatkul = MataKuliah::where('id_prodi', $user->id_prodi)->get();

        return view('penjadwalan.schedules.edit', compact('jadwal', 'masterMatkul'));
    }

    /**
     * Update jadwal + Collision Detection
     */
    public function update(Request $request, string $id)
    {
        $request->validate([
            'tipe'        => 'required|in:KULIAH,UTS,UAS',
            'hari'        => 'required|string',
            'jam_mulai'   => 'required',
            'jam_selesai' => 'required|after:jam_mulai',
            'ruangan'     => 'required|string|max:100',
            'nama_dosen'  => 'required|string|max:255',
        ]);

        $user   = Auth::user();
        $jadwal = Schedule::where('id_jurusan', $user->id_jurusan)->findOrFail($id);

        $collision = $this->detectCollision(
            $request->hari, $request->jam_mulai, $request->jam_selesai,
            $request->ruangan, $request->nama_dosen, $jadwal->nama_mk, $id
        );

        if ($collision) {
            return redirect()->back()->withInput()
                ->with('error', 'Terjadi bentrok jadwal saat revisi!')
                ->with('conflict_detail', $collision);
        }

        $jadwal->update([
            'tipe'        => $request->tipe,
            'hari'        => $request->hari,
            'jam_mulai'   => $request->jam_mulai,
            'jam_selesai' => $request->jam_selesai,
            'ruangan'     => $request->ruangan,
            'nama_dosen'  => $request->nama_dosen,
            'status'      => 'DRAFT',
        ]);

        return redirect()->route('penjadwalan.schedules.index')
            ->with('success', 'Jadwal berhasil diperbarui. Status direset ke DRAFT.');
    }

    /**
     * Finalisasi: DRAFT → FINAL
     */
    public function finalize(string $id)
    {
        $user   = Auth::user();
        $jadwal = Schedule::where('id_jurusan', $user->id_jurusan)
            ->where('status', 'DRAFT')
            ->findOrFail($id);

        $jadwal->update(['status' => 'FINAL']);

        return redirect()->back()
            ->with('success', "Jadwal '{$jadwal->nama_mk}' berhasil difinalisasi.");
    }

    /**
     * Publikasi: FINAL → PUBLISHED
     */
    public function publish(Request $request, string $id)
    {
        $request->validate(['pesan_pengantar' => 'required|string|min:10']);

        $user   = Auth::user();
        $jadwal = Schedule::where('id_jurusan', $user->id_jurusan)
            ->where('status', 'FINAL')
            ->findOrFail($id);

        $jadwal->update([
            'status'          => 'PUBLISHED',
            'pesan_pengantar' => $request->pesan_pengantar,
        ]);

        return redirect()->back()
            ->with('success', "Jadwal '{$jadwal->nama_mk}' berhasil dipublikasikan!");
    }

    // ============================================================
    // KELOLA REQUEST PERUBAHAN DARI DOSEN
    // ============================================================

    /**
     * Daftar semua request perubahan jadwal
     */
    public function requests(Request $request)
    {
        $user        = Auth::user();
        $scheduleIds = Schedule::where('id_jurusan', $user->id_jurusan)->pluck('_id')->toArray();

        $query = ScheduleRequests::whereIn('id_schedule', $scheduleIds)
            ->orderBy('created_at', 'desc');

        if ($request->filled('status')) $query->where('status', $request->status);

        $scheduleRequests = $query->get()->each(function ($req) {
            $req->jadwal = Schedule::find($req->id_schedule);
        });

        $count_pending  = ScheduleRequests::whereIn('id_schedule', $scheduleIds)->where('status', 'PENDING')->count();
        $count_approved = ScheduleRequests::whereIn('id_schedule', $scheduleIds)->where('status', 'APPROVED')->count();
        $count_rejected = ScheduleRequests::whereIn('id_schedule', $scheduleIds)->where('status', 'REJECTED')->count();

        return view('penjadwalan.requests.index', compact(
            'scheduleRequests', 'count_pending', 'count_approved', 'count_rejected'
        ));
    }

    /**
     * Detail request perubahan
     */
    public function requestDetail(string $id)
    {
        $user        = Auth::user();
        $scheduleIds = Schedule::where('id_jurusan', $user->id_jurusan)->pluck('_id')->toArray();

        $scheduleRequest = ScheduleRequests::whereIn('id_schedule', $scheduleIds)->findOrFail($id);
        $jadwal          = Schedule::find($scheduleRequest->id_schedule);

        return view('penjadwalan.requests.detail', compact('scheduleRequest', 'jadwal'));
    }

    /**
     * Approve request + terapkan perubahan ke jadwal
     */
    public function approveRequest(Request $request, string $id)
    {
        $request->validate(['catatan_admin' => 'nullable|string|max:500']);

        $user        = Auth::user();
        $scheduleIds = Schedule::where('id_jurusan', $user->id_jurusan)->pluck('_id')->toArray();

        $scheduleRequest = ScheduleRequests::whereIn('id_schedule', $scheduleIds)
            ->where('status', 'PENDING')
            ->findOrFail($id);

        $jadwal = Schedule::findOrFail($scheduleRequest->id_schedule);
        $detail = $scheduleRequest->detail_perubahan ?? [];

        // Validasi collision untuk perubahan yang diajukan dosen
        $newHari       = $detail['hari']        ?? $jadwal->hari;
        $newJamMulai   = $detail['jam_mulai']   ?? $jadwal->jam_mulai;
        $newJamSelesai = $detail['jam_selesai'] ?? $jadwal->jam_selesai;
        $newRuangan    = $detail['ruangan']     ?? $jadwal->ruangan;
        $newDosen      = $detail['nama_dosen']  ?? $jadwal->nama_dosen;

        $collision = $this->detectCollision(
            $newHari, $newJamMulai, $newJamSelesai,
            $newRuangan, $newDosen, $jadwal->nama_mk, $jadwal->_id
        );

        if ($collision) {
            return redirect()->back()->with('error',
                "Tidak bisa approve: Perubahan yang diminta menyebabkan bentrok dengan '{$collision->nama_mk}' di {$collision->ruangan}."
            );
        }

        $jadwal->update(array_merge($detail, ['status' => 'DRAFT']));

        $scheduleRequest->update([
            'status'        => 'APPROVED',
            'catatan_admin' => $request->catatan_admin ?? 'Disetujui.',
            'id_processor'  => $user->_id,
            'updated_at'    => now(),
        ]);

        return redirect()->route('penjadwalan.requests.index')
            ->with('success', "Request dari {$scheduleRequest->nama_dosen} telah disetujui dan jadwal diperbarui.");
    }

    /**
     * Reject request perubahan jadwal
     */
    public function rejectRequest(Request $request, string $id)
    {
        $request->validate(['catatan_admin' => 'required|string|min:10|max:500']);

        $user        = Auth::user();
        $scheduleIds = Schedule::where('id_jurusan', $user->id_jurusan)->pluck('_id')->toArray();

        $scheduleRequest = ScheduleRequests::whereIn('id_schedule', $scheduleIds)
            ->where('status', 'PENDING')
            ->findOrFail($id);

        $scheduleRequest->update([
            'status'        => 'REJECTED',
            'catatan_admin' => $request->catatan_admin,
            'id_processor'  => $user->_id,
            'updated_at'    => now(),
        ]);

        return redirect()->route('penjadwalan.requests.index')
            ->with('success', "Request dari {$scheduleRequest->nama_dosen} telah ditolak.");
    }

    // ============================================================
    // PRIVATE: COLLISION DETECTION
    // ============================================================

    private function detectCollision(
        string $hari,
        string $jamMulai,
        string $jamSelesai,
        string $ruangan,
        string $namaDosen,
        string $namaMk,
        ?string $excludeId = null
    ): ?Schedule {
        $query = Schedule::where('hari', $hari)
            ->where('status', '!=', 'DRAFT')
            ->where(function ($q) use ($jamMulai, $jamSelesai) {
                $q->where('jam_mulai', '<', $jamSelesai)
                  ->where('jam_selesai', '>', $jamMulai);
            })
            ->where(function ($q) use ($ruangan, $namaDosen, $namaMk) {
                $q->where('ruangan', $ruangan)
                  ->orWhere('nama_dosen', $namaDosen)
                  ->orWhere('nama_mk', $namaMk);
            });

        if ($excludeId) {
            $query->where('_id', '!=', $excludeId);
        }

        return $query->first();
    }
}