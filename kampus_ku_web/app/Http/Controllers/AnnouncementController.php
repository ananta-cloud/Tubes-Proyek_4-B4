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

        if ($user->role === 'MANAJEMEN') {
            $announcements   = Announcement::where('target_audience', 'UMUM')
                ->orderBy('created_at', 'desc')->paginate(10);
            $total_bulan_ini = Announcement::where('target_audience', 'UMUM')
                ->whereMonth('created_at', now()->month)->count();
            $view = 'manajemen.dashboard';
        } else {
            $announcements   = Announcement::where('id_jurusan', $user->id_jurusan)
                ->orderBy('created_at', 'desc')->paginate(10);
            $total_bulan_ini = Announcement::where('id_jurusan', $user->id_jurusan)
                ->whereMonth('created_at', now()->month)->count();
            $view = 'admin.announcements.index';
        }

        $total        = $announcements->total();
        // $total_dibaca = $announcements->sum(fn($a) => count($a->read_by_users ?? []));
        $total_dibaca = $announcements->sum(function($a) {
            $reads = $a->read_by_users;
            if (is_array($reads)) return count($reads);
            if (is_string($reads)) return count(json_decode($reads, true) ?? []);
            return 0;
        });
        return view($view, compact('announcements', 'total', 'total_bulan_ini', 'total_dibaca'));
    }

    public function create()
    {
        $user = Auth::user();

        $jurusanId = (string) $user->id_jurusan;

        $prodiList = \App\Models\ProgramStudi::all()->filter(function($prodi) use ($jurusanId) {
            return (string) $prodi->id_jurusan === $jurusanId;
        });

        return view('admin.announcements.create', compact('prodiList'));
    }

    public function store(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'judul'    => 'required|string',
            'isi'      => 'required|string',
            'kategori' => 'nullable|array',   
            'kategori' => 'nullable|string',
        ]);

        if ($user->role === 'MANAJEMEN') {
            $targetAudience = 'UMUM';
            $idJurusan      = null;
            $idProdi        = null;
        } else {
            $targetAudience = 'PRODI';
            $idJurusan      = $user->id_jurusan;
            $idProdi        = $request->id_prodi ?? null;
        }

        Announcement::create([
            ...$validated,
            'target_audience' => $targetAudience,
            'id_jurusan'      => $idJurusan,
            'id_prodi'        => $idProdi,
            'target_angkatan' => $request->target_angkatan,
            'id_publisher'    => $user->_id,   
            'nama_publisher'  => $user->nama, 
            'role_publisher'  => $user->role,
            'read_by_users'   => [],
            'kategori' => $request->kategori ? [$request->kategori] : [],
        ]);

        // FcmService::sendToTopic(...);

        return redirect()->route('admin.announcements.index')
            ->with('success', 'Pengumuman berhasil diterbitkan.');
    }

    public function destroy($id)
    {
        $announcement = Announcement::findOrFail($id);
        $announcement->delete();

        return redirect()->route('admin.announcements.index')
            ->with('success', 'Pengumuman berhasil dihapus.');
    }

    /**
     * Cross-posting Helper — khusus Manajemen
     */
    public function crossPostFormat($id)
    {
        $announcement = Announcement::findOrFail($id);

        $text  = "*[PENGUMUMAN POLBAN]*\n\n";
        $text .= "*" . strtoupper($announcement->judul) . "*\n\n";
        $text .= $announcement->isi . "\n\n";
        $text .= "_Cek detail lengkapnya dan simpan ke bookmark di Aplikasi SIGMA._";

        return response()->json(['whatsapp_format' => $text]);
    }
}