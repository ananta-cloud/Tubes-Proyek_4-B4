<?php $__env->startSection('page_title', 'Manajemen Pengumuman'); ?>

<?php $__env->startSection('content'); ?>
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

    <!-- Kolom Kiri: Form Buat Pengumuman -->
    <div class="lg:col-span-2 bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 class="font-bold text-slate-800 mb-4 border-b pb-2"><i class="fas fa-edit text-indigo-500 mr-2"></i> Buat Pengumuman Baru</h3>

        <form action="<?php echo e(auth()->user()->role == 'MANAJEMEN' ? url('/manajemen/announcements') : url('/jurusan/announcements')); ?>" method="POST" class="space-y-4">
            <?php echo csrf_field(); ?>
            <div>
                <label class="block text-sm font-semibold text-slate-700 mb-1">Judul Pengumuman</label>
                <input type="text" name="judul" required class="w-full border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="Cth: Jadwal Ujian Tengah Semester...">
            </div>

            <div class="grid grid-cols-2 gap-4">
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Kategori</label>
                    <select name="kategori" class="w-full border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                        <option value="Akademik">Akademik</option>
                        <option value="Beasiswa">Beasiswa</option>
                        <option value="Kemahasiswaan">Kemahasiswaan</option>
                    </select>
                </div>

                <!-- Input Targeting (Should Have - DOCX) -->
                <?php if(auth()->user()->role != 'MANAJEMEN'): ?>
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Target Spesifik Prodi</label>
                    <select name="id_prodi" class="w-full border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                        <option value="">-- Seluruh Jurusan --</option>
                        <?php $__currentLoopData = $prodiList ?? []; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $prodi): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                            <option value="<?php echo e($prodi->id); ?>"><?php echo e($prodi->nama_prodi); ?></option>
                        <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                    </select>
                </div>
                <?php else: ?>
                <!-- Jika Manajemen Kampus, otomatis broadcast ke seluruh kampus -->
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">Targeting (Manajemen)</label>
                    <input type="text" disabled value="Tag UMUM (Broadcast ke Semua Mahasiswa)" class="w-full border border-slate-200 bg-slate-50 text-slate-500 rounded-lg px-4 py-2 text-sm">
                </div>
                <?php endif; ?>
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
                <?php $__empty_1 = true; $__currentLoopData = $announcements ?? []; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $ann): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
                <?php
                    $total_baca = is_array($ann->read_by_users) ? count($ann->read_by_users) : 0;
                    // Simulasi perhitungan persentase
                    $persentase = $total_baca > 0 ? min(100, ($total_baca / 200) * 100) : 0;
                ?>
                <div>
                    <div class="flex justify-between text-xs font-semibold mb-1">
                        <span class="truncate w-32" title="<?php echo e($ann->judul); ?>"><?php echo e($ann->judul); ?></span>
                        <span class="text-indigo-600"><?php echo e(round($persentase)); ?>% (<?php echo e($total_baca); ?> dibaca)</span>
                    </div>
                    <div class="w-full bg-slate-100 rounded-full h-1.5">
                        <div class="bg-indigo-500 h-1.5 rounded-full" style="width: <?php echo e($persentase); ?>%"></div>
                    </div>
                </div>
                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?>
                <p class="text-xs text-slate-500">Belum ada pengumuman diterbitkan.</p>
                <?php endif; ?>
            </div>
        </div>

        <!-- Cross-posting Helper (Khusus Manajemen Kampus - Could Have) -->
        <?php if(auth()->user()->role == 'MANAJEMEN'): ?>
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
        <?php endif; ?>

    </div>
</div>
<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/manajemen/pengumuman/index.blade.php ENDPATH**/ ?>