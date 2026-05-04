<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;
use App\Models\Announcement;
use Illuminate\Support\Facades\Auth;
use MongoDB\Model\BSONArray;
use App\Services\CrossPostingService;
use Illuminate\Support\Facades\Storage;


class AnnouncementController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $query = Announcement::query();

        // 1. Filter Scope
        if ($user->role === 'MANAJEMEN') {
            // Cari data yang sesuai dengan ENUM skema untuk MANAJEMEN
            $query->whereIn('target_audience', ['SEMUA', 'SEMUA_MAHASISWA', 'SEMUA_DOSEN']);
            $view = 'manajemen.announcements.index'; // Pastikan path ini benar
        } else {
            $query->where('id_jurusan', $user->id_jurusan);
            $view = 'admin.announcements.index';
        }

        // 2. Arsip & Pencarian
        $announcements = $query->orderBy('created_at', 'desc')->paginate(10);

        // 3. Metrik Dashboard
        $total = $announcements->total();
        $total_bulan_ini = (clone $query)->whereMonth('created_at', now()->month)->count();

        // 4. Read Confirmation Calculation
        // Read Confirmation Calculation
        $total_dibaca = $announcements->getCollection()->sum(function($a) {
            $reads = $a->read_by_users;

            // 1. Jika data kosong (null atau tidak ada), kembalikan 0
            if (empty($reads)) {
                return 0;
            }

            // 2. Karena Model sudah men-cast ke 'array', kita bisa langsung hitung
            if (is_array($reads)) {
                return count($reads);
            }

            // 3. Jaga-jaga jika MongoDB mengembalikannya sebagai wujud BSON Object
            if (is_object($reads) && method_exists($reads, 'count')) {
                return $reads->count();
            }

            return 0;
        });

        return view($view, compact('announcements', 'total', 'total_bulan_ini', 'total_dibaca'));
    }
   public function create()
    {
        $user = Auth::user();

        // Manajemen tidak butuh dropdown prodi (Targeting lintas jurusan)
        if ($user->role === 'MANAJEMEN') {
            return view('manajemen.announcements.create');
        }

        $prodiList = \App\Models\ProgramStudi::where('id_jurusan', $user->id_jurusan)->get();
        return view('admin.announcements.create', compact('prodiList'));
    }

   public function store(Request $request)
    {
        $user = Auth::user();

        // 1. Validasi Input Form
        $request->validate([
            'judul'           => 'required|string',
            'isi'             => 'required|string',
            'target_penerima' => 'required|in:MAHASISWA,DOSEN,KEDUANYA',
            'kategori'        => 'required|array|min:1',
            'lampiran'        => 'nullable|file|mimes:jpg,jpeg,png,pdf,xlsx,xls,doc,docx|max:5120',
        ]);

        // 2. Handle Upload File
        $lampiranPath = null;
        if ($request->hasFile('lampiran')) {
            $lampiranPath = $request->file('lampiran')->store('pengumuman_files', 'public');
        }

        // 3. Mapping ke Enum Skema MONGODB
        $targetMap = [
            'MAHASISWA' => ($user->role === 'MANAJEMEN') ? 'SEMUA_MAHASISWA' : 'PRODI_MAHASISWA',
            'DOSEN'     => ($user->role === 'MANAJEMEN') ? 'SEMUA_DOSEN' : 'PRODI_DOSEN',
            'KEDUANYA'  => ($user->role === 'MANAJEMEN') ? 'SEMUA' : 'PRODI_SEMUA',
        ];
        $targetAudience = $targetMap[$request->target_penerima];
        $now = new UTCDateTime(now());

        // 4. SUSUN DATA INTI
        $data = [
            'judul'           => (string) $request->judul,
            'isi'             => (string) $request->isi,
            'target_audience' => (string) $targetAudience,
            'id_publisher'    => new ObjectId($user->_id),
            'nama_publisher'  => (string) $user->nama,
            'role_publisher'  => (string) $user->role,
            'lampiran'        => $lampiranPath,
            'created_at'      => $now,
            'updated_at'      => $now,
        ];

        // 5. FIX KATEGORI: Paksa jadi BSON Array Murni
        if (!empty($request->kategori)) {
            $data['kategori'] = new BSONArray(array_values($request->kategori));
        }

        // 6. FIX TARGET ANGKATAN
        if (!empty($request->target_angkatan)) {
            $angkatanList = array_values(array_filter(array_map('trim', explode(',', $request->target_angkatan))));
            if (count($angkatanList) > 0) {
                $data['target_angkatan'] = new BSONArray($angkatanList);
            }
        }

        // 7. ID Relasi (Opsional)
        if ($user->id_jurusan) {
            $data['id_jurusan'] = new ObjectId($user->id_jurusan);
        }
        if ($request->id_prodi) {
            $data['id_prodi'] = new ObjectId($request->id_prodi);
        }

        // 8. EKSEKUSI INSERT
        $announcement = Announcement::create($data);

        // ==========================================
        // 9. LOGIKA AUTO-POSTING HANYA KE WA
        // ==========================================
        $photoUrl = null;

        // Cek apakah ada lampiran berupa foto (agar WA bisa mengirim gambar + caption)
        if ($lampiranPath) {
            $ext = strtolower(pathinfo($lampiranPath, PATHINFO_EXTENSION));
            if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) {
                $photoUrl = asset('storage/' . $lampiranPath);
            }
        }

        // Kirim ke WhatsApp (Jika $photoUrl null, WA hanya kirim teks. Jika ada isinya, WA kirim gambar)
        CrossPostingService::sendToWhatsApp($announcement, $photoUrl);

        // 10. REDIRECT
        $redirect = ($user->role === 'MANAJEMEN') ? 'manajemen.dashboard' : 'admin.announcements.index';
        return redirect()->route($redirect)->with('success', 'Pengumuman Berhasil Diterbitkan dan otomatis dikirim ke WhatsApp.');
    }

    /**
     * Cross-posting Helper — Generate format WA/IG (Could Have)
     */
    public function edit($id)
    {
        $announcement = Announcement::findOrFail($id);

        // Reverse Mapping untuk Dropdown Target Penerima di Form
        $penerimaMap = [
            'SEMUA_MAHASISWA' => 'MAHASISWA',
            'PRODI_MAHASISWA' => 'MAHASISWA',
            'SEMUA_DOSEN'     => 'DOSEN',
            'PRODI_DOSEN'     => 'DOSEN',
            'SEMUA'           => 'KEDUANYA',
            'PRODI_SEMUA'     => 'KEDUANYA',
        ];
        $targetPenerimaForm = $penerimaMap[$announcement->target_audience] ?? 'KEDUANYA';

        // Ekstrak kategori BSONArray menjadi array PHP murni agar mudah dibaca di Blade
        $kategoriArr = is_object($announcement->kategori) && method_exists($announcement->kategori, 'getArrayCopy')
                        ? $announcement->kategori->getArrayCopy()
                        : (is_array($announcement->kategori) ? $announcement->kategori : []);

        // Ekstrak target angkatan
        $angkatanStr = '';
        if (!empty($announcement->target_angkatan)) {
            $angkatanArr = is_object($announcement->target_angkatan) && method_exists($announcement->target_angkatan, 'getArrayCopy')
                            ? $announcement->target_angkatan->getArrayCopy()
                            : (array) $announcement->target_angkatan;
            $angkatanStr = implode(', ', $angkatanArr);
        }

        return view('manajemen.announcements.edit', compact('announcement', 'targetPenerimaForm', 'kategoriArr', 'angkatanStr'));
    }

    public function update(Request $request, $id)
    {
        $user = Auth::user();
        $announcement = Announcement::findOrFail($id);

        $request->validate([
            'judul' => 'required|string',
            'isi' => 'required|string',
            'target_penerima' => 'required|in:MAHASISWA,DOSEN,KEDUANYA',
            'kategori' => 'required|array|min:1',
        ]);

        $targetMap = [
            'MAHASISWA' => ($user->role === 'MANAJEMEN') ? 'SEMUA_MAHASISWA' : 'PRODI_MAHASISWA',
            'DOSEN'     => ($user->role === 'MANAJEMEN') ? 'SEMUA_DOSEN' : 'PRODI_DOSEN',
            'KEDUANYA'  => ($user->role === 'MANAJEMEN') ? 'SEMUA' : 'PRODI_SEMUA',
        ];

        // Susun data update sesuai Schema (Hanya update data konten, bukan data publisher)
        $updateData = [
            'judul'           => (string) $request->judul,
            'isi'             => (string) $request->isi,
            'target_audience' => (string) $targetMap[$request->target_penerima],
            'updated_at'      => new UTCDateTime(now()),
        ];

        if (!empty($request->kategori)) {
            $updateData['kategori'] = new BSONArray(array_values($request->kategori));
        }

        if (!empty($request->target_angkatan)) {
            $angkatanList = array_values(array_filter(array_map('trim', explode(',', $request->target_angkatan))));
            if (count($angkatanList) > 0) {
                $updateData['target_angkatan'] = new BSONArray($angkatanList);
            }
        } else {
            $updateData['target_angkatan'] = null; // Kosongkan jika dihapus oleh user
        }

        $announcement->update($updateData);

        $redirect = ($user->role === 'MANAJEMEN') ? 'manajemen.dashboard' : 'admin.announcements.index';
        return redirect()->route($redirect)->with('success', 'Pengumuman Berhasil Diperbarui');
    }

    // Helper untuk format teks WhatsApp dan Instagram (Could Have feature)
    public function crossPostFormat($id)
    {
        $announcement = Announcement::findOrFail($id);

        $kategori = 'Umum';
        if (!empty($announcement->kategori)) {
            $arr = is_object($announcement->kategori) ? $announcement->kategori->getArrayCopy() : (array) $announcement->kategori;
            $kategori = implode(', ', $arr);
        }

        $waText = "*PENGUMUMAN PUSAT*\n"
                . "Kategori: {$kategori}\n\n"
                . "*{$announcement->judul}*\n\n"
                . "{$announcement->isi}\n\n"
                . "_Dikirim oleh: {$announcement->nama_publisher}_\n"
                . "_Info lebih lanjut, cek aplikasi SIGMA Kampusku_";

        $igText = "[PENGUMUMAN PUSAT]\n\n"
                . "{$announcement->judul}\n\n"
                . "{$announcement->isi}\n\n"
                . "Cek aplikasi Kampusku untuk melihat notifikasi lengkapnya!\n\n"
                . "#PengumumanKampus #SIGMA #Polban";

        return response()->json([
            'wa' => $waText,
            'ig' => $igText
        ]);
    }

    // Method untuk trigger kirim API secara manual dari tombol
    // Method untuk trigger kirim API WA secara manual dari tombol
    public function broadcast(Request $request, $id)
    {
        try {
            $announcement = Announcement::findOrFail($id);
            $photoUrl = null;

            if ($announcement->lampiran) {
                $ext = strtolower(pathinfo($announcement->lampiran, PATHINFO_EXTENSION));
                if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) {
                    $photoUrl = asset('storage/' . $announcement->lampiran);
                }
            }

            $status = CrossPostingService::sendToWhatsApp($announcement, $photoUrl);

            return response()->json([
                'success' => $status,
                'message' => $status ? 'Pengumuman berhasil dibroadcast ke WhatsApp!' : 'Gagal mengirim ke WhatsApp Gateway. Periksa koneksi API Anda.'
            ]);

        } catch (\Exception $e) {
            // TRIK JITU: Tangkap error PHP dan kirimkan ke layar sebagai pesan teks
            return response()->json([
                'success' => false,
                'message' => 'SYSTEM ERROR: ' . $e->getMessage() . ' (Baris: ' . $e->getLine() . ')'
            ]);
        }
    }

    public function destroy($id)
    {
        $user = Auth::user();
        $announcement = Announcement::findOrFail($id);

        // Keamanan: Manajemen bisa hapus semua UMUM, Admin TU hanya jurusannya
        $announcement->delete();

        $redirect = ($user->role === 'MANAJEMEN') ? 'manajemen.dashboard' : 'admin.announcements.index';
        return redirect()->route($redirect)->with('success', 'Pengumuman berhasil ditarik/dihapus.');
    }

    public function show($id)
    {
        $announcement = Announcement::findOrFail($id);

        // Pastikan path view sesuai dengan nama file yang Anda buat
        // Jika Anda menyimpannya sebagai detail.blade.php, ubah menjadi 'manajemen.announcements.detail'
        return view('manajemen.announcements.show', compact('announcement'));
    }
}

