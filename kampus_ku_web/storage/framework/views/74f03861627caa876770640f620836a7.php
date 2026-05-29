<?php $__env->startSection('page_title', 'Dashboard Tim Penjadwalan'); ?>

<?php $__env->startSection('content'); ?>


<?php if(session('success')): ?>
<div class="mb-6 bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
    <i class="fas fa-check-circle text-emerald-500 mt-0.5"></i>
    <p class="text-sm text-emerald-800 font-medium"><?php echo e(session('success')); ?></p>
</div>
<?php endif; ?>

<?php if(session('error')): ?>
<div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
    <i class="fas fa-exclamation-triangle text-red-500 mt-0.5"></i>
    <div>
        <h4 class="font-bold text-sm text-red-800">Collision Detected!</h4>
        <p class="text-xs mt-1 text-red-700"><?php echo e(session('error')); ?></p>
        <?php if(session('conflict_detail')): ?>
            <p class="text-xs mt-1 text-red-600 font-mono bg-red-100 px-2 py-1 rounded inline-block">
                Bentrok dengan: <?php echo e(session('conflict_detail')->nama_mk); ?> — <?php echo e(session('conflict_detail')->ruangan); ?>

                (<?php echo e(session('conflict_detail')->hari); ?>, <?php echo e(session('conflict_detail')->jam_mulai); ?>–<?php echo e(session('conflict_detail')->jam_selesai); ?>)
            </p>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>


<div class="bg-gradient-to-r from-indigo-900 to-indigo-700 rounded-2xl p-6 mb-8 text-white shadow-lg relative overflow-hidden">
    <div class="absolute right-0 top-0 w-64 h-full opacity-10">
        <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" class="w-full h-full">
            <path fill="white" d="M47.7,-57.2C59.5,-46.3,65.5,-29.4,67.3,-12.5C69.1,4.5,66.6,21.4,58.1,34.7C49.5,48,34.9,57.6,18.4,63.1C1.9,68.6,-16.4,70,-32,64.2C-47.5,58.4,-60.3,45.3,-67.4,29.3C-74.4,13.4,-75.6,-5.3,-69.5,-21.2C-63.3,-37,-49.7,-50,-34.9,-60.3C-20,-70.5,-4,-78,10.9,-74.3C25.8,-70.5,35.9,-68.1,47.7,-57.2Z" transform="translate(100 100)" />
        </svg>
    </div>
    <div class="relative z-10">
        <p class="text-indigo-300 text-sm font-medium mb-1">Selamat datang,</p>
        <h2 class="text-2xl font-black mb-1"><?php echo e(auth()->user()->name); ?></h2>
        <p class="text-indigo-300 text-xs">Tim Penjadwalan · Semester Genap 2025/2026</p>
    </div>
    <div class="relative z-10 mt-4 flex gap-3">
        <a href="<?php echo e(route('penjadwalan.schedules.create')); ?>" class="bg-yellow-400 text-indigo-900 px-4 py-2 rounded-lg text-sm font-bold shadow hover:bg-yellow-300 transition flex items-center gap-2">
            <i class="fas fa-plus"></i> Input Jadwal Baru
        </a>
        <a href="<?php echo e(route('penjadwalan.requests.index')); ?>" class="bg-white/10 backdrop-blur text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-white/20 transition flex items-center gap-2 border border-white/20">
            <i class="fas fa-inbox"></i> Kelola Request
            <?php if($pending_requests > 0): ?>
                <span class="bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full"><?php echo e($pending_requests); ?></span>
            <?php endif; ?>
        </a>
    </div>
</div>


<div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-slate-400">
        <p class="text-[11px] text-slate-500 font-bold uppercase tracking-wider mb-2">Total Jadwal</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($total); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Semester ini</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-slate-400">
        <p class="text-[11px] text-slate-500 font-bold uppercase tracking-wider mb-2">Draft</p>
        <h3 class="text-3xl font-black text-slate-700"><?php echo e($count_draft); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Belum difinalisasi</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-yellow-400">
        <p class="text-[11px] text-yellow-600 font-bold uppercase tracking-wider mb-2">Final</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_final); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Tunggu publikasi</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-emerald-500">
        <p class="text-[11px] text-emerald-600 font-bold uppercase tracking-wider mb-2">Published</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_published); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Live di HP mahasiswa</p>
    </div>
</div>


