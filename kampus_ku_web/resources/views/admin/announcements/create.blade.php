@extends('layouts.app')

@section('page_title', 'Buat Pengumuman Baru')

@section('content')

{{-- Back Button --}}
<div class="mb-6">
    <a href="{{ route('admin.announcements.index') }}"
       class="text-slate-500 hover:text-slate-700 text-sm font-medium flex items-center gap-2 w-fit">
        <i class="fas fa-arrow-left"></i> Kembali ke Daftar Pengumuman
    </a>
</div>

<div class="max-w-2xl">
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="p-5 border-b border-slate-200 bg-slate-50">
            <h3 class="font-bold text-slate-800">
                <i class="fas fa-edit text-indigo-500 mr-2"></i> Form Pengumuman Jurusan
            </h3>
            <p class="text-xs text-slate-500 mt-1">Pengumuman akan dikirim via Push Notification ke mahasiswa sesuai target.</p>
        </div>

        <form action="{{ route('admin.announcements.store') }}" method="POST" class="p-6 space-y-5">
            @csrf

            {{-- Judul --}}
            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">
                    Judul Pengumuman <span class="text-red-500">*</span>
                </label>
                <input type="text" name="judul" required
                       value="{{ old('judul') }}"
                       class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition"
                       placeholder="Cth: Perubahan Jadwal Ujian Basis Data...">
                @error('judul')
                    <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Kategori & Target Prodi --}}
            <div class="grid grid-cols-2 gap-4">
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Kategori</label>
                    <select name="kategori[]" multiple
                            class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                        <option value="AKADEMIK">Akademik</option>
                        <option value="BEASISWA">Beasiswa</option>
                        <option value="LOMBA">Lomba</option>
                        <option value="UKM">UKM</option>
                        <option value="KARIR">Karir</option>
                        <option value="PKM">PKM</option>
                        <option value="WIRAUSAHA">Wirausaha</option>
                        <option value="KONSELING">Konseling</option>
                        <option value="FASILITAS">Fasilitas</option>
                        <option value="LAINNYA">Lainnya</option>
                    </select>
                </div>

                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Target Prodi</label>
                    <select name="id_prodi"
                            class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                        <option value="">-- Seluruh Jurusan --</option>
                        @foreach($prodiList ?? [] as $prodi)
                            <option value="{{ $prodi->id }}" {{ old('id_prodi') == $prodi->id ? 'selected' : '' }}>
                                {{ $prodi->nama_prodi }}
                            </option>
                        @endforeach
                    </select>
                </div>
            </div>

            {{-- Isi Pengumuman --}}
            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">
                    Isi Pengumuman <span class="text-red-500">*</span>
                </label>
                <textarea name="isi" required rows="6"
                          class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition resize-none"
                          placeholder="Tuliskan detail pengumuman di sini...">{{ old('isi') }}</textarea>
                @error('isi')
                    <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Info target otomatis --}}
            <div class="bg-indigo-50 border border-indigo-100 rounded-lg px-4 py-3 flex items-start gap-3">
                <i class="fas fa-info-circle text-indigo-400 mt-0.5"></i>
                <p class="text-xs text-indigo-700">
                    Pengumuman ini akan otomatis ditargetkan ke jurusan Anda
                    (<strong>{{ auth()->user()->id_jurusan }}</strong>).
                    Pilih Prodi spesifik jika ingin mempersempit target.
                </p>
            </div>

            {{-- Actions --}}
            <div class="flex justify-end gap-3 pt-2">
                <a href="{{ route('admin.announcements.index') }}"
                   class="px-5 py-2.5 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100 transition border border-slate-200">
                    Batal
                </a>
                <button type="submit"
                        class="bg-indigo-600 text-white font-bold py-2.5 px-6 rounded-lg text-sm shadow-md hover:bg-indigo-700 transition">
                    <i class="fas fa-paper-plane mr-2"></i> Terbitkan Pengumuman
                </button>
            </div>
        </form>
    </div>
</div>

@endsection