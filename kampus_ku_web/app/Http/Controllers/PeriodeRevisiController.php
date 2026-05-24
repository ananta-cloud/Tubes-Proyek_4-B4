<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\PeriodeRevisi;
use App\Models\Schedule;

class PeriodeRevisiController extends Controller
{
    /**
     * Daftar semua periode revisi
     */
    public function index()
    {
        $periodes = PeriodeRevisi::orderBy('created_at', 'desc')->paginate(10);

        $count_aktif    = PeriodeRevisi::aktif()->count();
        $count_semester = PeriodeRevisi::where('scope', 'SEMESTER')->count();
        $count_matkul   = PeriodeRevisi::where('scope', 'MATKUL')->count();

        // Ambil daftar jadwal untuk dropdown di modal create (scope MATKUL)
        $schedules = Schedule::select(['_id', 'nama_mk', 'nama_dosen'])->get();

        return view('penjadwalan.revisi.index', compact(
            'periodes',
            'count_aktif',
            'count_semester',
            'count_matkul',
            'schedules'
        ));
    }

    /**
     * Simpan periode revisi baru
     */
    public function store(Request $request)
    {
        $request->validate([
            'judul'           => 'required|string|max:200',
            'scope'           => 'required|in:SEMESTER,MATKUL',
            'id_jadwal'       => 'required_if:scope,MATKUL|nullable|string',
            'tanggal_mulai'   => 'required|date',
            'tanggal_selesai' => 'required|date|after:tanggal_mulai',
        ]);

        $user       = Auth::user();
        $idJadwal   = null;
        $namaJadwal = null;
        $namaDosen  = null;

        if ($request->scope === 'MATKUL' && $request->id_jadwal) {
            $jadwal = Schedule::find($request->id_jadwal);
            if ($jadwal) {
                $idJadwal   = new \MongoDB\BSON\ObjectId($request->id_jadwal);
                $namaJadwal = $jadwal->nama_mk;
                $namaDosen  = $jadwal->nama_dosen;
            }
        }

        PeriodeRevisi::create([
            'judul'           => $request->judul,
            'scope'           => $request->scope,
            'id_jadwal'       => $idJadwal,
            'nama_jadwal'     => $namaJadwal,
            'nama_dosen'      => $namaDosen,
            'tanggal_mulai'   => new \MongoDB\BSON\UTCDateTime(
                                    \Carbon\Carbon::parse($request->tanggal_mulai)->timestamp * 1000
                                 ),
            'tanggal_selesai' => new \MongoDB\BSON\UTCDateTime(
                                    \Carbon\Carbon::parse($request->tanggal_selesai)->timestamp * 1000
                                 ),
            'is_active'       => true,
            'created_by'      => new \MongoDB\BSON\ObjectId((string) $user->_id),
        ]);

        return redirect()->route('penjadwalan.revisi.index')
            ->with('success', 'Periode revisi berhasil dibuat.');
    }

    /**
     * Aktifkan / nonaktifkan periode
     */
    public function toggle($id)
    {
        $periode = PeriodeRevisi::findOrFail($id);
        $periode->update(['is_active' => !$periode->is_active]);

        $status = $periode->is_active ? 'diaktifkan' : 'dinonaktifkan';

        return redirect()->route('penjadwalan.revisi.index')
            ->with('success', "Periode revisi berhasil {$status}.");
    }

    /**
     * Hapus periode revisi
     */
    public function destroy($id)
    {
        $periode = PeriodeRevisi::findOrFail($id);
        $periode->delete();

        return redirect()->route('penjadwalan.revisi.index')
            ->with('success', 'Periode revisi berhasil dihapus.');
    }
}