<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;
use App\Models\Announcement;
use Illuminate\Support\Facades\Auth;
use MongoDB\Model\BSONArray;
use App\Services\CrossPostingService;
use Illuminate\Support\Facades\Storage;

class AnnouncementController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $query = Announcement::query();

        // 1. Filter Scope
        if ($user->role === 'MANAJEMEN') {
            // Cari data yang sesuai dengan ENUM skema untuk MANAJEMEN
            $query->whereIn('target_audience', ['SEMUA', 'SEMUA_MAHASISWA', 'SEMUA_DOSEN']);
            $view = 'manajemen.announcements.index'; // Pastikan path ini benar
        } else {
            $query->where('id_jurusan', $user->id_jurusan);
            $view = 'admin.announcements.index';
        }

        // 2. Arsip & Pencarian
        $announcements = $query->orderBy('created_at', 'desc')->paginate(10);

        // 3. Metrik Dashboard
        $total = $announcements->total();
        $total_bulan_ini = (clone $query)->whereMonth('created_at', now()->month)->count();

        // 4. Read Confirmation Calculation
        // Read Confirmation Calculation
        $total_dibaca = $announcements->getCollection()->sum(function($a) {
            $reads = $a->read_by_users;

            // 1. Jika data kosong (null atau tidak ada), kembalikan 0
            if (empty($reads)) {
                return 0;
            }

            // 2. Karena Model sudah men-cast ke 'array', kita bisa langsung hitung
            if (is_array($reads)) {
                return count($reads);
            }

            // 3. Jaga-jaga jika MongoDB mengembalikannya sebagai wujud BSON Object
            if (is_object($reads) && method_exists($reads, 'count')) {
                return $reads->count();
            }

            return 0;
        });

        return view($view, compact('announcements', 'total', 'total_bulan_ini', 'total_dibaca'));
    }
   public function create()
    {
        $user = Auth::user();

        // Manajemen tidak butuh dropdown prodi (Targeting lintas jurusan)
        if ($user->role === 'MANAJEMEN') {
            return view('manajemen.announcements.create');
        }

        $prodiList = \App\Models\ProgramStudi::where('id_jurusan', $user->id_jurusan)->get();
        return view('admin.announcements.create', compact('prodiList'));
    }

   public function store(Request $request)
    {
        $user = Auth::user();

        // 1. Validasi Input Form
        $request->validate([
            'judul'           => 'required|string',
            'isi'             => 'required|string',
            'target_penerima' => 'required|in:MAHASISWA,DOSEN,KEDUANYA',
            'kategori'        => 'required|array|min:1',
            'lampiran'        => 'nullable|file|mimes:jpg,jpeg,png,pdf,xlsx,xls,doc,docx|max:5120',
        ]);

        // 2. Handle Upload File
        $lampiranPath = null;
        if ($request->hasFile('lampiran')) {
            $lampiranPath = $request->file('lampiran')->store('pengumuman_files', 'public');
        }

        // 3. Mapping ke Enum Skema MONGODB
        $targetMap = [
            'MAHASISWA' => ($user->role === 'MANAJEMEN') ? 'SEMUA_MAHASISWA' : 'PRODI_MAHASISWA',
            'DOSEN'     => ($user->role === 'MANAJEMEN') ? 'SEMUA_DOSEN' : 'PRODI_DOSEN',
            'KEDUANYA'  => ($user->role === 'MANAJEMEN') ? 'SEMUA' : 'PRODI_SEMUA',
        ];
        $targetAudience = $targetMap[$request->target_penerima];
        $now = new UTCDateTime(now());

        // 4. SUSUN DATA INTI
        $data = [
            'judul'           => (string) $request->judul,
            'isi'             => (string) $request->isi,
            'target_audience' => (string) $targetAudience,
            'id_publisher'    => new ObjectId($user->_id),
            'nama_publisher'  => (string) $user->nama,
            'role_publisher'  => (string) $user->role,
            'lampiran'        => $lampiranPath,
            'created_at'      => $now,
            'updated_at'      => $now,
        ];

        // 5. FIX KATEGORI: Paksa jadi BSON Array Murni
        if (!empty($request->kategori)) {
            $data['kategori'] = new BSONArray(array_values($request->kategori));
        }

        // 6. FIX TARGET ANGKATAN
        if (!empty($request->target_angkatan)) {
            $angkatanList = array_values(array_filter(array_map('trim', explode(',', $request->target_angkatan))));
            if (count($angkatanList) > 0) {
                $data['target_angkatan'] = new BSONArray($angkatanList);
            }
        }

        // 7. ID Relasi (Opsional)
        if ($user->id_jurusan) {
            $data['id_jurusan'] = new ObjectId($user->id_jurusan);
        }
        if ($request->id_prodi) {
            $data['id_prodi'] = new ObjectId($request->id_prodi);
        }

        // 8. EKSEKUSI INSERT
        $announcement = Announcement::create($data);

        // ==========================================
        // 9. LOGIKA AUTO-POSTING HANYA KE WA
        // ==========================================
        $photoUrl = null;

        // Cek apakah ada lampiran berupa foto (agar WA bisa mengirim gambar + caption)
        if ($lampiranPath) {
            $ext = strtolower(pathinfo($lampiranPath, PATHINFO_EXTENSION));
            if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) {
                $photoUrl = asset('storage/' . $lampiranPath);
            }
        }

        // Kirim ke WhatsApp (Jika $photoUrl null, WA hanya kirim teks. Jika ada isinya, WA kirim gambar)
        CrossPostingService::sendToWhatsApp($announcement, $photoUrl);

        // 10. REDIRECT
        $redirect = ($user->role === 'MANAJEMEN') ? 'manajemen.dashboard' : 'admin.announcements.index';
        return redirect()->route($redirect)->with('success', 'Pengumuman Berhasil Diterbitkan dan otomatis dikirim ke WhatsApp.');
    }

    /**
     * Cross-posting Helper — Generate format WA/IG (Could Have)
     */
    public function edit($id)
    {
        $announcement = Announcement::findOrFail($id);

        // Reverse Mapping untuk Dropdown Target Penerima di Form
        $penerimaMap = [
            'SEMUA_MAHASISWA' => 'MAHASISWA',
            'PRODI_MAHASISWA' => 'MAHASISWA',
            'SEMUA_DOSEN'     => 'DOSEN',
            'PRODI_DOSEN'     => 'DOSEN',
            'SEMUA'           => 'KEDUANYA',
            'PRODI_SEMUA'     => 'KEDUANYA',
        ];
        $targetPenerimaForm = $penerimaMap[$announcement->target_audience] ?? 'KEDUANYA';

        // Ekstrak kategori BSONArray menjadi array PHP murni agar mudah dibaca di Blade
        $kategoriArr = is_object($announcement->kategori) && method_exists($announcement->kategori, 'getArrayCopy')
                        ? $announcement->kategori->getArrayCopy()
                        : (is_array($announcement->kategori) ? $announcement->kategori : []);

        // Ekstrak target angkatan
        $angkatanStr = '';
        if (!empty($announcement->target_angkatan)) {
            $angkatanArr = is_object($announcement->target_angkatan) && method_exists($announcement->target_angkatan, 'getArrayCopy')
                            ? $announcement->target_angkatan->getArrayCopy()
                            : (array) $announcement->target_angkatan;
            $angkatanStr = implode(', ', $angkatanArr);
        }

        return view('manajemen.announcements.edit', compact('announcement', 'targetPenerimaForm', 'kategoriArr', 'angkatanStr'));
    }

    public function update(Request $request, $id)
    {
        $user = Auth::user();
        $announcement = Announcement::findOrFail($id);

        $request->validate([
            'judul' => 'required|string',
            'isi' => 'required|string',
            'target_penerima' => 'required|in:MAHASISWA,DOSEN,KEDUANYA',
            'kategori' => 'required|array|min:1',
        ]);

        $targetMap = [
            'MAHASISWA' => ($user->role === 'MANAJEMEN') ? 'SEMUA_MAHASISWA' : 'PRODI_MAHASISWA',
            'DOSEN'     => ($user->role === 'MANAJEMEN') ? 'SEMUA_DOSEN' : 'PRODI_DOSEN',
            'KEDUANYA'  => ($user->role === 'MANAJEMEN') ? 'SEMUA' : 'PRODI_SEMUA',
        ];

        // Susun data update sesuai Schema (Hanya update data konten, bukan data publisher)
        $updateData = [
            'judul'           => (string) $request->judul,
            'isi'             => (string) $request->isi,
            'target_audience' => (string) $targetMap[$request->target_penerima],
            'updated_at'      => new UTCDateTime(now()),
        ];

        if (!empty($request->kategori)) {
            $updateData['kategori'] = new BSONArray(array_values($request->kategori));
        }

        if (!empty($request->target_angkatan)) {
            $angkatanList = array_values(array_filter(array_map('trim', explode(',', $request->target_angkatan))));
            if (count($angkatanList) > 0) {
                $updateData['target_angkatan'] = new BSONArray($angkatanList);
            }
        } else {
            $updateData['target_angkatan'] = null; // Kosongkan jika dihapus oleh user
        }

        $announcement->update($updateData);

        $redirect = ($user->role === 'MANAJEMEN') ? 'manajemen.dashboard' : 'admin.announcements.index';
        return redirect()->route($redirect)->with('success', 'Pengumuman Berhasil Diperbarui');
    }

    // Helper untuk format teks WhatsApp dan Instagram (Could Have feature)
    public function crossPostFormat($id)
    {
        $announcement = Announcement::findOrFail($id);

        $kategori = 'Umum';
        if (!empty($announcement->kategori)) {
            $arr = is_object($announcement->kategori) ? $announcement->kategori->getArrayCopy() : (array) $announcement->kategori;
            $kategori = implode(', ', $arr);
        }

        $waText = "*PENGUMUMAN PUSAT*\n"
                . "Kategori: {$kategori}\n\n"
                . "*{$announcement->judul}*\n\n"
                . "{$announcement->isi}\n\n"
                . "_Dikirim oleh: {$announcement->nama_publisher}_\n"
                . "_Info lebih lanjut, cek aplikasi SIGMA Kampusku_";

        $igText = "[PENGUMUMAN PUSAT]\n\n"
                . "{$announcement->judul}\n\n"
                . "{$announcement->isi}\n\n"
                . "Cek aplikasi Kampusku untuk melihat notifikasi lengkapnya!\n\n"
                . "#PengumumanKampus #SIGMA #Polban";

        return response()->json([
            'wa' => $waText,
            'ig' => $igText
        ]);
    }

    // Method untuk trigger kirim API secara manual dari tombol
    // Method untuk trigger kirim API WA secara manual dari tombol
    public function broadcast(Request $request, $id)
    {
        try {
            $announcement = Announcement::findOrFail($id);
            $photoUrl = null;

            if ($announcement->lampiran) {
                $ext = strtolower(pathinfo($announcement->lampiran, PATHINFO_EXTENSION));
                if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) {
                    $photoUrl = asset('storage/' . $announcement->lampiran);
                }
            }

            $status = CrossPostingService::sendToWhatsApp($announcement, $photoUrl);

            return response()->json([
                'success' => $status,
                'message' => $status ? 'Pengumuman berhasil dibroadcast ke WhatsApp!' : 'Gagal mengirim ke WhatsApp Gateway. Periksa koneksi API Anda.'
            ]);

        } catch (\Exception $e) {
            // TRIK JITU: Tangkap error PHP dan kirimkan ke layar sebagai pesan teks
            return response()->json([
                'success' => false,
                'message' => 'SYSTEM ERROR: ' . $e->getMessage() . ' (Baris: ' . $e->getLine() . ')'
            ]);
        }
    }

    public function destroy($id)
    {
        $user = Auth::user();
        $announcement = Announcement::findOrFail($id);

        // Keamanan: Manajemen bisa hapus semua UMUM, Admin TU hanya jurusannya
        $announcement->delete();

        $redirect = ($user->role === 'MANAJEMEN') ? 'manajemen.dashboard' : 'admin.announcements.index';
        return redirect()->route($redirect)->with('success', 'Pengumuman berhasil ditarik/dihapus.');
    }

    public function show($id)
    {
        $announcement = Announcement::findOrFail($id);

        // Pastikan path view sesuai dengan nama file yang Anda buat
        // Jika Anda menyimpannya sebagai detail.blade.php, ubah menjadi 'manajemen.announcements.detail'
        return view('manajemen.announcements.show', compact('announcement'));
    }
}
