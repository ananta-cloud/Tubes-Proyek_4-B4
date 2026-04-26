@extends('layouts.app')

@section('content')
<div class="max-w-3xl mx-auto bg-white p-8 rounded-xl shadow-lg">
    <h2 class="text-xl font-bold mb-6 border-b pb-2">Edit Pengumuman</h2>

    @if ($errors->any())
        <div class="mb-6 p-4 bg-red-50 border-l-4 border-red-500 text-red-700 rounded-r-lg shadow-sm">
            <ul class="list-disc pl-5 text-sm space-y-1">
                @foreach ($errors->all() as $error) <li>{{ $error }}</li> @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ route('manajemen.announcements.update', (string) $announcement->_id) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700">Judul Pengumuman</label>
                <input type="text" name="judul" value="{{ old('judul', $announcement->judul) }}" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>
            </div>

            <div class="grid grid-cols-2 gap-4">
                <div>
                    <label class="block text-sm font-medium text-gray-700">Target Penerima</label>
                    <select name="target_penerima" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
                        <option value="KEDUANYA" {{ old('target_penerima', $targetPenerimaForm) == 'KEDUANYA' ? 'selected' : '' }}>Mahasiswa & Dosen</option>
                        <option value="MAHASISWA" {{ old('target_penerima', $targetPenerimaForm) == 'MAHASISWA' ? 'selected' : '' }}>Hanya Mahasiswa</option>
                        <option value="DOSEN" {{ old('target_penerima', $targetPenerimaForm) == 'DOSEN' ? 'selected' : '' }}>Hanya Dosen</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700">Target Angkatan (Opsional)</label>
                    <input type="text" name="target_angkatan" value="{{ old('target_angkatan', $angkatanStr) }}" placeholder="Contoh: 2022, 2023" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
                </div>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700">Kategori (Wajib pilih minimal satu)</label>
                <div class="mt-2 flex flex-wrap gap-3">
                    @php $selectedCats = old('kategori', $kategoriArr); @endphp
                    @foreach(['AKADEMIK', 'BEASISWA', 'LOMBA', 'UKM', 'KARIR', 'PKM', 'WIRAUSAHA', 'KONSELING', 'FASILITAS', 'LAINNYA'] as $cat)
                    <label class="inline-flex items-center">
                        <input type="checkbox" name="kategori[]" value="{{ $cat }}"
                            {{ in_array($cat, $selectedCats) ? 'checked' : '' }}
                            class="rounded text-indigo-600 focus:ring-indigo-500">
                        <span class="ml-2 text-sm text-gray-600">{{ $cat }}</span>
                    </label>
                    @endforeach
                </div>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700">Isi Pengumuman</label>
                <textarea name="isi" rows="6" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>{{ old('isi', $announcement->isi) }}</textarea>
            </div>

            <div class="pt-4 flex justify-end gap-3">
                <a href="{{ route('manajemen.dashboard') }}" class="text-gray-700 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-lg font-medium transition duration-150">Batal</a>
                <button type="submit" class="bg-amber-500 text-white px-6 py-2 rounded-lg font-bold shadow-md hover:bg-amber-600 transition duration-150">
                    Simpan Perubahan
                </button>
            </div>
        </div>
    </form>
</div>
@endsection
