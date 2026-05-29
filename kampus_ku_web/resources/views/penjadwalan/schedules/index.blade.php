@extends('layouts.app')

<<<<<<< HEAD
@section('page_title', 'Status Tracking Jadwal')

@section('content')

    {{-- Alert Collision --}}
=======
<<<<<<< HEAD
@section('page_title', 'Status Tracking Jadwal (Prodi Anda)')

@section('content')
    <!-- Alert Jika Terdeteksi Bentrok (Collision Detection) -->
=======
@section('page_title', 'Status Tracking Jadwal')

@section('content')

    {{-- Alert Collision --}}
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
    @if(session('error'))
    <div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
        <i class="fas fa-exclamation-triangle text-red-500 mt-0.5"></i>
        <div>
            <h4 class="font-bold text-sm text-red-800">Collision Detected (Bentrok Jadwal!)</h4>
            <p class="text-xs mt-1 text-red-700">{{ session('error') }}</p>
            @if(session('conflict_detail'))
<<<<<<< HEAD
                <p class="text-xs mt-1 text-red-600 font-mono bg-red-100 px-2 py-1 rounded inline-block">
                    Bentrok dengan: {{ session('conflict_detail')->nama_mk }} ({{ session('conflict_detail')->ruangan }})
                </p>
=======
<<<<<<< HEAD
                <p class="text-xs mt-1 text-red-600 font-mono">Bentrok dengan: {{ session('conflict_detail')->nama_mk }} ({{ session('conflict_detail')->ruangan }})</p>
=======
                <p class="text-xs mt-1 text-red-600 font-mono bg-red-100 px-2 py-1 rounded inline-block">
                    Bentrok dengan: {{ session('conflict_detail')->nama_mk }} ({{ session('conflict_detail')->ruangan }})
                </p>
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
            @endif
        </div>
    </div>
    @endif

<<<<<<< HEAD
    @if(session('success'))
    <div class="mb-6 bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
        <i class="fas fa-check-circle text-emerald-500 mt-0.5"></i>
        <p class="text-sm text-emerald-800 font-medium">{{ session('success') }}</p>
    </div>
    @endif

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
=======
<<<<<<< HEAD
    <!-- Dashboard Stats Tracking Jadwal -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
>>>>>>> nazriel
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-slate-400">
            <p class="text-xs text-slate-500 font-bold uppercase tracking-wider mb-1">Draft</p>
            <h3 class="text-3xl font-black text-slate-800">
                {{ $count_draft ?? 0 }} <span class="text-sm font-medium text-slate-400">Matkul</span>
            </h3>
            <p class="text-xs text-slate-400 mt-1">Belum difinalisasi</p>
        </div>
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-emerald-500">
            <p class="text-xs text-emerald-600 font-bold uppercase tracking-wider mb-1">Published</p>
            <h3 class="text-3xl font-black text-slate-800">
                {{ $count_published ?? 0 }} <span class="text-sm font-medium text-slate-400">Matkul</span>
            </h3>
            <p class="text-xs text-slate-400 mt-1">Live di HP mahasiswa</p>
        </div>
    </div>

    {{-- Tabel Jadwal --}}
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="p-5 border-b border-slate-200 flex justify-between items-center bg-slate-50">
<<<<<<< HEAD
=======
            <h3 class="font-bold text-slate-800"><i class="fas fa-list text-indigo-500 mr-2"></i> Daftar Jadwal Kuliah</h3>
            <button class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition">
                <i class="fas fa-plus mr-1"></i> Input Jadwal Baru
            </button>
