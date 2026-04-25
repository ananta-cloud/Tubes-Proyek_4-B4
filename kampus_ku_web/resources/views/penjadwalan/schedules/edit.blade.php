@extends('layouts.app')

@section('page_title', 'Edit Jadwal')

@section('content')

<div class="mb-6">
    <a href="{{ route('penjadwalan.schedules.index') }}" class="text-indigo-600 text-sm hover:text-indigo-800 font-semibold">
        <i class="fas fa-arrow-left mr-1"></i> Kembali ke Daftar Jadwal
    </a>
</div>

{{-- Collision Error --}}
@if(session('error'))
<div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
    <i class="fas fa-exclamation-triangle text-red-500 mt-0.5 flex-shrink-0 text-lg"></i>
    <div>
        <h4 class="font-bold text-sm text-red-800">⚠ Collision Detected — Jadwal Bentrok!</h4>
        <p class="text-xs mt-1 text-red-700">{{ session('error') }}</p>
        @if(session('conflict_detail'))
        <div class="mt-2 bg-red-100 border border-red-200 rounded-lg p-3 text-xs text-red-700 font-mono">
            <p><strong>Konflik dengan:</strong> {{ session('conflict_detail')->nama_mk }}</p>
            <p><strong>Dosen:</strong> {{ session('conflict_detail')->nama_dosen }}</p>
            <p><strong>Ruangan:</strong> {{ session('conflict_detail')->ruangan }}</p>
            <p><strong>Waktu:</strong> {{ session('conflict_detail')->hari }}, {{ session('conflict_detail')->jam_mulai }}–{{ session('conflict_detail')->jam_selesai }}</p>
        </div>
        @endif
    </div>
</div>
@endif

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

    {{-- ===== FORM EDIT ===== --}}
    <div class="lg:col-span-2">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div class="p-5 border-b border-slate-200 bg-slate-50 flex items-center justify-between">
                <div>
                    <h3 class="font-bold text-slate-800"><i class="fas fa-edit text-indigo-500 mr-2"></i> Edit Jadwal</h3>
                    <p class="text-xs text-slate-500 mt-1">Perubahan akan mereset status ke <span class="font-bold text-slate-700">DRAFT</span> dan diperiksa collision-nya.</p>
                </div>
                @include('penjadwalan.partials.status-badge', ['status' => $jadwal->status])
            </div>

            <form action="{{ route('penjadwalan.schedules.update', $jadwal->id) }}" method="POST" class="p-6 space-y-5">
                @csrf @method('PUT')

                {{-- Info Matkul (Read-only karena tidak bisa diganti dari sini) --}}
                <div class="bg-slate-50 border border-slate-200 rounded-lg p-4">
                    <p class="text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1">Mata Kuliah (Tidak dapat diubah)</p>
                    <p class="font-bold text-slate-800">{{ $jadwal->nama_mk }}</p>
                    <p class="text-xs text-slate-500 font-mono">{{ $jadwal->kode_mk }} · {{ $jadwal->nama_dosen }}</p>
                </div>

                {{-- Tipe --}}
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Tipe Jadwal <span class="text-red-500">*</span></label>
                    <div class="flex gap-3">
                        @foreach(['KULIAH' => 'Perkuliahan', 'UTS' => 'UTS', 'UAS' => 'UAS'] as $value => $label)
                        <label class="flex-1 cursor-pointer">
                            <input type="radio" name="tipe" value="{{ $value }}" class="sr-only peer" {{ old('tipe', $jadwal->tipe) == $value ? 'checked' : '' }}>
                            <div class="border border-slate-200 rounded-lg p-3 text-center text-sm peer-checked:border-indigo-500 peer-checked:bg-indigo-50 peer-checked:text-indigo-700 peer-checked:font-bold transition">
                                {{ $label }}
                            </div>
                        </label>
                        @endforeach
                    </div>
                </div>

                {{-- Hari --}}
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Hari <span class="text-red-500">*</span></label>
                    <select name="hari" required class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                        @foreach(['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'] as $hari)
                            <option value="{{ $hari }}" {{ old('hari', $jadwal->hari) == $hari ? 'selected' : '' }}>{{ $hari }}</option>
                        @endforeach
                    </select>
                </div>

                {{-- Jam --}}
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Jam Mulai <span class="text-red-500">*</span></label>
                        <input type="time" name="jam_mulai" value="{{ old('jam_mulai', $jadwal->jam_mulai) }}" required
                            class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Jam Selesai <span class="text-red-500">*</span></label>
                        <input type="time" name="jam_selesai" value="{{ old('jam_selesai', $jadwal->jam_selesai) }}" required
                            class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                    </div>
                </div>

                {{-- Ruangan --}}
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Ruangan <span class="text-red-500">*</span></label>
                    <input type="text" name="ruangan" value="{{ old('ruangan', $jadwal->ruangan) }}" required
                        class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                </div>

                {{-- Dosen --}}
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Nama Dosen <span class="text-red-500">*</span></label>
                    <input type="text" name="nama_dosen" value="{{ old('nama_dosen', $jadwal->nama_dosen) }}" required
                        class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                </div>

                {{-- Submit --}}
                <div class="pt-2 flex gap-3">
                    <button type="submit" class="flex-1 bg-indigo-600 text-white py-3 rounded-lg text-sm font-bold hover:bg-indigo-700 shadow-md transition flex items-center justify-center gap-2">
                        <i class="fas fa-save"></i> Simpan Perubahan (Cek Collision)
                    </button>
                    <a href="{{ route('penjadwalan.schedules.index') }}"
                        class="px-6 py-3 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100 border border-slate-200 transition">
                        Batal
                    </a>
                </div>
            </form>
        </div>
    </div>

    {{-- ===== SIDE INFO ===== --}}
    <div class="space-y-4">

        {{-- Peringatan Edit --}}
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-5">
            <div class="flex items-center gap-2 mb-2">
                <i class="fas fa-exclamation-circle text-amber-600"></i>
                <h4 class="font-bold text-amber-800 text-sm">Perhatian</h4>
            </div>
            <p class="text-xs text-amber-700 leading-relaxed">Setiap perubahan akan mereset status jadwal ini kembali ke <strong>DRAFT</strong> dan harus melalui proses finalisasi ulang oleh Tim Penjadwalan.</p>
        </div>

        {{-- Riwayat Jadwal Sebelumnya --}}
        <div class="bg-white border border-slate-200 rounded-xl p-5 shadow-sm">
            <h4 class="font-bold text-slate-700 text-sm mb-3"><i class="fas fa-history text-slate-400 mr-1"></i> Data Saat Ini</h4>
            <div class="space-y-2 text-xs text-slate-600">
                <div class="flex justify-between">
                    <span class="text-slate-400">Hari</span>
                    <span class="font-semibold">{{ $jadwal->hari }}</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-slate-400">Jam</span>
                    <span class="font-semibold">{{ $jadwal->jam_mulai }}–{{ $jadwal->jam_selesai }}</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-slate-400">Ruangan</span>
                    <span class="font-semibold">{{ $jadwal->ruangan }}</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-slate-400">Dosen</span>
                    <span class="font-semibold">{{ $jadwal->nama_dosen }}</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-slate-400">Status</span>
                    @include('penjadwalan.partials.status-badge', ['status' => $jadwal->status])
                </div>
            </div>
        </div>
    </div>
</div>

@endsection