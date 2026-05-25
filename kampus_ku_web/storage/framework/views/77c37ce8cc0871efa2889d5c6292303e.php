

<?php $__env->startSection('page_title', 'Periode Revisi Jadwal'); ?>

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
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-emerald-500">
        <p class="text-[11px] text-emerald-600 font-bold uppercase tracking-wider mb-2">Periode Aktif</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_aktif); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Sedang berjalan</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-indigo-500">
        <p class="text-[11px] text-indigo-600 font-bold uppercase tracking-wider mb-2">Scope Semester</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_semester); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Semua dosen</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-purple-500">
        <p class="text-[11px] text-purple-600 font-bold uppercase tracking-wider mb-2">Scope Matkul</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_matkul); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Per mata kuliah</p>
    </div>
</div>


<div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
    <div class="p-5 border-b border-slate-200 bg-slate-50 flex justify-between items-center">
        <h3 class="font-bold text-slate-800">
            <i class="fas fa-calendar-check text-indigo-500 mr-2"></i> Daftar Periode Revisi
        </h3>
        <button onclick="document.getElementById('modal-create').classList.remove('hidden')"
                class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition">
            <i class="fas fa-plus mr-1"></i> Buat Periode Baru
        </button>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-left text-sm min-w-[800px]">
            <thead class="bg-slate-50 border-b border-slate-200">
                <tr>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/3">Judul & Scope</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Target</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Periode</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Status</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                <?php $__empty_1 = true; $__currentLoopData = $periodes; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $periode): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
                <?php
                    $now      = now();
                    $ongoing  = $periode->is_active
                                && $now->gte($periode->tanggal_mulai)
                                && $now->lte($periode->tanggal_selesai);
                    $belumMulai = $now->lt($periode->tanggal_mulai);
                    $selesai  = $now->gt($periode->tanggal_selesai);
                ?>
                <tr class="hover:bg-slate-50 transition">
                    <td class="px-6 py-4">
                        <p class="font-bold text-slate-800"><?php echo e($periode->judul); ?></p>
                        <span class="mt-1 inline-block text-[10px] font-bold px-2 py-0.5 rounded border
                            <?php echo e($periode->scope == 'SEMESTER'
                                ? 'bg-indigo-50 text-indigo-600 border-indigo-100'
                                : 'bg-purple-50 text-purple-600 border-purple-100'); ?>">
                            <?php echo e($periode->scope); ?>

                        </span>
                    </td>

                    <td class="px-6 py-4">
                        <?php if($periode->scope == 'SEMESTER'): ?>
                            <p class="text-xs text-slate-500 italic">Semua dosen</p>
                        <?php else: ?>
                            <p class="text-xs font-semibold text-slate-700"><?php echo e($periode->nama_jadwal ?? '-'); ?></p>
                            <p class="text-[10px] text-slate-400"><?php echo e($periode->nama_dosen ?? '-'); ?></p>
                        <?php endif; ?>
                    </td>

                    <td class="px-6 py-4">
                        <p class="text-xs font-medium text-slate-700">
                            <?php echo e(\Carbon\Carbon::parse($periode->tanggal_mulai)->format('d M Y')); ?>

                        </p>
                        <p class="text-[10px] text-slate-400">
                            s/d <?php echo e(\Carbon\Carbon::parse($periode->tanggal_selesai)->format('d M Y')); ?>

                        </p>
                    </td>

                    <td class="px-6 py-4">
                        <?php if(!$periode->is_active): ?>
                            <span class="bg-slate-100 text-slate-500 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-slate-200">
                                NONAKTIF
                            </span>
                        <?php elseif($belumMulai): ?>
                            <span class="bg-blue-50 text-blue-600 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-blue-100">
                                BELUM MULAI
                            </span>
                        <?php elseif($ongoing): ?>
                            <span class="bg-emerald-100 text-emerald-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-emerald-200 flex items-center gap-1 w-fit">
                                <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse inline-block"></span>
                                AKTIF
                            </span>
                        <?php else: ?>
                            <span class="bg-red-50 text-red-500 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-red-100">
                                SELESAI
                            </span>
                        <?php endif; ?>
                    </td>

                    <td class="px-6 py-4 text-right">
                        <div class="flex gap-2 justify-end">
                            
                            <form action="<?php echo e(route('penjadwalan.revisi.toggle', $periode->id)); ?>" method="POST">
                                <?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?>
                                <button type="submit"
                                        onclick="return confirm('<?php echo e($periode->is_active ? 'Nonaktifkan' : 'Aktifkan'); ?> periode ini?')"
                                        class="text-xs font-semibold px-3 py-1.5 rounded border transition
                                               <?php echo e($periode->is_active
                                                   ? 'text-amber-600 bg-amber-50 border-amber-200 hover:bg-amber-100'
                                                   : 'text-emerald-600 bg-emerald-50 border-emerald-200 hover:bg-emerald-100'); ?>">
                                    <i class="fas <?php echo e($periode->is_active ? 'fa-pause' : 'fa-play'); ?> mr-1"></i>
                                    <?php echo e($periode->is_active ? 'Nonaktifkan' : 'Aktifkan'); ?>

                                </button>
                            </form>

                            
                            <form action="<?php echo e(route('penjadwalan.revisi.destroy', $periode->id)); ?>" method="POST"
                                  onsubmit="return confirm('Hapus periode revisi ini?')">
                                <?php echo csrf_field(); ?> <?php echo method_field('DELETE'); ?>
                                <button type="submit"
                                        class="text-red-500 hover:text-red-700 text-xs font-semibold bg-red-50 px-3 py-1.5 rounded border border-red-100 transition">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?>
                <tr>
                    <td colspan="5" class="px-6 py-12 text-center">
                        <div class="flex flex-col items-center gap-2 text-slate-400">
                            <i class="fas fa-calendar-times text-3xl"></i>
                            <p class="text-sm font-medium">Belum ada periode revisi dibuat.</p>
                        </div>
                    </td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <?php if($periodes->hasPages()): ?>
    <div class="px-6 py-4 border-t border-slate-100 bg-slate-50">
        <?php echo e($periodes->links()); ?>

    </div>
    <?php endif; ?>