=======
    @if(session('success'))
    <div class="mb-6 bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
        <i class="fas fa-check-circle text-emerald-500 mt-0.5"></i>
        <p class="text-sm text-emerald-800 font-medium">{{ session('success') }}</p>
    </div>
    @endif

    {{-- Stats Cards — Final (Tunggu Kajur) dihapus, diganti 2 card saja --}}
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-slate-400">
            <p class="text-xs text-slate-500 font-bold uppercase tracking-wider mb-1">Draft</p>
            <h3 class="text-3xl font-black text-slate-800">
                {{ $count_draft ?? 0 }} <span class="text-sm font-medium text-slate-400">Matkul</span>
            </h3>
            <p class="text-xs text-slate-400 mt-1">Belum difinalisasi</p>
        </div>
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-emerald-500">
            <p class="text-xs text-emerald-600 font-bold uppercase tracking-wider mb-1">Published</p>
            <h3 class="text-3xl font-black text-slate-800">
                {{ $count_published ?? 0 }} <span class="text-sm font-medium text-slate-400">Matkul</span>
            </h3>
            <p class="text-xs text-slate-400 mt-1">Live di HP mahasiswa</p>
        </div>
    </div>

    {{-- Tabel Jadwal --}}
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="p-5 border-b border-slate-200 flex justify-between items-center bg-slate-50">
>>>>>>> nazriel
            <h3 class="font-bold text-slate-800">
                <i class="fas fa-list text-indigo-500 mr-2"></i> Daftar Jadwal Kuliah
            </h3>

            {{-- Tombol Input Jadwal hanya untuk TIM_PENJADWALAN --}}
            @if(auth()->user()->role == 'TIM_PENJADWALAN')
                <a href="{{ route('penjadwalan.schedules.create') }}"
                   class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition">
                    <i class="fas fa-plus mr-1"></i> Input Jadwal Baru
                </a>
            @endif
<<<<<<< HEAD
=======
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm min-w-[800px]">
                <thead class="bg-slate-50 border-b border-slate-200">
                    <tr>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/3">Mata Kuliah & Dosen</th>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/4">Waktu & Ruangan</th>
<<<<<<< HEAD
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Status</th>
=======
<<<<<<< HEAD
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/4">Status</th>
=======
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Status</th>
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($schedules ?? [] as $jadwal)
<<<<<<< HEAD
                    <tr class="hover:bg-slate-50 transition">
=======
<<<<<<< HEAD
                    <tr class="hover:bg-slate-50">
=======
                    <tr class="hover:bg-slate-50 transition">
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
                        <td class="px-6 py-4">
                            <p class="font-bold text-slate-800">{{ $jadwal->nama_mk }}</p>
                            <p class="text-xs text-slate-500">{{ $jadwal->nama_dosen }}</p>
                        </td>
                        <td class="px-6 py-4">
<<<<<<< HEAD
                            <p class="font-medium text-slate-800">
                                {{ $jadwal->hari }}, {{ \Carbon\Carbon::parse($jadwal->jam_mulai)->format('H:i') }}–{{ \Carbon\Carbon::parse($jadwal->jam_selesai)->format('H:i') }}
                            </p>
=======
<<<<<<< HEAD
                            <p class="font-medium text-slate-800">{{ $jadwal->hari }}, {{ Carbon\Carbon::parse($jadwal->jam_mulai)->format('H:i') }}</p>
>>>>>>> nazriel
                            <p class="text-xs text-slate-500">{{ $jadwal->ruangan }}</p>
                        </td>
                        <td class="px-6 py-4">
                            @include('penjadwalan.partials.status-badge', ['status' => $jadwal->status])
                        </td>
                        <td class="px-6 py-4 text-right">

                            @if(auth()->user()->role == 'TIM_PENJADWALAN')
                                {{-- Tim Penjadwalan: hanya bisa edit selama masih DRAFT --}}
                                @if($jadwal->status == 'DRAFT')
                                    <a href="{{ route('penjadwalan.schedules.edit', $jadwal->id) }}"
                                       class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                        <i class="fas fa-edit mr-1"></i> Edit
                                    </a>
                                @elseif($jadwal->status == 'FINAL')
                                    <span class="text-[10px] text-yellow-600 font-medium italic">Menunggu Admin TU</span>
                                @else
                                    <span class="text-xs text-emerald-600">
                                        <i class="fas fa-check-circle"></i> Live di Mhs
                                    </span>
                                @endif

                            @elseif(auth()->user()->role == 'ADMIN_TU')
                                {{-- Admin TU: finalisasi & publikasi --}}
                                @if($jadwal->status == 'DRAFT')
                                    <form action="{{ route('admin.schedules.finalize', $jadwal->id) }}" method="POST">
                                        @csrf @method('PATCH')
                                        <button type="submit"
                                                onclick="return confirm('Finalisasi jadwal {{ $jadwal->nama_mk }}?')"
                                                class="text-indigo-600 hover:text-indigo-800 font-semibold text-xs bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                            <i class="fas fa-check mr-1"></i> Finalisasi
                                        </button>
                                    </form>
                                @elseif($jadwal->status == 'FINAL')
                                    <button onclick="bukaModalPublish('{{ $jadwal->id }}')"
                                            class="bg-emerald-500 text-white font-semibold text-xs px-3 py-1.5 rounded shadow-sm hover:bg-emerald-600 transition">
                                        <i class="fas fa-paper-plane mr-1"></i> Publikasi
                                    </button>
                                @else
                                    <span class="text-xs text-emerald-600">
                                        <i class="fas fa-check-circle"></i> Live di Mhs
                                    </span>
                                @endif

                            @endif
