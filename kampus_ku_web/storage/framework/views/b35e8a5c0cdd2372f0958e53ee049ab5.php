<?php $__env->startSection('page_title', 'Input Jadwal Baru'); ?>

<?php $__env->startSection('content'); ?>

<div class="mb-6">
    <a href="<?php echo e(route('penjadwalan.schedules.index')); ?>" class="text-indigo-600 text-sm hover:text-indigo-800 font-semibold">
        <i class="fas fa-arrow-left mr-1"></i> Kembali ke Daftar Jadwal
    </a>
</div>


<?php if(session('error')): ?>
<div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-start gap-3">
    <i class="fas fa-exclamation-triangle text-red-500 mt-0.5 flex-shrink-0 text-lg"></i>
    <div>
        <h4 class="font-bold text-sm text-red-800">⚠ Collision Detected — Jadwal Bentrok!</h4>
        <p class="text-xs mt-1 text-red-700"><?php echo e(session('error')); ?></p>
        <?php if(session('conflict_detail')): ?>
        <div class="mt-2 bg-red-100 border border-red-200 rounded-lg p-3 text-xs text-red-700 font-mono">
            <p><strong>Konflik dengan:</strong> <?php echo e(session('conflict_detail')->nama_mk); ?> (<?php echo e(session('conflict_detail')->kode_mk); ?>)</p>
            <p><strong>Dosen:</strong> <?php echo e(session('conflict_detail')->nama_dosen); ?></p>
            <p><strong>Ruangan:</strong> <?php echo e(session('conflict_detail')->ruangan); ?></p>
            <p><strong>Waktu:</strong> <?php echo e(session('conflict_detail')->hari); ?>, <?php echo e(session('conflict_detail')->jam_mulai); ?>–<?php echo e(session('conflict_detail')->jam_selesai); ?></p>
            <p><strong>Status:</strong> <?php echo e(session('conflict_detail')->status); ?></p>
        </div>
        <?php endif; ?>
        <p class="text-xs text-red-600 mt-2">Silakan ubah waktu, ruangan, atau dosen agar tidak bentrok.</p>
    </div>
