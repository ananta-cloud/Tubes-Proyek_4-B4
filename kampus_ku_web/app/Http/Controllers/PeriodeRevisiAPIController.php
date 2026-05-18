<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\PeriodeRevisi;
use App\Models\ScheduleRequest;

class PeriodeRevisiApiController extends Controller
{
    /**
     * GET /api/periode-revisi
     * Semua periode aktif yang relevan untuk dosen yang login.
     * Mengembalikan:
     *   - Periode SEMESTER yang aktif
     *   - Periode MATKUL yang aktif, hanya untuk jadwal yang diampu dosen ini
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $now  = now();

        $periodes = PeriodeRevisi::where('is_active', true)
            ->where('tanggal_mulai',   '<=', $now)
            ->where('tanggal_selesai', '>=', $now)
            ->get()
            ->filter(function ($periode) use ($user) {
                // SEMESTER — semua dosen boleh lihat
                if ($periode->scope === 'SEMESTER') return true;

                // MATKUL — hanya jika dosen yang mengampu
                return $periode->nama_dosen === $user->nama;
            })
            ->values();

        return response()->json([
            'status' => 'success',
            'data'   => $periodes->map(fn($p) => $this->formatPeriode($p, true)),
        ]);
    }

    /**
     * GET /api/periode-revisi/semua
     * Semua periode (aktif maupun tidak) — untuk dosen lihat riwayat deadline
     */
    public function semua(Request $request)
    {
        $user = $request->user();

        $periodes = PeriodeRevisi::orderBy('created_at', 'desc')
            ->get()
            ->filter(function ($periode) use ($user) {
                if ($periode->scope === 'SEMESTER') return true;
                return $periode->nama_dosen === $user->nama;
            })
            ->values();

        return response()->json([
            'status' => 'success',
            'data'   => $periodes->map(fn($p) => $this->formatPeriode($p, false)),
        ]);
    }

    /**
     * GET /api/periode-revisi/{id}
     * Detail satu periode + info apakah dosen masih bisa submit
     */
    public function show(Request $request, $id)
    {
        $periode = PeriodeRevisi::findOrFail($id);
        $now     = now();

        $isOngoing = $periode->is_active
            && $now->gte($periode->tanggal_mulai)
            && $now->lte($periode->tanggal_selesai);

        return response()->json([
            'status' => 'success',
            'data'   => array_merge(
                $this->formatPeriode($periode, $isOngoing),
                ['can_submit' => $isOngoing]
            ),
        ]);
    }

    /**
     * GET /api/periode-revisi/cek-jadwal/{id_jadwal}
     * Cek apakah jadwal tertentu masih dalam periode revisi aktif.
     * Digunakan Flutter sebelum dosen submit request — untuk tampilkan
     * warning "terlambat" jika sudah lewat deadline.
     */
    public function cekJadwal(Request $request, $id_jadwal)
    {
        $user = $request->user();
        $now  = now();

        // Cek periode SEMESTER aktif
        $periodeSemester = PeriodeRevisi::where('is_active', true)
            ->where('scope', 'SEMESTER')
            ->where('tanggal_mulai',   '<=', $now)
            ->where('tanggal_selesai', '>=', $now)
            ->first();

        // Cek periode MATKUL aktif untuk jadwal ini
        $periodeMatkul = PeriodeRevisi::where('is_active', true)
            ->where('scope', 'MATKUL')
            ->where('tanggal_mulai',   '<=', $now)
            ->where('tanggal_selesai', '>=', $now)
            ->get()
            ->first(function ($p) use ($id_jadwal) {
                return (string) $p->id_jadwal === $id_jadwal;
            });

        $aktif   = $periodeSemester || $periodeMatkul;
        $periode = $periodeMatkul ?? $periodeSemester;

        return response()->json([
            'status' => 'success',
            'data'   => [
                'can_submit'    => $aktif,
                'is_late'       => !$aktif,
                'periode_aktif' => $periode ? $this->formatPeriode($periode, true) : null,
                'pesan'         => $aktif
                    ? 'Masih dalam periode revisi. Silakan ajukan request.'
                    : 'Periode revisi sudah berakhir. Request tetap bisa diajukan namun akan ditandai terlambat.',
            ],
        ]);
    }

    // Helper format response
    private function formatPeriode(PeriodeRevisi $p, bool $isOngoing): array
    {
        $now = now();
        return [
            'id'               => (string) $p->_id,
            'judul'            => $p->judul,
            'scope'            => $p->scope,
            'nama_jadwal'      => $p->nama_jadwal,
            'nama_dosen'       => $p->nama_dosen,
            'tanggal_mulai'    => $p->tanggal_mulai?->toDateString(),
            'tanggal_selesai'  => $p->tanggal_selesai?->toDateString(),
            'is_active'        => $p->is_active,
            'is_ongoing'       => $isOngoing,
            'sisa_hari'        => $isOngoing
                ? (int) $now->diffInDays($p->tanggal_selesai)
                : null,
        ];
    }
}