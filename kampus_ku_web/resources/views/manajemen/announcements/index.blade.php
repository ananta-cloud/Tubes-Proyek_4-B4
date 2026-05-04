@extends('layouts.app')

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
@endsection
