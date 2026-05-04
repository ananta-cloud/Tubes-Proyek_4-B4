@extends('layouts.app')

<<<<<<< HEAD
@section('page_title', 'Manajemen Pengumuman')

@section('content')
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

    <!-- Kolom Kiri: Form Buat Pengumuman -->
    <div class="lg:col-span-2 bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 class="font-bold text-slate-800 mb-4 border-b pb-2"><i class="fas fa-edit text-indigo-500 mr-2"></i> Buat Pengumuman Baru</h3>

        <form action="{{ auth()->user()->role == 'MANAJEMEN' ? url('/manajemen/announcements') : url('/jurusan/announcements') }}" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">Judul Pengumuman</label>
                <input type="text" name="judul" required class="w-full border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="Cth: Jadwal Ujian Tengah Semester...">
            </div>

            <div class="grid grid-cols-2 gap-4">
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Kategori (Could Have)</label>
                    <select name="kategori" class="w-full border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                        <option value="Akademik">Akademik</option>
                        <option value="Beasiswa">Beasiswa</option>
                        <option value="Kemahasiswaan">Kemahasiswaan</option>
                    </select>
                </div>

                <!-- Input Targeting (Should Have - DOCX) -->
                @if(auth()->user()->role != 'MANAJEMEN')
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Target Spesifik Prodi</label>
                    <select name="id_prodi" class="w-full border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                        <option value="">-- Seluruh Jurusan --</option>
                        @foreach($prodiList ?? [] as $prodi)
                            <option value="{{ $prodi->id }}">{{ $prodi->nama_prodi }}</option>
                        @endforeach
                    </select>
                </div>
                @else
                <!-- Jika Manajemen Kampus, otomatis broadcast ke seluruh kampus -->
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Targeting (Manajemen)</label>
                    <input type="text" disabled value="Tag UMUM (Broadcast ke Semua Mahasiswa)" class="w-full border border-slate-200 bg-slate-50 text-slate-500 rounded-lg px-4 py-2 text-sm">
                </div>
                @endif
            </div>

            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">Isi Pengumuman</label>
                <textarea name="isi" required rows="5" class="w-full border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="Tuliskan detail pengumuman di sini..."></textarea>
            </div>

            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-indigo-600 text-white font-bold py-2 px-6 rounded-lg text-sm shadow-md hover:bg-indigo-700 transition">
                    <i class="fas fa-paper-plane mr-2"></i> Terbitkan via FCM
                </button>
            </div>
        </form>
    </div>

    <!-- Kolom Kanan: Panel Statistik & Cross-posting -->
    <div class="space-y-6">

        <!-- Read Confirmation Widget (Should Have) -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
            <h4 class="font-bold text-slate-800 mb-3 text-sm"><i class="fas fa-chart-pie text-indigo-500 mr-2"></i> Read Confirmation</h4>
            <div class="space-y-4">
                @forelse($announcements ?? [] as $ann)
                @php
                    $total_baca = is_array($ann->read_by_users) ? count($ann->read_by_users) : 0;
                    // Simulasi perhitungan persentase
                    $persentase = $total_baca > 0 ? min(100, ($total_baca / 200) * 100) : 0;
                @endphp
                <div>
                    <div class="flex justify-between text-xs font-semibold mb-1">
                        <span class="truncate w-32" title="{{ $ann->judul }}">{{ $ann->judul }}</span>
                        <span class="text-indigo-600">{{ round($persentase) }}% ({{ $total_baca }} dibaca)</span>
                    </div>
                    <div class="w-full bg-slate-100 rounded-full h-1.5">
                        <div class="bg-indigo-500 h-1.5 rounded-full" style="width: {{ $persentase }}%"></div>
                    </div>
                </div>
                @empty
                <p class="text-xs text-slate-500">Belum ada pengumuman diterbitkan.</p>
                @endforelse
            </div>
        </div>

        <!-- Cross-posting Helper (Khusus Manajemen Kampus - Could Have) -->
        @if(auth()->user()->role == 'MANAJEMEN')
        <div class="bg-emerald-50 rounded-xl shadow-sm border border-emerald-200 p-5">
            <h4 class="font-bold text-emerald-800 mb-2 text-sm"><i class="fab fa-whatsapp text-emerald-600 mr-2"></i> Cross-posting Helper</h4>
            <p class="text-[10px] text-emerald-700 mb-3">Setelah menerbitkan di atas, gunakan form ini untuk menyalin format broadcast WhatsApp/IG.</p>

            <div class="bg-white p-3 rounded border border-emerald-100 text-[11px] font-mono text-slate-600 h-28 overflow-y-auto mb-2 select-all cursor-text">
                *[PENGUMUMAN POLBAN]*<br><br>
                *(JUDUL OTOMATIS GENERATE)*<br>
                Segera lengkapi berkas di ruang akademik.<br><br>
                _Detail lebih lanjut, buka aplikasi mobile SIGMA._
            </div>

            <button class="w-full bg-emerald-500 text-white py-1.5 rounded text-xs font-bold shadow-sm hover:bg-emerald-600 transition">Copy ke Clipboard</button>
        </div>
        @endif

    </div>
