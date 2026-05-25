<?php $__env->startSection('page_title', 'Manajemen Pengumuman'); ?>

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
    <p class="text-sm text-red-800 font-medium"><?php echo e(session('error')); ?></p>
</div>
<?php endif; ?>


<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-indigo-500">
        <p class="text-[11px] text-indigo-600 font-bold uppercase tracking-wider mb-2">Total Pengumuman</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($total ?? 0); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Semua pengumuman</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-emerald-500">
        <p class="text-[11px] text-emerald-600 font-bold uppercase tracking-wider mb-2">Bulan Ini</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($total_bulan_ini ?? 0); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Pengumuman diterbitkan</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-amber-400">
        <p class="text-[11px] text-amber-600 font-bold uppercase tracking-wider mb-2">Total Dibaca</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($total_dibaca ?? 0); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Konfirmasi baca mahasiswa</p>
    </div>
</div>


<div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
    <div class="p-5 border-b border-slate-200 flex justify-between items-center bg-slate-50">
        <h3 class="font-bold text-slate-800">
            <i class="fas fa-bullhorn text-indigo-500 mr-2"></i> Daftar Pengumuman
        </h3>
        <a href="<?php echo e(route('admin.announcements.create')); ?>"
           class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition">
            <i class="fas fa-plus mr-1"></i> Buat Pengumuman
        </a>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-left text-sm min-w-[700px]">
            <thead class="bg-slate-50 border-b border-slate-200">
                <tr>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-2/5">Judul & Kategori</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Target</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Dibaca</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Tanggal</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                <?php $__empty_1 = true; $__currentLoopData = $announcements ?? []; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $ann): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
                <?php
                    $total_baca = is_array($ann->read_by_users) ? count($ann->read_by_users) : 0;
                ?>
                <tr class="hover:bg-slate-50 transition">
                    <td class="px-6 py-4">
                        <p class="font-bold text-slate-800"><?php echo e($ann->judul); ?></p>
                        <span class="bg-indigo-50 text-indigo-600 text-[10px] font-bold px-2 py-0.5 rounded border border-indigo-100 mt-1 inline-block">
                            <?php echo e($ann->kategori ?? 'Umum'); ?>

                        </span>
                    </td>
                    <td class="px-6 py-4">
                        <?php if($ann->id_prodi): ?>
                            <span class="text-xs text-slate-600 font-medium">Prodi Tertentu</span>
                        <?php else: ?>
                            <span class="text-xs text-slate-400 italic">Seluruh Jurusan</span>
                        <?php endif; ?>
                    </td>
                    <td class="px-6 py-4">
                        <span class="text-sm font-bold text-slate-700"><?php echo e($total_baca); ?></span>
                        <span class="text-xs text-slate-400 ml-1">mahasiswa</span>
                    </td>
                    <td class="px-6 py-4">
                        <p class="text-xs font-medium text-slate-700">
                            <?php echo e(\Carbon\Carbon::parse($ann->created_at)->format('d M Y')); ?>

                        </p>
                        <p class="text-[10px] text-slate-400">
                            <?php echo e(\Carbon\Carbon::parse($ann->created_at)->format('H:i')); ?> WIB
                        </p>
                    </td>
                    <td class="px-6 py-4 text-right">
                        <form action="<?php echo e(route('admin.announcements.destroy', $ann->id)); ?>" method="POST"
                              onsubmit="return confirm('Hapus pengumuman ini?')">
                            <?php echo csrf_field(); ?> <?php echo method_field('DELETE'); ?>
                            <button type="submit"
                                    class="text-red-500 hover:text-red-700 text-xs font-semibold bg-red-50 px-3 py-1.5 rounded border border-red-100 transition">
                                <i class="fas fa-trash mr-1"></i> Hapus
                            </button>
                        </form>
                    </td>
                </tr>
                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?>
                <tr>
                    <td colspan="5" class="px-6 py-12 text-center">
                        <div class="flex flex-col items-center gap-2 text-slate-400">
                            <i class="fas fa-bullhorn text-3xl"></i>
                            <p class="text-sm font-medium">Belum ada pengumuman diterbitkan.</p>
                            <a href="<?php echo e(route('admin.announcements.create')); ?>"
                               class="text-indigo-600 text-xs font-semibold hover:underline mt-1">
                                Buat pengumuman pertama →
                            </a>
                        </div>
                    </td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    
    <?php if(isset($announcements) && $announcements->hasPages()): ?>
    <div class="px-6 py-4 border-t border-slate-100 bg-slate-50">
        <?php echo e($announcements->links()); ?>

    </div>
    <?php endif; ?>
</div>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/admin/pengumuman/index.blade.php ENDPATH**/ ?>