<?php if($total > 0): ?>
<div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5 mb-8">
    <div class="flex justify-between items-center mb-3">
        <h3 class="font-bold text-slate-800 text-sm"><i class="fas fa-chart-bar text-indigo-500 mr-2"></i> Progress Publikasi Jadwal</h3>
        <span class="text-xs text-slate-500"><?php echo e(round(($count_published / $total) * 100)); ?>% Published</span>
    </div>
    <div class="h-3 bg-slate-100 rounded-full overflow-hidden flex gap-0.5">
        <?php if($count_draft > 0): ?>
        <div class="bg-slate-400 h-full rounded-l-full transition-all duration-500" style="width: <?php echo e(($count_draft / $total) * 100); ?>%"></div>
        <?php endif; ?>
        <?php if($count_final > 0): ?>
        <div class="bg-yellow-400 h-full transition-all duration-500" style="width: <?php echo e(($count_final / $total) * 100); ?>%"></div>
        <?php endif; ?>
        <?php if($count_published > 0): ?>
        <div class="bg-emerald-500 h-full rounded-r-full transition-all duration-500" style="width: <?php echo e(($count_published / $total) * 100); ?>%"></div>
        <?php endif; ?>
    </div>
    <div class="flex gap-4 mt-3 text-xs text-slate-500">
        <span class="flex items-center gap-1"><span class="w-2 h-2 bg-slate-400 rounded-full inline-block"></span> Draft</span>
        <span class="flex items-center gap-1"><span class="w-2 h-2 bg-yellow-400 rounded-full inline-block"></span> Final</span>
        <span class="flex items-center gap-1"><span class="w-2 h-2 bg-emerald-500 rounded-full inline-block"></span> Published</span>
    </div>
</div>
<?php endif; ?>


<?php if($pending_requests > 0): ?>
<div class="bg-amber-50 border border-amber-200 rounded-xl p-5 mb-8 shadow-sm">
    <div class="flex justify-between items-center">
        <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center text-amber-600">
                <i class="fas fa-bell"></i>
            </div>
            <div>
                <h4 class="font-bold text-amber-900 text-sm"><?php echo e($pending_requests); ?> Request Perubahan Jadwal Menunggu</h4>
                <p class="text-xs text-amber-700">Dosen telah mengajukan perubahan jadwal yang perlu divalidasi.</p>
            </div>
        </div>
        <a href="<?php echo e(route('penjadwalan.requests.index')); ?>" class="bg-amber-500 text-white px-4 py-2 rounded-lg text-sm font-bold hover:bg-amber-600 transition shadow-sm flex-shrink-0">
            Kelola Sekarang →
        </a>
    </div>
</div>
<?php endif; ?>


<div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
    <div class="p-5 border-b border-slate-200 flex justify-between items-center bg-slate-50">
        <h3 class="font-bold text-slate-800"><i class="fas fa-calendar-week text-indigo-500 mr-2"></i> Jadwal Terbaru</h3>
        <a href="<?php echo e(route('penjadwalan.schedules.index')); ?>" class="text-indigo-600 text-sm font-semibold hover:text-indigo-800">
            Lihat Semua →
        </a>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
            <thead class="bg-slate-50 border-b border-slate-100">
                <tr>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase">Mata Kuliah</th>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase">Waktu & Ruangan</th>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase">Status</th>
                    <th class="px-6 py-3 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                <?php $__empty_1 = true; $__currentLoopData = $schedules->take(5); $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $jadwal): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
                <tr class="hover:bg-slate-50 transition">
                    <td class="px-6 py-4">
                        <p class="font-bold text-slate-800"><?php echo e($jadwal->nama_mk); ?></p>
                        <p class="text-xs text-slate-500"><?php echo e($jadwal->nama_dosen); ?></p>
                    </td>
                    <td class="px-6 py-4">
                        <p class="font-medium text-slate-800"><?php echo e($jadwal->hari); ?>, <?php echo e(\Carbon\Carbon::parse($jadwal->jam_mulai)->format('H:i')); ?>–<?php echo e(\Carbon\Carbon::parse($jadwal->jam_selesai)->format('H:i')); ?></p>
                        <p class="text-xs text-slate-500"><?php echo e($jadwal->ruangan); ?></p>
                    </td>
                    <td class="px-6 py-4">
                        <?php echo $__env->make('penjadwalan.partials.status-badge', ['status' => $jadwal->status], array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?>
                    </td>
                    <td class="px-6 py-4 text-right">
                        <a href="<?php echo e(route('penjadwalan.schedules.edit', $jadwal->id)); ?>" class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100">
                            <i class="fas fa-edit mr-1"></i> Edit
                        </a>
                    </td>
                </tr>
                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?>
                <tr>
                    <td colspan="4" class="px-6 py-8 text-center text-slate-500 text-sm">Belum ada jadwal.</td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/penjadwalan/dashboard.blade.php ENDPATH**/ ?>