</div>
=======
@section('content')
<div class="container mx-auto px-4 py-0">

    <div class="flex flex-col md:flex-row justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-indigo-900 mb-4 md:mb-0">Manajemen Pengumuman Pusat</h1>
        <a href="{{ route('manajemen.announcements.create') }}" class="bg-indigo-600 text-white px-5 py-2.5 rounded-lg font-semibold shadow-md hover:bg-indigo-700 transition duration-200">
            <i class="fas fa-plus mr-2"></i> Buat Pengumuman Umum
        </a>
    </div>

    @if(session('success'))
        <div class="mb-6 p-4 bg-green-50 border-l-4 border-green-500 text-green-700 rounded-r-lg shadow-sm">
            <p class="font-bold"><i class="fas fa-check-circle mr-2"></i> Berhasil!</p>
            <p class="text-sm">{{ session('success') }}</p>
        </div>
    @endif

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div class="bg-white p-5 rounded-xl shadow-sm border border-gray-100 flex items-center">
            <div class="bg-indigo-100 p-3 rounded-lg text-indigo-600 mr-4"><i class="fas fa-bullhorn text-xl"></i></div>
            <div>
                <p class="text-sm text-gray-500 font-medium">Total Pengumuman</p>
                <p class="text-2xl font-bold text-gray-800">{{ $total }}</p>
            </div>
        </div>
        <div class="bg-white p-5 rounded-xl shadow-sm border border-gray-100 flex items-center">
            <div class="bg-green-100 p-3 rounded-lg text-green-600 mr-4"><i class="fas fa-calendar-check text-xl"></i></div>
            <div>
                <p class="text-sm text-gray-500 font-medium">Bulan Ini</p>
                <p class="text-2xl font-bold text-gray-800">{{ $total_bulan_ini }}</p>
            </div>
        </div>
        <div class="bg-white p-5 rounded-xl shadow-sm border border-gray-100 flex items-center">
            <div class="bg-blue-100 p-3 rounded-lg text-blue-600 mr-4"><i class="fas fa-eye text-xl"></i></div>
            <div>
                <p class="text-sm text-gray-500 font-medium">Total Interaksi (Dibaca)</p>
                <p class="text-2xl font-bold text-gray-800">{{ $total_dibaca }} <span class="text-xs text-gray-400 font-normal">Mahasiswa</span></p>
            </div>
        </div>
    </div>

    <div class="bg-white rounded-xl shadow-md overflow-hidden border border-gray-100">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Judul & Target</th>
                        <th class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Kategori</th>
                        <th class="px-6 py-3 text-center text-xs font-bold text-gray-500 uppercase tracking-wider">Dibaca</th>
                        <th class="px-6 py-3 text-right text-xs font-bold text-gray-500 uppercase tracking-wider">Aksi</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-100">
                    @forelse($announcements as $item)
                    <tr class="hover:bg-gray-50 transition duration-150">
                        <td class="px-6 py-4">
                            <div class="text-sm font-bold text-gray-900 mb-1">{{ $item->judul }}</div>
                            <div class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium bg-gray-100 text-gray-800">
                                <i class="fas fa-users mr-1"></i> {{ str_replace('_', ' ', $item->target_audience) }}
                            </div>
                        </td>

                        <td class="px-6 py-4">
                            @php
                                $kategoriList = is_array($item->kategori) ? $item->kategori : [];
                                if (is_object($item->kategori) && method_exists($item->kategori, 'getArrayCopy')) {
                                    $kategoriList = $item->kategori->getArrayCopy();
                                }
                            @endphp

                            @if(count($kategoriList) > 0)
                                <div class="flex flex-wrap gap-1">
                                    @foreach($kategoriList as $cat)
                                    <span class="px-2 py-1 text-[10px] font-semibold bg-indigo-50 text-indigo-700 rounded-md border border-indigo-100">
                                        {{ $cat }}
                                    </span>
                                    @endforeach
                                </div>
                            @else
                                <span class="text-xs text-gray-400 italic">Tanpa Kategori</span>
                            @endif
                        </td>

                        <td class="px-6 py-4 text-center">
                            @php
                                $readCount = 0;
                                if (is_array($item->read_by_users)) {
                                    $readCount = count($item->read_by_users);
                                } elseif (is_object($item->read_by_users) && method_exists($item->read_by_users, 'count')) {
                                    $readCount = $item->read_by_users->count();
                                }
                            @endphp
                            <span class="text-sm font-bold text-blue-600 bg-blue-50 px-3 py-1 rounded-full">{{ $readCount }}</span>
                        </td>

                        <td class="px-6 py-4 text-right space-x-3 whitespace-nowrap">

                            <a href="{{ route('manajemen.announcements.show', (string) $item->_id) }}" class="text-blue-500 hover:text-blue-700 transition" title="Lihat Detail">
                                <i class="fas fa-eye text-lg"></i>
                            </a>

                            <button onclick="broadcastWA('{{ (string) $item->_id }}', this)" class="text-green-500 hover:text-green-700 transition" title="Kirim/Push ke WhatsApp">
                                <i class="fas fa-paper-plane text-lg"></i><i class="fab fa-whatsapp text-xs ml-0.5"></i>
                            </button>

                            <a href="{{ route('manajemen.announcements.edit', (string) $item->_id) }}" class="text-amber-500 hover:text-amber-700 transition" title="Edit">
                                <i class="fas fa-edit text-lg"></i>
                            </a>

                            <form action="{{ route('manajemen.announcements.destroy', (string) $item->_id) }}" method="POST" class="inline">
                                @csrf @method('DELETE')
                                <button type="submit" class="text-red-500 hover:text-red-700 transition" onclick="return confirm('Tarik pengumuman ini?')">
                                    <i class="fas fa-trash text-lg"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="4" class="px-6 py-12 text-center">
                            <div class="text-gray-400 mb-2"><i class="fas fa-folder-open text-4xl"></i></div>
                            <p class="text-gray-500 font-medium">Belum ada pengumuman yang diterbitkan.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($announcements->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $announcements->links() }}
        </div>
        @endif
    </div>
