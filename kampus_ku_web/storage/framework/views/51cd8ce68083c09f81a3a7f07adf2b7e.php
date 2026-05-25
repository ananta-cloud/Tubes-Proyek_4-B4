<?php $status = $status ?? 'DRAFT'; ?>

<?php if($status == 'DRAFT'): ?>
    <span class="bg-slate-100 text-slate-600 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-slate-200">DRAFT</span>
<?php elseif($status == 'FINAL'): ?>
    <span class="bg-yellow-100 text-yellow-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-yellow-200">FINAL</span>
<?php elseif($status == 'PUBLISHED'): ?>
    <span class="bg-emerald-100 text-emerald-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-emerald-200">PUBLISHED</span>
<?php endif; ?><?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/penjadwalan/partials/status-badge.blade.php ENDPATH**/ ?>