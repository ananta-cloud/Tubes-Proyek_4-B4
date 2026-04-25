@php $status = $status ?? 'DRAFT'; @endphp

@if($status == 'DRAFT')
    <span class="bg-slate-100 text-slate-600 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-slate-200">DRAFT</span>
@elseif($status == 'FINAL')
    <span class="bg-yellow-100 text-yellow-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-yellow-200">FINAL</span>
@elseif($status == 'PUBLISHED')
    <span class="bg-emerald-100 text-emerald-700 px-3 py-1 rounded text-[10px] font-bold tracking-wider border border-emerald-200">PUBLISHED</span>
@endif