</div>

<script>
    function broadcastWA(id, btnElement) {
        if(!confirm('Kirim pengumuman ini langsung ke WhatsApp Mahasiswa?')) return;

        // Tampilkan indikator proses
        let originalContent = btnElement.innerHTML;
        btnElement.innerHTML = `<i class="fas fa-spinner fa-spin text-lg"></i>`;
        btnElement.disabled = true;

        fetch(`/manajemen/announcements/${id}/broadcast`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json', // <--- TAMBAHKAN BARIS INI
                'X-CSRF-TOKEN': '{{ csrf_token() }}' // Pastikan ini tetap pakai kurung kurawal Blade
            }
        })
        .then(async response => {
            // Tangkap respons JSON baik sukses maupun saat server error (500)
            const data = await response.json();

            if (response.ok) {
                alert(`✅ SUKSES: ${data.message || 'Terkirim'}`);
            } else {
                // Ini akan memunculkan error PHP aslinya ke layar Anda!
                alert(`❌ SERVER ERROR: ${data.message || 'Kesalahan Sistem'}\nFile: ${data.file}\nBaris: ${data.line}`);
                console.error(data);
            }
        })
        .catch(error => {
            alert(`❌ Terjadi kesalahan pengiriman data.`);
            console.error(error);
        })
        .finally(() => {
            btnElement.innerHTML = originalContent;
            btnElement.disabled = false;
        });
    }
</script>
>>>>>>> nazriel
@endsection