<<<<<<< HEAD

=======
=======
                            <p class="font-medium text-slate-800">
                                {{ $jadwal->hari }}, {{ \Carbon\Carbon::parse($jadwal->jam_mulai)->format('H:i') }}–{{ \Carbon\Carbon::parse($jadwal->jam_selesai)->format('H:i') }}
                            </p>
                            <p class="text-xs text-slate-500">{{ $jadwal->ruangan }}</p>
                        </td>
                        <td class="px-6 py-4">
                            @include('penjadwalan.partials.status-badge', ['status' => $jadwal->status])
                        </td>
                        <td class="px-6 py-4 text-right">

                            @if(auth()->user()->role == 'TIM_PENJADWALAN')
                                {{-- Tim Penjadwalan: hanya bisa edit selama masih DRAFT --}}
                                @if($jadwal->status == 'DRAFT')
                                    <a href="{{ route('penjadwalan.schedules.edit', $jadwal->id) }}"
                                       class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                        <i class="fas fa-edit mr-1"></i> Edit
                                    </a>
                                @elseif($jadwal->status == 'FINAL')
                                    <span class="text-[10px] text-yellow-600 font-medium italic">Menunggu Admin TU</span>
                                @else
                                    <span class="text-xs text-emerald-600">
                                        <i class="fas fa-check-circle"></i> Live di Mhs
                                    </span>
                                @endif

                            @elseif(auth()->user()->role == 'ADMIN_TU')
                                {{-- Admin TU: finalisasi & publikasi --}}
                                @if($jadwal->status == 'DRAFT')
                                    <form action="{{ route('admin.schedules.finalize', $jadwal->id) }}" method="POST">
                                        @csrf @method('PATCH')
                                        <button type="submit"
                                                onclick="return confirm('Finalisasi jadwal {{ $jadwal->nama_mk }}?')"
                                                class="text-indigo-600 hover:text-indigo-800 font-semibold text-xs bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                            <i class="fas fa-check mr-1"></i> Finalisasi
                                        </button>
                                    </form>
                                @elseif($jadwal->status == 'FINAL')
                                    <button onclick="bukaModalPublish('{{ $jadwal->id }}')"
                                            class="bg-emerald-500 text-white font-semibold text-xs px-3 py-1.5 rounded shadow-sm hover:bg-emerald-600 transition">
                                        <i class="fas fa-paper-plane mr-1"></i> Publikasi
                                    </button>
                                @else
                                    <span class="text-xs text-emerald-600">
                                        <i class="fas fa-check-circle"></i> Live di Mhs
                                    </span>
                                @endif

                            @endif

>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
                        </td>
                    </tr>
                    @empty
                    <tr>
<<<<<<< HEAD
                        <td colspan="4" class="px-6 py-8 text-center text-slate-500 text-sm">
                            Belum ada data jadwal perkuliahan.
                        </td>
=======
<<<<<<< HEAD
                        <td colspan="4" class="px-6 py-8 text-center text-slate-500 text-sm">Belum ada data jadwal perkuliahan.</td>
=======
                        <td colspan="4" class="px-6 py-8 text-center text-slate-500 text-sm">
                            Belum ada data jadwal perkuliahan.
                        </td>
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

