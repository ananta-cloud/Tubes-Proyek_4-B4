@extends('layouts.app')

@section('page_title', 'Status Tracking Jadwal (Prodi Anda)')

@section('content')
    <!-- Alert Jika Terdeteksi Bentrok (Collision Detection) -->
    @if(session('error'))
    <div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
        <i class="fas fa-exclamation-triangle text-red-500 mt-0.5"></i>
        <div>
            <h4 class="font-bold text-sm text-red-800">Collision Detected (Bentrok Jadwal!)</h4>
            <p class="text-xs mt-1 text-red-700">{{ session('error') }}</p>
            @if(session('conflict_detail'))
                <p class="text-xs mt-1 text-red-600 font-mono">Bentrok dengan: {{ session('conflict_detail')->nama_mk }} ({{ session('conflict_detail')->ruangan }})</p>
            @endif
        </div>
    </div>
    @endif

    <!-- Dashboard Stats Tracking Jadwal -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-slate-400">
            <p class="text-xs text-slate-500 font-bold uppercase tracking-wider mb-1">Status Draft (Oleh TU)</p>
            <h3 class="text-3xl font-black text-slate-800">{{ $count_draft ?? 0 }} <span class="text-sm font-medium text-slate-400">Matkul</span></h3>
        </div>
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-yellow-400">
            <p class="text-xs text-yellow-600 font-bold uppercase tracking-wider mb-1">Final (Tunggu Kajur)</p>
            <h3 class="text-3xl font-black text-slate-800">{{ $count_final ?? 0 }} <span class="text-sm font-medium text-slate-400">Matkul</span></h3>
        </div>
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-green-500">
            <p class="text-xs text-green-600 font-bold uppercase tracking-wider mb-1">Published (Live HP Mhs)</p>
            <h3 class="text-3xl font-black text-slate-800">{{ $count_published ?? 0 }} <span class="text-sm font-medium text-slate-400">Matkul</span></h3>
        </div>
    </div>

    <!-- Tabel Rekapitulasi Jadwal -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="p-5 border-b border-slate-200 flex justify-between items-center bg-slate-50">
            <h3 class="font-bold text-slate-800"><i class="fas fa-list text-indigo-500 mr-2"></i> Daftar Jadwal Kuliah</h3>
            <button class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition">
                <i class="fas fa-plus mr-1"></i> Input Jadwal Baru
            </button>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm min-w-[800px]">
                <thead class="bg-slate-50 border-b border-slate-200">
                    <tr>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/3">Mata Kuliah & Dosen</th>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/4">Waktu & Ruangan</th>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/4">Status</th>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($schedules ?? [] as $jadwal)
                    <tr class="hover:bg-slate-50">
                        <td class="px-6 py-4">
                            <p class="font-bold text-slate-800">{{ $jadwal->nama_mk }}</p>
                            <p class="text-xs text-slate-500">{{ $jadwal->nama_dosen }}</p>
                        </td>
                        <td class="px-6 py-4">
                            <p class="font-medium text-slate-800">{{ $jadwal->hari }}, {{ Carbon\Carbon::parse($jadwal->jam_mulai)->format('H:i') }}</p>
                            <p class="text-xs text-slate-500">{{ $jadwal->ruangan }}</p>
                        </td>
                        <td class="px-6 py-4">
                            @if($jadwal->status == 'DRAFT')
                                <span class="bg-slate-100 text-slate-600 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-slate-200">DRAFT</span>
                            @elseif($jadwal->status == 'FINAL')
                                <span class="bg-yellow-100 text-yellow-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-yellow-200">FINAL</span>
                            @else
                                <span class="bg-emerald-100 text-emerald-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-emerald-200">PUBLISHED</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-right">
                            @if($jadwal->status == 'DRAFT')
                                <!-- Tombol Finalisasi (Bisa oleh TU & Kajur) -->
                                <form action="{{ url('/jurusan/schedules/'.$jadwal->id.'/finalize') }}" method="POST">
                                    @csrf @method('PATCH')
                                    <button type="submit" class="text-indigo-600 hover:text-indigo-800 font-semibold text-xs bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100">Finalisasi</button>
                                </form>
                            @elseif($jadwal->status == 'FINAL')
                                <!-- Logika RBAC: Hanya KAJUR yang bisa mempublikasikan jadwal -->
                                @if(auth()->user()->role == 'KAJUR')
                                    <button onclick="bukaModalPublish('{{ $jadwal->id }}')" class="bg-emerald-500 text-white font-semibold text-xs px-3 py-1.5 rounded shadow-sm hover:bg-emerald-600 transition">
                                        <i class="fas fa-paper-plane mr-1"></i> Publikasi
                                    </button>
                                @else
                                    <span class="text-[10px] text-yellow-600 font-medium italic">Menunggu Kajur</span>
                                @endif
                            @else
                                <span class="text-xs text-emerald-600"><i class="fas fa-check-circle"></i> Live di Mhs</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="4" class="px-6 py-8 text-center text-slate-500 text-sm">Belum ada data jadwal perkuliahan.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Modal Publikasi (Wajib Isi Pesan Pengantar) -->
    <div id="modal-publish" class="fixed inset-0 bg-slate-900/50 hidden z-50 flex items-center justify-center backdrop-blur-sm">
        <div class="bg-white rounded-xl shadow-2xl max-w-md w-full m-4 overflow-hidden">
            <form id="form-publish" method="POST" action="">
                @csrf @method('PATCH')
                <div class="p-6">
                    <div class="w-12 h-12 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center text-xl mb-4">
                        <i class="fas fa-paper-plane"></i>
                    </div>
                    <h3 class="text-xl font-bold text-slate-800 mb-2">Publikasi Jadwal</h3>
                    <p class="text-sm text-slate-600 mb-4">Anda akan mengirimkan Push Notification ke seluruh mahasiswa prodi. <strong>Wajib isi pesan pengantar!</strong></p>

                    <textarea name="pesan_pengantar" required rows="3" class="w-full border border-slate-300 rounded-lg p-3 text-sm focus:ring-2 focus:ring-indigo-500 outline-none mb-4" placeholder="Cth: Perubahan ruangan Basis Data menjadi Lab RPL 2..."></textarea>

                    <div class="flex gap-3 justify-end">
                        <button type="button" onclick="document.getElementById('modal-publish').classList.add('hidden')" class="px-4 py-2 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100">Batal</button>
                        <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-bold shadow-md hover:bg-indigo-700">Kirim & Publikasi</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <script>
        function bukaModalPublish(id) {
            document.getElementById('form-publish').action = '/jurusan/schedules/' + id + '/publish';
            document.getElementById('modal-publish').classList.remove('hidden');
        }
    </script>
@endsection