</div>
<?php endif; ?>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

    
    <div class="lg:col-span-2">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div class="p-5 border-b border-slate-200 bg-slate-50">
                <h3 class="font-bold text-slate-800"><i class="fas fa-calendar-plus text-indigo-500 mr-2"></i> Detail Jadwal Baru</h3>
                <p class="text-xs text-slate-500 mt-1">Isi semua kolom. Sistem akan otomatis mendeteksi bentrok jadwal saat disimpan.</p>
            </div>

            <form action="<?php echo e(route('penjadwalan.schedules.store')); ?>" method="POST" class="p-6 space-y-5">
                <?php echo csrf_field(); ?>

                
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Mata Kuliah <span class="text-red-500">*</span></label>
                    <select name="id_mk" id="select-matkul" required onchange="isiDataMatkul(this)"
                        class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none <?php $__errorArgs = ['id_mk'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> border-red-400 <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>">
                        <option value="">-- Pilih Mata Kuliah --</option>
                        <?php $__currentLoopData = $masterMatkul; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $mk): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                            <option value="<?php echo e($mk->_id); ?>"
                                data-nama="<?php echo e($mk->nama_mk); ?>"
                                data-kode="<?php echo e($mk->kode_mk); ?>"
                                <?php echo e(old('id_mk') == $mk->_id ? 'selected' : ''); ?>>
                                [<?php echo e($mk->kode_mk); ?>] <?php echo e($mk->nama_mk); ?>

                            </option>
                        <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                    </select>
                    <?php $__errorArgs = ['id_mk'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> <p class="text-xs text-red-500 mt-1"><?php echo e($message); ?></p> <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                </div>

                
                <input type="hidden" name="nama_mk" id="nama_mk" value="<?php echo e(old('nama_mk')); ?>">
                <input type="hidden" name="kode_mk" id="kode_mk" value="<?php echo e(old('kode_mk')); ?>">
                <input type="hidden" name="id_periode" value="2025-GENAP"> 

                
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Tipe Jadwal <span class="text-red-500">*</span></label>
                    <div class="flex gap-3">
                        <?php $__currentLoopData = ['KULIAH' => 'Perkuliahan', 'UTS' => 'Ujian Tengah Semester', 'UAS' => 'Ujian Akhir Semester']; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $value => $label): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                        <label class="flex-1 cursor-pointer">
                            <input type="radio" name="tipe" value="<?php echo e($value); ?>" class="sr-only peer" <?php echo e(old('tipe', 'KULIAH') == $value ? 'checked' : ''); ?>>
                            <div class="border border-slate-200 rounded-lg p-3 text-center text-sm peer-checked:border-indigo-500 peer-checked:bg-indigo-50 peer-checked:text-indigo-700 peer-checked:font-bold transition">
                                <?php echo e($label); ?>

                            </div>
                        </label>
                        <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                    </div>
                    <?php $__errorArgs = ['tipe'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> <p class="text-xs text-red-500 mt-1"><?php echo e($message); ?></p> <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                </div>

                
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Hari <span class="text-red-500">*</span></label>
                    <select name="hari" required class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none <?php $__errorArgs = ['hari'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> border-red-400 <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>">
                        <option value="">-- Pilih Hari --</option>
                        <?php $__currentLoopData = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu']; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $hari): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                            <option value="<?php echo e($hari); ?>" <?php echo e(old('hari') == $hari ? 'selected' : ''); ?>><?php echo e($hari); ?></option>
                        <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                    </select>
                    <?php $__errorArgs = ['hari'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> <p class="text-xs text-red-500 mt-1"><?php echo e($message); ?></p> <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                </div>

                
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Jam Mulai <span class="text-red-500">*</span></label>
                        <input type="time" name="jam_mulai" value="<?php echo e(old('jam_mulai')); ?>" required
                            class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none <?php $__errorArgs = ['jam_mulai'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> border-red-400 <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>">
                        <?php $__errorArgs = ['jam_mulai'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> <p class="text-xs text-red-500 mt-1"><?php echo e($message); ?></p> <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Jam Selesai <span class="text-red-500">*</span></label>
                        <input type="time" name="jam_selesai" value="<?php echo e(old('jam_selesai')); ?>" required
                            class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none <?php $__errorArgs = ['jam_selesai'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> border-red-400 <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>">
                        <?php $__errorArgs = ['jam_selesai'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> <p class="text-xs text-red-500 mt-1"><?php echo e($message); ?></p> <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                    </div>
                </div>

                
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Ruangan <span class="text-red-500">*</span></label>
                    <input type="text" name="ruangan" value="<?php echo e(old('ruangan')); ?>" required
                        placeholder="Cth: GK-301, Lab RPL 2, Aula Lantai 3"
                        class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none <?php $__errorArgs = ['ruangan'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> border-red-400 <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>">
                    <?php $__errorArgs = ['ruangan'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> <p class="text-xs text-red-500 mt-1"><?php echo e($message); ?></p> <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                </div>

                
                <div>
                    <label class="block text-xs font-bold text-slate-600 uppercase tracking-wider mb-1.5">Nama Dosen <span class="text-red-500">*</span></label>
                    <input type="text" name="nama_dosen" value="<?php echo e(old('nama_dosen')); ?>" required
                        placeholder="Nama lengkap dosen pengampu"
                        class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none <?php $__errorArgs = ['nama_dosen'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> border-red-400 <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>">
                    <?php $__errorArgs = ['nama_dosen'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> <p class="text-xs text-red-500 mt-1"><?php echo e($message); ?></p> <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                </div>

                
                <div class="pt-2 flex gap-3">
                    <button type="submit" class="flex-1 bg-indigo-600 text-white py-3 rounded-lg text-sm font-bold hover:bg-indigo-700 shadow-md transition flex items-center justify-center gap-2">
                        <i class="fas fa-save"></i> Simpan Jadwal (Cek Collision)
                    </button>
                    <a href="<?php echo e(route('penjadwalan.schedules.index')); ?>"
                        class="px-6 py-3 rounded-lg text-sm font-semibold text-slate-600 hover:bg-slate-100 border border-slate-200 transition">
                        Batal
                    </a>
                </div>
            </form>
        </div>
    </div>

    
    <div class="space-y-4">

        
        <div class="bg-indigo-50 border border-indigo-200 rounded-xl p-5">
            <div class="flex items-center gap-2 mb-3">
                <i class="fas fa-shield-alt text-indigo-600"></i>
                <h4 class="font-bold text-indigo-800 text-sm">Collision Detection Aktif</h4>
            </div>
            <p class="text-xs text-indigo-700 leading-relaxed">Sistem akan otomatis memeriksa bentrok saat kamu klik <strong>Simpan</strong>. Bentrok dicek berdasarkan:</p>
            <ul class="mt-2 space-y-1 text-xs text-indigo-700">
                <li class="flex items-start gap-2"><i class="fas fa-check text-indigo-500 mt-0.5 text-[10px]"></i> Ruangan yang sama di waktu yang sama</li>
                <li class="flex items-start gap-2"><i class="fas fa-check text-indigo-500 mt-0.5 text-[10px]"></i> Dosen yang sama di waktu yang sama</li>
                <li class="flex items-start gap-2"><i class="fas fa-check text-indigo-500 mt-0.5 text-[10px]"></i> Mata kuliah ganda di waktu yang sama</li>
            </ul>
        </div>

        
        <div class="bg-white border border-slate-200 rounded-xl p-5 shadow-sm">
            <h4 class="font-bold text-slate-700 text-sm mb-3"><i class="fas fa-info-circle text-slate-400 mr-1"></i> Alur Status Jadwal</h4>
            <div class="space-y-3">
                <div class="flex items-center gap-3">
                    <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded text-[10px] font-bold border border-slate-200 w-20 text-center">DRAFT</span>
                    <span class="text-xs text-slate-500">Baru disimpan, bisa diedit</span>
                </div>
                <div class="flex items-center gap-2 text-slate-300 text-xs pl-2"><i class="fas fa-arrow-down"></i> Finalisasi oleh Tim</div>
                <div class="flex items-center gap-3">
                    <span class="bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded text-[10px] font-bold border border-yellow-200 w-20 text-center">FINAL</span>
                    <span class="text-xs text-slate-500">Menunggu persetujuan Kajur</span>
                </div>
                <div class="flex items-center gap-2 text-slate-300 text-xs pl-2"><i class="fas fa-arrow-down"></i> Dipublikasi oleh Kajur</div>
                <div class="flex items-center gap-3">
                    <span class="bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded text-[10px] font-bold border border-emerald-200 w-20 text-center">PUBLISHED</span>
                    <span class="text-xs text-slate-500">Live di HP mahasiswa</span>
                </div>
            </div>
        </div>

    </div>
</div>

<script>
    function isiDataMatkul(select) {
        const option = select.options[select.selectedIndex];
        document.getElementById('nama_mk').value = option.dataset.nama || '';
        document.getElementById('kode_mk').value = option.dataset.kode || '';
    }

    // Restore selection on validation error
    window.addEventListener('DOMContentLoaded', function() {
        const select = document.getElementById('select-matkul');
        if (select.value) isiDataMatkul(select);
    });
</script>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/penjadwalan/schedules/create.blade.php ENDPATH**/ ?>