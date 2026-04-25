@extends('layouts.app')

@section('page_title', 'Master Data Mata Kuliah')

@section('content')
<div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden max-w-4xl">
    <div class="p-5 border-b border-slate-200 flex justify-between items-center bg-slate-50">
        <h3 class="font-bold text-slate-800"><i class="fas fa-database text-indigo-500 mr-2"></i> Master Data Mata Kuliah</h3>
        <button class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition">
            <i class="fas fa-plus mr-1"></i> Tambah Matkul
        </button>
    </div>

    <!-- Table Master Data Matkul -->
    <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
            <thead class="bg-slate-50 border-b border-slate-200">
                <tr>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase">Kode MK</th>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase">Nama Mata Kuliah</th>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase">Program Studi</th>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase text-center">SKS</th>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse($mataKuliahs ?? [] as $mk)
                <tr class="hover:bg-slate-50 transition">
                    <td class="px-6 py-3 font-mono text-xs text-slate-600">{{ $mk->kode_mk }}</td>
                    <td class="px-6 py-3 font-semibold text-slate-800">{{ $mk->nama_mk }}</td>
                    <td class="px-6 py-3 text-slate-600">D3 Teknik Informatika</td>
                    <td class="px-6 py-3 text-center">{{ $mk->sks }}</td>
                    <td class="px-6 py-3 text-right">
                        <button class="text-indigo-600 font-semibold hover:text-indigo-800 transition">Edit</button>
                    </td>
                </tr>
                @empty
                <!-- Simulasi Data Jika Database Kosong -->
                <tr class="hover:bg-slate-50 transition">
                    <td class="px-6 py-3 font-mono text-xs text-slate-600">IF101</td>
                    <td class="px-6 py-3 font-semibold text-slate-800">Algoritma & Struktur Data</td>
                    <td class="px-6 py-3 text-slate-600">D3 Teknik Informatika</td>
                    <td class="px-6 py-3 text-center">3</td>
                    <td class="px-6 py-3 text-right text-indigo-600 font-semibold cursor-pointer">Edit</td>
                </tr>
                <tr class="hover:bg-slate-50 transition">
                    <td class="px-6 py-3 font-mono text-xs text-slate-600">IF102</td>
                    <td class="px-6 py-3 font-semibold text-slate-800">Pemrograman Web Bergerak</td>
                    <td class="px-6 py-3 text-slate-600">D3 Teknik Informatika</td>
                    <td class="px-6 py-3 text-center">4</td>
                    <td class="px-6 py-3 text-right text-indigo-600 font-semibold cursor-pointer">Edit</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
