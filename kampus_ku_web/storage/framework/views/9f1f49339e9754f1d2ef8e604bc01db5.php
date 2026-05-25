<?php $__env->startSection('page_title', 'Status Tracking Jadwal'); ?>

<?php $__env->startSection('content'); ?>

    
    <?php if(session('error')): ?>
    <div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
        <i class="fas fa-exclamation-triangle text-red-500 mt-0.5"></i>
        <div>
            <h4 class="font-bold text-sm text-red-800">Collision Detected (Bentrok Jadwal!)</h4>
            <p class="text-xs mt-1 text-red-700"><?php echo e(session('error')); ?></p>
            <?php if(session('conflict_detail')): ?>
                <p class="text-xs mt-1 text-red-600 font-mono bg-red-100 px-2 py-1 rounded inline-block">
                    Bentrok dengan: <?php echo e(session('conflict_detail')->nama_mk); ?> (<?php echo e(session('conflict_detail')->ruangan); ?>)
                </p>
            <?php endif; ?>
        </div>
    </div>
    <?php endif; ?>

    <?php if(session('success')): ?>
    <div class="mb-6 bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
        <i class="fas fa-check-circle text-emerald-500 mt-0.5"></i>
        <p class="text-sm text-emerald-800 font-medium"><?php echo e(session('success')); ?></p>
    </div>
    <?php endif; ?>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-slate-400">
            <p class="text-xs text-slate-500 font-bold uppercase tracking-wider mb-1">Draft</p>
            <h3 class="text-3xl font-black text-slate-800">
                <?php echo e($count_draft ?? 0); ?> <span class="text-sm font-medium text-slate-400">Matkul</span>
            </h3>
            <p class="text-xs text-slate-400 mt-1">Belum difinalisasi</p>
        </div>
        <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-emerald-500">
            <p class="text-xs text-emerald-600 font-bold uppercase tracking-wider mb-1">Published</p>
            <h3 class="text-3xl font-black text-slate-800">
                <?php echo e($count_published ?? 0); ?> <span class="text-sm font-medium text-slate-400">Matkul</span>
            </h3>
            <p class="text-xs text-slate-400 mt-1">Live di HP mahasiswa</p>
        </div>
    </div>

    
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="p-5 border-b border-slate-200 flex justify-between items-center bg-slate-50">
            <h3 class="font-bold text-slate-800">
                <i class="fas fa-list text-indigo-500 mr-2"></i> Daftar Jadwal Kuliah
            </h3>

            
            <?php if(auth()->user()->role == 'TIM_PENJADWALAN'): ?>
                <a href="<?php echo e(route('penjadwalan.schedules.create')); ?>"
                   class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition">
                    <i class="fas fa-plus mr-1"></i> Input Jadwal Baru
                </a>
            <?php endif; ?>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm min-w-[800px]">
                <thead class="bg-slate-50 border-b border-slate-200">
                    <tr>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/3">Mata Kuliah & Dosen</th>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/4">Waktu & Ruangan</th>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Status</th>
                        <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <?php $__empty_1 = true; $__currentLoopData = $schedules ?? []; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $jadwal): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
                    <tr class="hover:bg-slate-50 transition">
                        <td class="px-6 py-4">
                            <p class="font-bold text-slate-800"><?php echo e($jadwal->nama_mk); ?></p>
                            <p class="text-xs text-slate-500"><?php echo e($jadwal->nama_dosen); ?></p>
                        </td>
                        <td class="px-6 py-4">
                            <p class="font-medium text-slate-800">
                                <?php echo e($jadwal->hari); ?>, <?php echo e(\Carbon\Carbon::parse($jadwal->jam_mulai)->format('H:i')); ?>–<?php echo e(\Carbon\Carbon::parse($jadwal->jam_selesai)->format('H:i')); ?>

                            </p>
                            <p class="text-xs text-slate-500"><?php echo e($jadwal->ruangan); ?></p>
                        </td>
                        <td class="px-6 py-4">
                            <?php echo $__env->make('penjadwalan.partials.status-badge', ['status' => $jadwal->status], array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?>
                        </td>
                        <td class="px-6 py-4 text-right">

                            <?php if(auth()->user()->role == 'TIM_PENJADWALAN'): ?>
                                
                                <?php if($jadwal->status == 'DRAFT'): ?>
                                    <a href="<?php echo e(route('penjadwalan.schedules.edit', $jadwal->id)); ?>"
                                       class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                        <i class="fas fa-edit mr-1"></i> Edit
                                    </a>
                                <?php elseif($jadwal->status == 'FINAL'): ?>
                                    <span class="text-[10px] text-yellow-600 font-medium italic">Menunggu Admin TU</span>
                                <?php else: ?>
                                    <span class="text-xs text-emerald-600">
                                        <i class="fas fa-check-circle"></i> Live di Mhs
                                    </span>
                                <?php endif; ?>

                            <?php elseif(auth()->user()->role == 'ADMIN_TU'): ?>
                                
                                <?php if($jadwal->status == 'DRAFT'): ?>
                                    <form action="<?php echo e(route('admin.schedules.finalize', $jadwal->id)); ?>" method="POST">
                                        <?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?>
                                        <button type="submit"
                                                onclick="return confirm('Finalisasi jadwal <?php echo e($jadwal->nama_mk); ?>?')"
                                                class="text-indigo-600 hover:text-indigo-800 font-semibold text-xs bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                            <i class="fas fa-check mr-1"></i> Finalisasi
                                        </button>
                                    </form>
                                <?php elseif($jadwal->status == 'FINAL'): ?>
                                    <button onclick="bukaModalPublish('<?php echo e($jadwal->id); ?>')"
                                            class="bg-emerald-500 text-white font-semibold text-xs px-3 py-1.5 rounded shadow-sm hover:bg-emerald-600 transition">
                                        <i class="fas fa-paper-plane mr-1"></i> Publikasi
                                    </button>
                                <?php else: ?>
                                    <span class="text-xs text-emerald-600">
                                        <i class="fas fa-check-circle"></i> Live di Mhs
                                    </span>
                                <?php endif; ?>

                            <?php endif; ?>

                        </td>
                    </tr>
                    <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?>
                    <tr>
                        <td colspan="4" class="px-6 py-8 text-center text-slate-500 text-sm">
                            Belum ada data jadwal perkuliahan.
                        </td>
                    </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    
    <?php if(auth()->user()->role == 'ADMIN_TU'): ?>
    <div id="modal-publish" class="fixed inset-0 bg-slate-900/50 hidden z-50 flex items-center justify-center backdrop-blur-sm">
        <div class="bg-white rounded-xl shadow-2xl max-w-md w-full m-4 overflow-hidden">
            <form id="form-publish" method="POST" action="">
                <?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?>
                <div class="p-6">
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
                        <button type="button"
                                onclick="document.getElementById('modal-publish').classList.add('hidden')"
                                class="px-4 py-2 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100 transition">
                            Batal
                        </button>
                        <button type="submit"
                                class="bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm font-bold shadow-md hover:bg-emerald-700 transition">
                            <i class="fas fa-paper-plane mr-1"></i> Kirim & Publikasi
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <script>
        function bukaModalPublish(id) {
            document.getElementById('form-publish').action = '<?php echo e(url("/jurusan/schedules")); ?>/' + id + '/publish';
            document.getElementById('modal-publish').classList.remove('hidden');
        }
    </script>
    <?php endif; ?>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/penjadwalan/schedules/index.blade.php ENDPATH**/ ?>