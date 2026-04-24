<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\MataKuliah;
use App\Models\ProgramStudi;
use Illuminate\Support\Facades\Auth;

class MasterMatkulController extends Controller
{
    /**
     * Menampilkan halaman daftar Master Mata Kuliah
     */
    public function index()
    {
        // Mengambil semua data mata kuliah dari MongoDB
        $mataKuliahs = MataKuliah::all();

        // Mengambil data Program Studi untuk pilihan di form Tambah/Edit
        $prodiList = ProgramStudi::all();

        return view('admin.master.index', compact('mataKuliahs', 'prodiList'));
    }

    /**
     * Menyimpan data Mata Kuliah baru ke MongoDB
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'kode_mk' => 'required|string',
            'nama_mk' => 'required|string|max:255',
            'sks' => 'required|integer|min:1|max:6',
            'id_prodi' => 'required|string'
        ]);

        // Mencegah duplikasi kode MK
        $exists = MataKuliah::where('kode_mk', $validated['kode_mk'])->first();
        if ($exists) {
            return redirect()->back()->withErrors(['kode_mk' => 'Kode Mata Kuliah ini sudah digunakan!']);
        }

        MataKuliah::create($validated);

        return redirect()->back()->with('success', 'Master Mata Kuliah berhasil ditambahkan.');
    }

    /**
     * Memperbarui data Mata Kuliah yang sudah ada
     */
    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'kode_mk' => 'required|string',
            'nama_mk' => 'required|string|max:255',
            'sks' => 'required|integer|min:1|max:6',
            'id_prodi' => 'required|string'
        ]);

        $mk = MataKuliah::findOrFail($id);

        // Pengecekan duplikasi jika kode MK diubah
        if ($mk->kode_mk !== $validated['kode_mk']) {
            $exists = MataKuliah::where('kode_mk', $validated['kode_mk'])->first();
            if ($exists) {
                return redirect()->back()->withErrors(['kode_mk' => 'Kode Mata Kuliah ini sudah digunakan!']);
            }
        }

        $mk->update($validated);

        return redirect()->back()->with('success', 'Data Mata Kuliah berhasil diperbarui.');
    }

    /**
     * Menghapus data Mata Kuliah
     */
    public function destroy($id)
    {
        $mk = MataKuliah::findOrFail($id);
        $mk->delete();

        return redirect()->back()->with('success', 'Mata Kuliah berhasil dihapus.');
    }
}
