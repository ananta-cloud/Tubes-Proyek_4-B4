

<?php $__env->startSection('page_title', 'Buat Pengumuman Baru'); ?>

<?php $__env->startSection('content'); ?>


<div class="mb-6">
    <a href="<?php echo e(route('admin.announcements.index')); ?>"
       class="text-slate-500 hover:text-slate-700 text-sm font-medium flex items-center gap-2 w-fit">
        <i class="fas fa-arrow-left"></i> Kembali ke Daftar Pengumuman
    </a>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

    
    <div class="lg:col-span-2">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div class="p-5 border-b border-slate-200 bg-slate-50">
                <h3 class="font-bold text-slate-800">
                    <i class="fas fa-edit text-indigo-500 mr-2"></i> Form Pengumuman Jurusan
                </h3>
                <p class="text-xs text-slate-500 mt-1">Pengumuman akan dikirim via Push Notification ke mahasiswa sesuai target.</p>
            </div>

            <form action="<?php echo e(route('admin.announcements.store')); ?>" method="POST"
                  enctype="multipart/form-data" class="p-6 space-y-5" id="form-pengumuman">
                <?php echo csrf_field(); ?>

                
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">
                        Judul Pengumuman <span class="text-red-500">*</span>
                    </label>
                    <input type="text" name="judul" required
                           value="<?php echo e(old('judul')); ?>"
                           id="input-judul"
                           class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition"
                           placeholder="Cth: Perubahan Jadwal Ujian Basis Data...">
                    <?php $__errorArgs = ['judul'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                        <p class="text-red-500 text-xs mt-1"><?php echo e($message); ?></p>
                    <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                </div>

                
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-1">Kategori</label>
                        <select name="kategori"
                                class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                            <option value="">-- Pilih Kategori --</option>
                            <?php $__currentLoopData = \App\Models\Announcement::KATEGORI; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $kat): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <option value="<?php echo e($kat); ?>" <?php echo e(old('kategori') == $kat ? 'selected' : ''); ?>>
                                    <?php echo e(ucfirst(strtolower($kat))); ?>

                                </option>
                            <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-1">Target Prodi</label>
                        <select name="id_prodi"
                                class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition">
                            <option value="">-- Seluruh Jurusan --</option>
                            <?php $__currentLoopData = $prodiList ?? []; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $prodi): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <option value="<?php echo e($prodi->_id); ?>" <?php echo e(old('id_prodi') == $prodi->_id ? 'selected' : ''); ?>>
                                    <?php echo e($prodi->nama_prodi); ?>

                                </option>
                            <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                        </select>
                    </div>
                </div>

                
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-1">
                        Isi Pengumuman <span class="text-red-500">*</span>
                    </label>
                    <textarea name="isi" required rows="6" id="input-isi"
                              class="w-full border border-slate-300 rounded-lg px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition resize-none"
                              placeholder="Tuliskan detail pengumuman di sini..."><?php echo e(old('isi')); ?></textarea>
                    <?php $__errorArgs = ['isi'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                        <p class="text-red-500 text-xs mt-1"><?php echo e($message); ?></p>
                    <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                </div>

                
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">
                        Lampiran <span class="text-slate-400 font-normal">(opsional)</span>
                    </label>

                    
                    <div id="drop-zone"
                         class="border-2 border-dashed border-slate-300 rounded-lg p-6 text-center cursor-pointer hover:border-indigo-400 hover:bg-indigo-50 transition"
                         onclick="document.getElementById('input-lampiran').click()">
                        <i class="fas fa-cloud-upload-alt text-2xl text-slate-400 mb-2"></i>
                        <p class="text-sm text-slate-500 font-medium">Klik atau drag & drop file di sini</p>
                        <p class="text-xs text-slate-400 mt-1">Foto, PDF, Excel, Word — maks. 10MB per file</p>
                        <input type="file" name="lampiran[]" id="input-lampiran"
                               multiple class="hidden"
                               accept=".jpg,.jpeg,.png,.gif,.pdf,.xlsx,.xls,.doc,.docx,.ppt,.pptx">
                    </div>

                    
                    <div id="preview-list" class="mt-3 space-y-2 hidden"></div>
                </div>

                
                <div class="bg-indigo-50 border border-indigo-100 rounded-lg px-4 py-3 flex items-start gap-3">
                    <i class="fas fa-info-circle text-indigo-400 mt-0.5"></i>
                    <p class="text-xs text-indigo-700">
                        Pengumuman ini akan otomatis ditargetkan ke jurusan Anda.
                        Pilih Prodi spesifik jika ingin mempersempit target.
                    </p>
                </div>

                
                <div class="flex justify-end gap-3 pt-2">
                    <a href="<?php echo e(route('admin.announcements.index')); ?>"
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

    
    <div class="space-y-4">

        
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div class="p-4 border-b border-slate-200 bg-slate-50">
                <h4 class="font-bold text-slate-800 text-sm">
                    <i class="fas fa-eye text-indigo-500 mr-2"></i> Preview
                </h4>
                <p class="text-[10px] text-slate-400 mt-0.5">Tampilan di aplikasi mobile</p>
            </div>

            <div class="p-4">
                <div class="bg-slate-100 rounded-xl p-4 border border-slate-200">
                    
                    <div class="flex items-center gap-2 mb-3">
                        <div class="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center">
                            <i class="fas fa-graduation-cap text-white text-xs"></i>
                        </div>
                        <div>
                            <p class="text-[10px] font-bold text-slate-800">SIGMA</p>
                            <p class="text-[9px] text-slate-400">Pengumuman · Baru saja</p>
                        </div>
                    </div>

                    
                    <div class="bg-white rounded-lg p-3 shadow-sm">
                        <p id="preview-judul"
                           class="font-bold text-xs mb-1 text-slate-400 italic">
                            Judul pengumuman...
                        </p>
                        <p id="preview-isi"
                           class="text-[10px] text-slate-500 leading-relaxed line-clamp-4">
                            Isi pengumuman akan tampil di sini...
                        </p>

                        
                        <div id="preview-lampiran-badge" class="hidden mt-2">
                            <span class="bg-indigo-50 text-indigo-600 text-[9px] font-bold px-2 py-0.5 rounded border border-indigo-100">
                                <i class="fas fa-paperclip mr-1"></i>
                                <span id="preview-lampiran-count">0</span> Lampiran
                            </span>
                        </div>
                        
                    </div>
                </div>
            </div>
        </div>

        
        <div class="bg-amber-50 rounded-xl border border-amber-200 p-4">
            <h4 class="font-bold text-amber-800 text-sm mb-2">
                <i class="fas fa-lightbulb text-amber-500 mr-1"></i> Tips
            </h4>
            <ul class="text-xs text-amber-700 space-y-1.5">
                <li class="flex items-start gap-1.5">
                    <i class="fas fa-check text-amber-500 mt-0.5 text-[10px]"></i>
                    Judul singkat dan jelas agar mudah dibaca di notifikasi HP
                </li>
                <li class="flex items-start gap-1.5">
                    <i class="fas fa-check text-amber-500 mt-0.5 text-[10px]"></i>
                    Lampiran maks. 10MB per file
                </li>
                <li class="flex items-start gap-1.5">
                    <i class="fas fa-check text-amber-500 mt-0.5 text-[10px]"></i>
                    Pilih target prodi jika pengumuman tidak untuk semua mahasiswa
                </li>
            </ul>
        </div>

    </div>
</div>

<script>
    // Live preview judul
    document.getElementById('input-judul').addEventListener('input', function () {
        const el = document.getElementById('preview-judul');
        if (this.value) {
            el.textContent = this.value;
            el.classList.remove('text-slate-400', 'italic');
            el.classList.add('text-slate-800');
        } else {
            el.textContent = 'Judul pengumuman...';
            el.classList.add('text-slate-400', 'italic');
            el.classList.remove('text-slate-800');
        }
    });

    // Live preview isi
    document.getElementById('input-isi').addEventListener('input', function () {
        const el = document.getElementById('preview-isi');
        el.textContent = this.value || 'Isi pengumuman akan tampil di sini...';
    });

    // File upload
    const inputFile   = document.getElementById('input-lampiran');
    const previewList = document.getElementById('preview-list');
    const dropZone    = document.getElementById('drop-zone');
    const badge       = document.getElementById('preview-lampiran-badge');
    const badgeCount  = document.getElementById('preview-lampiran-count');
    let fileList      = new DataTransfer();

    function getFileIcon(type) {
        if (type.startsWith('image/'))                              return { icon: 'fa-file-image',  color: 'text-blue-500'    };
        if (type === 'application/pdf')                             return { icon: 'fa-file-pdf',    color: 'text-red-500'     };
        if (type.includes('spreadsheet') || type.includes('excel'))return { icon: 'fa-file-excel',  color: 'text-emerald-500' };
        if (type.includes('word'))                                  return { icon: 'fa-file-word',   color: 'text-blue-700'    };
        if (type.includes('presentation'))                         return { icon: 'fa-file-powerpoint', color: 'text-orange-500' };
        return { icon: 'fa-file-alt', color: 'text-slate-500' };
    }

    function formatSize(bytes) {
        if (bytes < 1024)    return bytes + ' B';
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / 1048576).toFixed(1) + ' MB';
    }

    function renderPreviews() {
        const files = fileList.files;
        previewList.innerHTML = '';

        if (files.length === 0) {
            previewList.classList.add('hidden');
            badge.classList.add('hidden');
            return;
        }

        previewList.classList.remove('hidden');
        badge.classList.remove('hidden');
        badgeCount.textContent = files.length;

        Array.from(files).forEach((file, i) => {
            const { icon, color } = getFileIcon(file.type);
            const isImage = file.type.startsWith('image/');
            const div = document.createElement('div');
            div.className = 'flex items-center gap-3 bg-slate-50 border border-slate-200 rounded-lg p-3';
            div.innerHTML = `
                ${isImage
                    ? `<img src="${URL.createObjectURL(file)}"
                            class="w-10 h-10 rounded object-cover border border-slate-200 flex-shrink-0">`
                    : `<div class="w-10 h-10 rounded bg-white border border-slate-200 flex items-center justify-center flex-shrink-0">
                           <i class="fas ${icon} ${color} text-lg"></i>
                       </div>`
                }
                <div class="flex-1 min-w-0">
                    <p class="text-xs font-semibold text-slate-700 truncate">${file.name}</p>
                    <p class="text-[10px] text-slate-400">${formatSize(file.size)}</p>
                </div>
                <button type="button" onclick="removeFile(${i})"
                        class="text-slate-400 hover:text-red-500 transition flex-shrink-0 text-sm">
                    <i class="fas fa-times"></i>
                </button>
            `;
            previewList.appendChild(div);
        });
    }

    window.removeFile = function (index) {
        const dt = new DataTransfer();
        Array.from(fileList.files).forEach((f, i) => { if (i !== index) dt.items.add(f); });
        fileList = dt;
        inputFile.files = fileList.files;
        renderPreviews();
    };

    inputFile.addEventListener('change', function () {
        Array.from(this.files).forEach(f => fileList.items.add(f));
        inputFile.files = fileList.files;
        renderPreviews();
    });

    // Drag & drop
    dropZone.addEventListener('dragover',  e => { e.preventDefault(); dropZone.classList.add('border-indigo-400', 'bg-indigo-50'); });
    dropZone.addEventListener('dragleave', () => dropZone.classList.remove('border-indigo-400', 'bg-indigo-50'));
    dropZone.addEventListener('drop', e => {
        e.preventDefault();
        dropZone.classList.remove('border-indigo-400', 'bg-indigo-50');
        Array.from(e.dataTransfer.files).forEach(f => fileList.items.add(f));
        inputFile.files = fileList.files;
        renderPreviews();
    });
</script>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/admin/announcements/create.blade.php ENDPATH**/ ?>