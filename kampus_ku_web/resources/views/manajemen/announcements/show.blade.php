@extends('layouts.app')

@section('page_title', 'Detail Pengumuman')

@section('content')
<div class="container mx-auto px-4 py-6 max-w-5xl">

    <div class="mb-6">
        <a href="{{ route('manajemen.dashboard') }}" class="text-indigo-600 hover:text-indigo-800 font-medium flex items-center gap-2 transition">
            <i class="fas fa-arrow-left"></i> Kembali ke Dashboard
        </a>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

        <div class="lg:col-span-2 space-y-6">
            <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div class="p-6 md:p-8">
                    <h1 class="text-3xl font-bold text-gray-900 mb-4">{{ $announcement->judul }}</h1>

                    <div class="flex flex-wrap gap-2 mb-6">
                        @php
                            $kategoriList = is_array($announcement->kategori) ? $announcement->kategori : [];
                            if (is_object($announcement->kategori) && method_exists($announcement->kategori, 'getArrayCopy')) {
                                $kategoriList = $announcement->kategori->getArrayCopy();
                            }
                        @endphp

                        @if(count($kategoriList) > 0)
                            @foreach($kategoriList as $cat)
                                <span class="px-3 py-1 text-xs font-bold bg-indigo-50 text-indigo-700 rounded-full border border-indigo-100">
                                    <i class="fas fa-tag mr-1"></i> {{ $cat }}
                                </span>
                            @endforeach
                        @else
                            <span class="px-3 py-1 text-xs font-medium bg-gray-100 text-gray-500 rounded-full">
                                Tanpa Kategori
                            </span>
                        @endif
                    </div>

                    <div class="prose max-w-none text-gray-700 text-base leading-relaxed whitespace-pre-line mb-8">
                        {{ $announcement->isi }}
                    </div>

                    <hr class="border-gray-100 mb-6">

                    <div>
                        <h3 class="text-sm font-bold text-gray-900 mb-3 uppercase tracking-wider">Lampiran</h3>
                        @if($announcement->lampiran)
                            @php
                                $ext = strtolower(pathinfo($announcement->lampiran, PATHINFO_EXTENSION));
                                $isImage = in_array($ext, ['jpg', 'jpeg', 'png', 'webp']);
                            @endphp

                            @if($isImage)
                                <div class="border border-gray-200 rounded-lg overflow-hidden max-w-sm">
                                    <img src="{{ asset('storage/' . $announcement->lampiran) }}" alt="Lampiran Foto" class="w-full h-auto object-cover">
                                    <div class="p-3 bg-gray-50 flex justify-between items-center border-t border-gray-200">
                                        <span class="text-xs text-gray-500 font-medium">Gambar ({{ strtoupper($ext) }})</span>
                                        <a href="{{ asset('storage/' . $announcement->lampiran) }}" target="_blank" class="text-indigo-600 hover:text-indigo-800 text-xs font-bold">
                                            Buka Penuh <i class="fas fa-external-link-alt ml-1"></i>
                                        </a>
                                    </div>
                                </div>
                            @else
                                <a href="{{ asset('storage/' . $announcement->lampiran) }}" target="_blank" class="inline-flex items-center gap-3 p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition w-full sm:w-auto">
                                    <div class="w-10 h-10 rounded bg-red-100 text-red-600 flex items-center justify-center text-lg">
                                        <i class="fas fa-file-{{ $ext == 'pdf' ? 'pdf' : ($ext == 'xlsx' ? 'excel' : 'alt') }}"></i>
                                    </div>
                                    <div>
                                        <p class="text-sm font-bold text-gray-800">Unduh Dokumen</p>
                                        <p class="text-xs text-gray-500 uppercase">Format: {{ $ext }}</p>
                                    </div>
                                </a>
                            @endif
                        @else
                            <p class="text-sm text-gray-500 italic">Tidak ada lampiran.</p>
                        @endif
                    </div>
                </div>
            </div>
        </div>

        <div class="space-y-6">

            <div class="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
                <h3 class="text-sm font-bold text-gray-900 mb-4 border-b pb-2">Informasi Penerbitan</h3>

                <ul class="space-y-4">
                    <li class="flex items-start gap-3">
                        <i class="fas fa-calendar-alt text-gray-400 mt-1 w-5 text-center"></i>
                        <div>
                            <p class="text-xs text-gray-500">Tanggal Terbit</p>
                            <p class="text-sm font-medium text-gray-900">{{ $announcement->created_at->format('d M Y, H:i') }}</p>
                        </div>
                    </li>
                    <li class="flex items-start gap-3">
                        <i class="fas fa-user-tie text-gray-400 mt-1 w-5 text-center"></i>
                        <div>
                            <p class="text-xs text-gray-500">Diterbitkan Oleh</p>
                            <p class="text-sm font-medium text-gray-900">{{ $announcement->nama_publisher }}</p>
                            <p class="text-[10px] bg-gray-100 text-gray-600 px-2 py-0.5 rounded inline-block mt-1">{{ $announcement->role_publisher }}</p>
                        </div>
                    </li>
                    <li class="flex items-start gap-3">
                        <i class="fas fa-bullseye text-gray-400 mt-1 w-5 text-center"></i>
                        <div>
                            <p class="text-xs text-gray-500">Target Audiens</p>
                            <p class="text-sm font-medium text-gray-900">{{ str_replace('_', ' ', $announcement->target_audience) }}</p>
                        </div>
                    </li>
                    @if(!empty($announcement->target_angkatan))
                    <li class="flex items-start gap-3">
                        <i class="fas fa-users text-gray-400 mt-1 w-5 text-center"></i>
                        <div>
                            <p class="text-xs text-gray-500">Target Angkatan</p>
                            @php
                                $angkatanArr = is_object($announcement->target_angkatan) && method_exists($announcement->target_angkatan, 'getArrayCopy')
                                                ? $announcement->target_angkatan->getArrayCopy()
                                                : (array) $announcement->target_angkatan;
                            @endphp
                            <p class="text-sm font-medium text-gray-900">{{ implode(', ', $angkatanArr) }}</p>
                        </div>
                    </li>
                    @endif
                </ul>
            </div>

            <div class="bg-gradient-to-br from-indigo-600 to-blue-800 p-6 rounded-xl shadow-md text-white">
                <h3 class="text-sm font-semibold text-indigo-200 mb-2">Total Keterbacaan</h3>
                <div class="flex items-end gap-3">
                    @php
                        $readCount = 0;
                        if (is_array($announcement->read_by_users)) {
                            $readCount = count($announcement->read_by_users);
                        } elseif (is_object($announcement->read_by_users) && method_exists($announcement->read_by_users, 'count')) {
                            $readCount = $announcement->read_by_users->count();
                        }
                    @endphp
                    <span class="text-5xl font-bold">{{ $readCount }}</span>
                    <span class="text-indigo-200 mb-1">Mahasiswa</span>
                </div>
            </div>

            <div class="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
                <h3 class="text-sm font-bold text-gray-900 mb-4 border-b pb-2">Broadcast WhatsApp</h3>
                <p class="text-xs text-gray-500 mb-4">Gunakan tombol ini untuk mengirim ulang (push) pengumuman secara langsung ke Grup WhatsApp.</p>

                <div class="space-y-3">
                    <button onclick="broadcastWA('{{ (string) $announcement->_id }}', this)" class="w-full flex items-center justify-center gap-2 bg-green-50 text-green-700 hover:bg-green-100 px-4 py-2.5 rounded-lg font-bold transition shadow-sm">
                        <i class="fab fa-whatsapp text-lg"></i> Kirim ke WhatsApp
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    function broadcastWA(id, btnElement) {
        if(!confirm('Kirim pengumuman ini langsung ke Grup WhatsApp?')) return;

        let originalContent = btnElement.innerHTML;
        btnElement.innerHTML = `<i class="fas fa-spinner fa-spin text-lg"></i> Sedang Mengirim...`;
        btnElement.disabled = true;

        fetch(`/manajemen/announcements/${id}/broadcast`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            }
        })
        .then(response => response.json())
        .then(data => {
            if(data.success) {
                alert(`✅ SUKSES: ${data.message}`);
            } else {
                alert(`❌ GAGAL: ${data.message}`);
            }
        })
        .catch(error => {
            alert(`❌ Terjadi kesalahan jaringan / server tidak merespon.`);
            console.error(error);
        })
        .finally(() => {
            btnElement.innerHTML = originalContent;
            btnElement.disabled = false;
        });
    }
</script>
@endsection
