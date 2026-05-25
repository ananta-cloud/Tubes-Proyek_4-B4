<?php $__env->startSection('page_title', 'Request Perubahan Jadwal'); ?>

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
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-amber-400">
        <p class="text-[11px] text-amber-600 font-bold uppercase tracking-wider mb-2">Menunggu Review</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_pending ?? 0); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Request masuk</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-emerald-500">
        <p class="text-[11px] text-emerald-600 font-bold uppercase tracking-wider mb-2">Disetujui</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_approved ?? 0); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Bulan ini</p>
    </div>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-200 border-l-4 border-l-red-400">
        <p class="text-[11px] text-red-500 font-bold uppercase tracking-wider mb-2">Ditolak</p>
        <h3 class="text-3xl font-black text-slate-800"><?php echo e($count_rejected ?? 0); ?></h3>
        <p class="text-xs text-slate-400 mt-1">Bulan ini</p>
    </div>
</div>



<div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">

    
    <div class="p-5 border-b border-slate-200 bg-slate-50 flex flex-col md:flex-row justify-between items-start md:items-center gap-3">
        <h3 class="font-bold text-slate-800">
            <i class="fas fa-inbox text-indigo-500 mr-2"></i> Daftar Request Perubahan
        </h3>

        
        <div class="flex gap-2 flex-wrap">
            <a href="<?php echo e(route('penjadwalan.requests.index')); ?>"
               class="px-3 py-1.5 rounded-lg text-xs font-bold border transition
                      <?php echo e(!request('status') ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-white text-slate-600 border-slate-300 hover:border-indigo-400'); ?>">
                Semua
            </a>
            <a href="<?php echo e(route('penjadwalan.requests.index', ['status' => 'PENDING'])); ?>"
               class="px-3 py-1.5 rounded-lg text-xs font-bold border transition
                      <?php echo e(request('status') == 'PENDING' ? 'bg-amber-500 text-white border-amber-500' : 'bg-white text-slate-600 border-slate-300 hover:border-amber-400'); ?>">
                Pending
            </a>
            <a href="<?php echo e(route('penjadwalan.requests.index', ['status' => 'APPROVED'])); ?>"
               class="px-3 py-1.5 rounded-lg text-xs font-bold border transition
                      <?php echo e(request('status') == 'APPROVED' ? 'bg-emerald-500 text-white border-emerald-500' : 'bg-white text-slate-600 border-slate-300 hover:border-emerald-400'); ?>">
                Disetujui
            </a>
            <a href="<?php echo e(route('penjadwalan.requests.index', ['status' => 'REJECTED'])); ?>"
               class="px-3 py-1.5 rounded-lg text-xs font-bold border transition
                      <?php echo e(request('status') == 'REJECTED' ? 'bg-red-500 text-white border-red-500' : 'bg-white text-slate-600 border-slate-300 hover:border-red-400'); ?>">
                Ditolak
            </a>
        </div>
    </div>


    
    <div class="overflow-x-auto">
        <table class="w-full text-left text-sm min-w-[800px]">
            <thead class="bg-slate-50 border-b border-slate-200">
                <tr>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/4">Dosen & Mata Kuliah</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/5">Tipe Request</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase w-1/4">Alasan</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Tanggal</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase">Status</th>
                    <th class="px-6 py-4 text-slate-500 font-bold text-xs uppercase text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                <?php $__empty_1 = true; $__currentLoopData = $requests ?? []; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $req): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
                <tr class="hover:bg-slate-50 transition">

                    
                    <td class="px-6 py-4">
                        <p class="font-bold text-slate-800"><?php echo e($req->schedule->nama_mk ?? '-'); ?></p>
                        <p class="text-xs text-slate-500 mt-0.5">
                            <i class="fas fa-user-tie mr-1 text-slate-400"></i><?php echo e($req->dosen->nama ?? '-'); ?>

                        </p>
                    </td>

                    
                    <td class="px-6 py-4">
                        <?php if($req->tipe_request == 'GANTI_RUANGAN'): ?>
                            <span class="bg-blue-50 text-blue-700 px-2.5 py-1 rounded text-[10px] font-bold tracking-wider border border-blue-100">
                                <i class="fas fa-door-open mr-1"></i> Ganti Ruangan
                            </span>
                        <?php elseif($req->tipe_request == 'GANTI_WAKTU'): ?>
                            <span class="bg-purple-50 text-purple-700 px-2.5 py-1 rounded text-[10px] font-bold tracking-wider border border-purple-100">
                                <i class="fas fa-clock mr-1"></i> Ganti Waktu
                            </span>
                        <?php elseif($req->tipe_request == 'GANTI_DOSEN'): ?>
                            <span class="bg-orange-50 text-orange-700 px-2.5 py-1 rounded text-[10px] font-bold tracking-wider border border-orange-100">
                                <i class="fas fa-user-edit mr-1"></i> Ganti Dosen
                            </span>
                        <?php else: ?>
                            <span class="bg-slate-100 text-slate-600 px-2.5 py-1 rounded text-[10px] font-bold tracking-wider border border-slate-200">
                                <?php echo e($req->tipe_request); ?>

                            </span>
                        <?php endif; ?>
                    </td>

                    
                    <td class="px-6 py-4">
                        <p class="text-slate-600 text-xs line-clamp-2 max-w-xs"><?php echo e($req->alasan ?? '-'); ?></p>
                    </td>

                    
                    <td class="px-6 py-4">
                        <p class="text-slate-700 text-xs font-medium">
                            <?php echo e(\Carbon\Carbon::parse($req->created_at)->format('d M Y')); ?>

                        </p>
                        <p class="text-slate-400 text-[10px]">
                            <?php echo e(\Carbon\Carbon::parse($req->created_at)->format('H:i')); ?> WIB
                        </p>
                    </td>

                    
                    <td class="px-6 py-4">
                        <?php if($req->status == 'PENDING'): ?>
                            <span class="bg-amber-100 text-amber-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-amber-200">PENDING</span>
                        <?php elseif($req->status == 'APPROVED'): ?>
                            <span class="bg-emerald-100 text-emerald-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-emerald-200">APPROVED</span>
                        <?php elseif($req->status == 'REJECTED'): ?>
                            <span class="bg-red-100 text-red-600 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-red-200">REJECTED</span>
                        <?php endif; ?>
                    </td>

                    
                    <td class="px-6 py-4 text-right">
                        <?php if($req->status == 'PENDING'): ?>
                            <div class="flex gap-2 justify-end">
                                
                                <a href="<?php echo e(route('penjadwalan.requests.detail', $req->id)); ?>"
                                   class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                    <i class="fas fa-eye mr-1"></i> Detail
                                </a>

                                
                                <form action="<?php echo e(route('penjadwalan.requests.approve', $req->id)); ?>" method="POST">
                                    <?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?>
                                    <button type="submit"
                                            onclick="return confirm('Setujui request perubahan jadwal ini?')"
                                            class="text-emerald-700 hover:text-emerald-900 text-xs font-semibold bg-emerald-50 px-3 py-1.5 rounded border border-emerald-200 transition">
                                        <i class="fas fa-check mr-1"></i> Approve
                                    </button>
                                </form>

                                
                                <button onclick="bukaModalReject('<?php echo e($req->id); ?>')"
                                        class="text-red-600 hover:text-red-800 text-xs font-semibold bg-red-50 px-3 py-1.5 rounded border border-red-200 transition">
                                    <i class="fas fa-times mr-1"></i> Reject
                                </button>
                            </div>
                        <?php else: ?>
                            
                            <a href="<?php echo e(route('penjadwalan.requests.detail', $req->id)); ?>"
                               class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold bg-indigo-50 px-3 py-1.5 rounded border border-indigo-100 transition">
                                <i class="fas fa-eye mr-1"></i> Detail
                            </a>
                        <?php endif; ?>
                    </td>

                </tr>
                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?>
                <tr>
                    <td colspan="6" class="px-6 py-12 text-center">
                        <div class="flex flex-col items-center gap-2 text-slate-400">
                            <i class="fas fa-inbox text-3xl"></i>
                            <p class="text-sm font-medium">Tidak ada request
                                <?php if(request('status')): ?> dengan status <?php echo e(request('status')); ?> <?php endif; ?>
                            </p>
                        </div>
                    </td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    
    <?php if(isset($requests) && $requests->hasPages()): ?>
    <div class="px-6 py-4 border-t border-slate-100 bg-slate-50">
        <?php echo e($requests->appends(request()->query())->links()); ?>

    </div>
    <?php endif; ?>

</div>



<div id="modal-reject" class="fixed inset-0 bg-slate-900/50 hidden z-50 flex items-center justify-center backdrop-blur-sm">
    <div class="bg-white rounded-xl shadow-2xl max-w-md w-full m-4 overflow-hidden">
        <form id="form-reject" method="POST" action="">
            <?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?>
            <div class="p-6">
                <div class="w-12 h-12 rounded-full bg-red-100 text-red-500 flex items-center justify-center text-xl mb-4">
                    <i class="fas fa-times"></i>
                </div>
                <h3 class="text-xl font-bold text-slate-800 mb-2">Tolak Request</h3>
                <p class="text-sm text-slate-600 mb-4">Berikan alasan penolakan agar dosen mengetahui tindakan selanjutnya. <strong>Wajib diisi.</strong></p>

                <textarea name="alasan_penolakan" required rows="3"
                          class="w-full border border-slate-300 rounded-lg p-3 text-sm focus:ring-2 focus:ring-red-400 outline-none mb-4 resize-none"
                          placeholder="Cth: Ruangan yang diminta sudah terpakai di jam tersebut..."></textarea>

                <div class="flex gap-3 justify-end">
                    <button type="button"
                            onclick="document.getElementById('modal-reject').classList.add('hidden')"
                            class="px-4 py-2 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100 transition">
                        Batal
                    </button>
                    <button type="submit"
                            class="bg-red-500 text-white px-4 py-2 rounded-lg text-sm font-bold shadow-md hover:bg-red-600 transition">
                        <i class="fas fa-times mr-1"></i> Konfirmasi Tolak
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
    function bukaModalReject(id) {
        document.getElementById('form-reject').action = '<?php echo e(url("penjadwalan/requests")); ?>/' + id + '/reject';
        document.getElementById('modal-reject').classList.remove('hidden');
    }
</script>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/penjadwalan/requests/index.blade.php ENDPATH**/ ?>