</div>



<div id="modal-create" class="fixed inset-0 bg-slate-900/50 hidden z-50 flex items-center justify-center backdrop-blur-sm">
    <div class="bg-white rounded-xl shadow-2xl max-w-lg w-full m-4 overflow-hidden">
        <form action="<?php echo e(route('penjadwalan.revisi.store')); ?>" method="POST">
            <?php echo csrf_field(); ?>
            <div class="p-6">
                <div class="flex justify-between items-start mb-5">
                    <div>
                        <h3 class="text-lg font-bold text-slate-800">Buat Periode Revisi</h3>
                        <p class="text-xs text-slate-500 mt-0.5">Atur jendela waktu pengajuan revisi jadwal oleh dosen</p>
                    </div>
                    <button type="button"
                            onclick="document.getElementById('modal-create').classList.add('hidden')"
                            class="text-slate-400 hover:text-slate-600 text-lg">
                        <i class="fas fa-times"></i>
                    </button>
                </div>

                <div class="space-y-4">
                    
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-1">Judul Periode <span class="text-red-500">*</span></label>
                        <input type="text" name="judul" required
                               class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition"
                               placeholder="Cth: Revisi Jadwal Semester Genap 2025/2026">
                    </div>

                    
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-1">Scope <span class="text-red-500">*</span></label>
                        <select name="scope" id="select-scope" onchange="toggleJadwalField()"
                                class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                            <option value="SEMESTER">SEMESTER — Berlaku untuk semua dosen</option>
                            <option value="MATKUL">MATKUL — Spesifik satu mata kuliah</option>
                        </select>
                    </div>

                    
                    <div id="field-jadwal" class="hidden">
                        <label class="block text-sm font-semibold text-slate-700 mb-1">Mata Kuliah <span class="text-red-500">*</span></label>
                        <select name="id_jadwal"
                                class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                            <option value="">-- Pilih Mata Kuliah --</option>
                            <?php $__currentLoopData = $schedules; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $jadwal): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <option value="<?php echo e($jadwal->id); ?>">
                                    <?php echo e($jadwal->nama_mk); ?> — <?php echo e($jadwal->nama_dosen); ?>

                                </option>
                            <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                        </select>
                    </div>

                    
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Tanggal Mulai <span class="text-red-500">*</span></label>
                            <input type="date" name="tanggal_mulai" required
                                   min="<?php echo e(now()->format('Y-m-d')); ?>"
                                   class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                        </div>
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Tanggal Selesai <span class="text-red-500">*</span></label>
                            <input type="date" name="tanggal_selesai" required
                                   min="<?php echo e(now()->format('Y-m-d')); ?>"
                                   class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                        </div>
                    </div>

                    
                    <div class="bg-indigo-50 border border-indigo-100 rounded-lg px-4 py-3 flex items-start gap-2">
                        <i class="fas fa-info-circle text-indigo-400 mt-0.5 text-xs"></i>
                        <p class="text-xs text-indigo-700">
                            Dosen akan bisa melihat periode ini di aplikasi mobile.
                            Request yang masuk setelah deadline tetap bisa di-approve/reject secara manual oleh tim penjadwalan.
                        </p>
                    </div>
                </div>

                <div class="flex gap-3 justify-end mt-6">
                    <button type="button"
                            onclick="document.getElementById('modal-create').classList.add('hidden')"
                            class="px-4 py-2 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100 transition border border-slate-200">
                        Batal
                    </button>
                    <button type="submit"
                            class="bg-indigo-600 text-white px-5 py-2 rounded-lg text-sm font-bold shadow-md hover:bg-indigo-700 transition">
                        <i class="fas fa-calendar-plus mr-1"></i> Simpan Periode
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
    function toggleJadwalField() {
        const scope = document.getElementById('select-scope').value;
        const field = document.getElementById('field-jadwal');
        field.classList.toggle('hidden', scope !== 'MATKUL');
    }
</script>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/penjadwalan/revisi/index.blade.php ENDPATH**/ ?>