<<<<<<< HEAD
    {{-- Modal Publikasi — hanya relevan untuk ADMIN_TU --}}
    @if(auth()->user()->role == 'ADMIN_TU')
=======
<<<<<<< HEAD
    <!-- Modal Publikasi (Wajib Isi Pesan Pengantar) -->
=======
    {{-- Modal Publikasi — hanya relevan untuk ADMIN_TU --}}
    @if(auth()->user()->role == 'ADMIN_TU')
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
    <div id="modal-publish" class="fixed inset-0 bg-slate-900/50 hidden z-50 flex items-center justify-center backdrop-blur-sm">
        <div class="bg-white rounded-xl shadow-2xl max-w-md w-full m-4 overflow-hidden">
            <form id="form-publish" method="POST" action="">
                @csrf @method('PATCH')
                <div class="p-6">
<<<<<<< HEAD
                    <div class="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center text-xl mb-4">
=======
<<<<<<< HEAD
                    <div class="w-12 h-12 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center text-xl mb-4">
>>>>>>> nazriel
                        <i class="fas fa-paper-plane"></i>
                    </div>
                    <h3 class="text-xl font-bold text-slate-800 mb-2">Publikasi Jadwal</h3>
                    <p class="text-sm text-slate-600 mb-4">
                        Jadwal akan dikirim ke seluruh mahasiswa prodi via Push Notification.
                        <strong>Wajib isi pesan pengantar!</strong>
                    </p>

                    <textarea name="pesan_pengantar" required rows="3"
                              class="w-full border border-slate-300 rounded-lg p-3 text-sm focus:ring-2 focus:ring-emerald-500 outline-none mb-4 resize-none"
                              placeholder="Cth: Jadwal semester genap telah resmi diterbitkan..."></textarea>

                    <div class="flex gap-3 justify-end">
<<<<<<< HEAD
=======
                        <button type="button" onclick="document.getElementById('modal-publish').classList.add('hidden')" class="px-4 py-2 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100">Batal</button>
                        <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-bold shadow-md hover:bg-indigo-700">Kirim & Publikasi</button>
=======
                    <div class="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center text-xl mb-4">
                        <i class="fas fa-paper-plane"></i>
                    </div>
                    <h3 class="text-xl font-bold text-slate-800 mb-2">Publikasi Jadwal</h3>
                    <p class="text-sm text-slate-600 mb-4">
                        Jadwal akan dikirim ke seluruh mahasiswa prodi via Push Notification.
                        <strong>Wajib isi pesan pengantar!</strong>
                    </p>

                    <textarea name="pesan_pengantar" required rows="3"
                              class="w-full border border-slate-300 rounded-lg p-3 text-sm focus:ring-2 focus:ring-emerald-500 outline-none mb-4 resize-none"
                              placeholder="Cth: Jadwal semester genap telah resmi diterbitkan..."></textarea>

                    <div class="flex gap-3 justify-end">
>>>>>>> nazriel
                        <button type="button"
                                onclick="document.getElementById('modal-publish').classList.add('hidden')"
                                class="px-4 py-2 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100 transition">
                            Batal
                        </button>
                        <button type="submit"
                                class="bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm font-bold shadow-md hover:bg-emerald-700 transition">
                            <i class="fas fa-paper-plane mr-1"></i> Kirim & Publikasi
                        </button>
<<<<<<< HEAD
=======
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
                    </div>
                </div>
            </form>
        </div>
    </div>

    <script>
        function bukaModalPublish(id) {
<<<<<<< HEAD
            document.getElementById('form-publish').action = '{{ url("/jurusan/schedules") }}/' + id + '/publish';
            document.getElementById('modal-publish').classList.remove('hidden');
        }
    </script>
    @endif

@endsection
=======
<<<<<<< HEAD
            document.getElementById('form-publish').action = '/jurusan/schedules/' + id + '/publish';
            document.getElementById('modal-publish').classList.remove('hidden');
        }
    </script>
@endsection
=======
            document.getElementById('form-publish').action = '{{ url("/jurusan/schedules") }}/' + id + '/publish';
            document.getElementById('modal-publish').classList.remove('hidden');
        }
    </script>
    @endif

@endsection
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
>>>>>>> nazriel
