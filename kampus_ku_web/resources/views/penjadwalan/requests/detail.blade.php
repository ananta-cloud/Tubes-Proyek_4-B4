@extends('layouts.app')

@section('page_title', 'Detail Request Perubahan Jadwal')

@section('content')

<div class="mb-6">
    <a href="{{ route('penjadwalan.requests.index') }}" class="text-indigo-600 text-sm hover:text-indigo-800 font-semibold">
        <i class="fas fa-arrow-left mr-1"></i> Kembali ke Daftar Request
    </a>
</div>

@if(session('error'))
<div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
    <i class="fas fa-exclamation-triangle text-red-500 mt-0.5"></i>
    <p class="text-sm text-red-800">{{ session('error') }}</p>
</div>
@endif

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

    {{-- ===== DETAIL REQUEST ===== --}}
    <div class="lg:col-span-2 space-y-6">

        {{-- Header Request --}}
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
            <div class="flex justify-between items-start mb-4">
                <div>
                    <p class="text-[10px] text-slate-400 uppercase tracking-wider font-bold mb-1">Request dari Dosen</p>
                    <h2 class="text-xl font-black text-slate-800">{{ $scheduleRequest->nama_dosen }}</h2>
                    <p class="text-xs text-slate-500 mt-1">
                        Diajukan: {{ \Carbon\Carbon::parse($scheduleRequest->created_at)->format('d M Y, H:i') }}
                    </p>
                </div>
                @if($scheduleRequest->status == 'PENDING')
                    <span class="inline-flex items-center gap-1 bg-amber-100 text-amber-700 px-3 py-1.5 rounded-lg text-xs font-bold border border-amber-200">
                        <span class="w-2 h-2 rounded-full bg-amber-500 animate-pulse inline-block"></span> PENDING
                    </span>
                @elseif($scheduleRequest->status == 'APPROVED')
                    <span class="inline-flex items-center gap-1 bg-emerald-100 text-emerald-700 px-3 py-1.5 rounded-lg text-xs font-bold border border-emerald-200">
                        <i class="fas fa-check"></i> APPROVED
                    </span>
                @else
                    <span class="inline-flex items-center gap-1 bg-red-100 text-red-700 px-3 py-1.5 rounded-lg text-xs font-bold border border-red-200">
                        <i class="fas fa-times"></i> REJECTED
                    </span>
                @endif
            </div>

            <div class="bg-slate-50 rounded-lg p-4 border border-slate-200">
                <p class="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Tipe Request</p>
                <p class="text-sm font-semibold text-indigo-700">{{ $scheduleRequest->tipe_request ?? 'Perubahan Jadwal' }}</p>
            </div>

            @if($scheduleRequest->alasan)
            <div class="mt-4 bg-slate-50 rounded-lg p-4 border border-slate-200">
                <p class="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Alasan dari Dosen</p>
                <p class="text-sm text-slate-700 leading-relaxed">{{ $scheduleRequest->alasan }}</p>
            </div>
            @endif

            @if($scheduleRequest->catatan_admin && $scheduleRequest->status != 'PENDING')
            <div class="mt-4 bg-indigo-50 rounded-lg p-4 border border-indigo-200">
                <p class="text-xs font-bold text-indigo-600 uppercase tracking-wider mb-2">Catatan Tim Penjadwalan</p>
                <p class="text-sm text-indigo-800">{{ $scheduleRequest->catatan_admin }}</p>
            </div>
            @endif
        </div>

        {{-- Perbandingan Jadwal Sebelum & Sesudah --}}
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div class="p-5 border-b border-slate-200 bg-slate-50">
                <h3 class="font-bold text-slate-800"><i class="fas fa-exchange-alt text-indigo-500 mr-2"></i> Perbandingan Perubahan yang Diminta</h3>
            </div>
            <div class="p-6">
                <div class="grid grid-cols-2 gap-6">
                    {{-- Sebelum --}}
                    <div>
                        <div class="flex items-center gap-2 mb-3">
                            <span class="w-2 h-2 rounded-full bg-slate-400 inline-block"></span>
                            <p class="text-xs font-bold text-slate-500 uppercase tracking-wider">Jadwal Saat Ini</p>
                        </div>
                        @if($jadwal)
                        <div class="space-y-3 bg-slate-50 rounded-lg p-4 border border-slate-200">
                            <div>
                                <p class="text-[10px] text-slate-400 uppercase tracking-wider">Hari & Jam</p>
                                <p class="text-sm font-semibold text-slate-700">{{ $jadwal->hari }}, {{ $jadwal->jam_mulai }}–{{ $jadwal->jam_selesai }}</p>
                            </div>
                            <div>
                                <p class="text-[10px] text-slate-400 uppercase tracking-wider">Ruangan</p>
                                <p class="text-sm font-semibold text-slate-700">{{ $jadwal->ruangan }}</p>
                            </div>
                            <div>
                                <p class="text-[10px] text-slate-400 uppercase tracking-wider">Dosen</p>
                                <p class="text-sm font-semibold text-slate-700">{{ $jadwal->nama_dosen }}</p>
                            </div>
                        </div>
                        @else
                        <p class="text-sm text-slate-400 italic">Data jadwal tidak ditemukan.</p>
                        @endif
                    </div>

                    {{-- Sesudah (yang diminta) --}}
                    <div>
                        <div class="flex items-center gap-2 mb-3">
                            <span class="w-2 h-2 rounded-full bg-indigo-500 inline-block"></span>
                            <p class="text-xs font-bold text-indigo-600 uppercase tracking-wider">Perubahan yang Diminta</p>
                        </div>
                        @php $detail = $scheduleRequest->detail_perubahan ?? []; @endphp
                        <div class="space-y-3 bg-indigo-50 rounded-lg p-4 border border-indigo-200">
                            @if(isset($detail['hari']) || isset($detail['jam_mulai']))
                            <div>
                                <p class="text-[10px] text-indigo-500 uppercase tracking-wider">Hari & Jam</p>
                                <p class="text-sm font-semibold text-indigo-800">
                                    {{ $detail['hari'] ?? $jadwal?->hari }},
                                    {{ $detail['jam_mulai'] ?? $jadwal?->jam_mulai }}–{{ $detail['jam_selesai'] ?? $jadwal?->jam_selesai }}
                                </p>
                            </div>
                            @endif
                            @if(isset($detail['ruangan']))
                            <div>
                                <p class="text-[10px] text-indigo-500 uppercase tracking-wider">Ruangan</p>
                                <p class="text-sm font-semibold text-indigo-800">{{ $detail['ruangan'] }}</p>
                            </div>
                            @endif
                            @if(isset($detail['nama_dosen']))
                            <div>
                                <p class="text-[10px] text-indigo-500 uppercase tracking-wider">Dosen</p>
                                <p class="text-sm font-semibold text-indigo-800">{{ $detail['nama_dosen'] }}</p>
                            </div>
                            @endif
                            @if(empty($detail))
                            <p class="text-xs text-indigo-500 italic">Tidak ada detail perubahan spesifik.</p>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- ===== PANEL AKSI ===== --}}
    <div class="space-y-4">

        @if($scheduleRequest->status == 'PENDING')

        {{-- Approve --}}
        <div class="bg-white rounded-xl shadow-sm border border-emerald-200 overflow-hidden">
            <div class="p-4 bg-emerald-50 border-b border-emerald-200">
                <h4 class="font-bold text-emerald-800 text-sm flex items-center gap-2">
                    <i class="fas fa-check-circle text-emerald-600"></i> Setujui Request
                </h4>
                <p class="text-xs text-emerald-700 mt-1">Perubahan akan diterapkan ke jadwal. Collision detection tetap berjalan.</p>
            </div>
            <form action="{{ route('penjadwalan.requests.approve', $scheduleRequest->id) }}" method="POST" class="p-4">
                @csrf @method('PATCH')
                <textarea name="catatan_admin" rows="3"
                    class="w-full border border-slate-200 rounded-lg p-3 text-sm focus:ring-2 focus:ring-emerald-500 outline-none mb-3"
                    placeholder="Catatan (opsional)..."></textarea>
                <button type="submit"
                    class="w-full bg-emerald-500 text-white py-2.5 rounded-lg text-sm font-bold hover:bg-emerald-600 shadow-sm transition"
                    onclick="return confirm('Approve request ini? Perubahan akan langsung diterapkan ke jadwal.')">
                    <i class="fas fa-check mr-1"></i> Approve & Terapkan Perubahan
                </button>
            </form>
        </div>

        {{-- Reject --}}
        <div class="bg-white rounded-xl shadow-sm border border-red-200 overflow-hidden">
            <div class="p-4 bg-red-50 border-b border-red-200">
                <h4 class="font-bold text-red-800 text-sm flex items-center gap-2">
                    <i class="fas fa-times-circle text-red-600"></i> Tolak Request
                </h4>
                <p class="text-xs text-red-700 mt-1">Dosen akan diberitahu alasan penolakan.</p>
            </div>
            <form action="{{ route('penjadwalan.requests.reject', $scheduleRequest->id) }}" method="POST" class="p-4">
                @csrf @method('PATCH')
                <textarea name="catatan_admin" rows="3" required
                    class="w-full border border-slate-200 rounded-lg p-3 text-sm focus:ring-2 focus:ring-red-500 outline-none mb-3"
                    placeholder="Alasan penolakan (wajib diisi)..."></textarea>
                <button type="submit"
                    class="w-full bg-red-500 text-white py-2.5 rounded-lg text-sm font-bold hover:bg-red-600 shadow-sm transition"
                    onclick="return confirm('Tolak request ini?')">
                    <i class="fas fa-times mr-1"></i> Tolak Request
                </button>
            </form>
        </div>

        @else

        {{-- Sudah diproses --}}
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
            <p class="text-xs text-slate-500 font-bold uppercase tracking-wider mb-3">Status Request</p>
            @if($scheduleRequest->status == 'APPROVED')
                <div class="flex items-center gap-3 text-emerald-700">
                    <i class="fas fa-check-circle text-2xl"></i>
                    <div>
                        <p class="font-bold text-sm">Request Disetujui</p>
                        <p class="text-xs text-slate-500">Perubahan telah diterapkan ke jadwal.</p>
                    </div>
                </div>
            @else
                <div class="flex items-center gap-3 text-red-700">
                    <i class="fas fa-times-circle text-2xl"></i>
                    <div>
                        <p class="font-bold text-sm">Request Ditolak</p>
                        <p class="text-xs text-slate-500">Tidak ada perubahan pada jadwal.</p>
                    </div>
                </div>
            @endif
            @if($scheduleRequest->catatan_admin)
            <div class="mt-3 bg-slate-50 rounded-lg p-3 border border-slate-200">
                <p class="text-[10px] text-slate-400 font-bold uppercase mb-1">Catatan</p>
                <p class="text-xs text-slate-700">{{ $scheduleRequest->catatan_admin }}</p>
            </div>
            @endif
        </div>

        @endif

    </div>
</div>

@endsection