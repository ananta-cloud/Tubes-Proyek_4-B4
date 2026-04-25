<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SIGMA - @yield('page_title', 'Dashboard')</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body class="bg-slate-50 flex h-screen font-sans text-slate-800 overflow-hidden">

    <!-- Sidebar Navigation -->
    <aside class="w-64 bg-indigo-900 text-white flex flex-col shadow-xl z-20">
        <div class="p-6 border-b border-indigo-800 flex items-center gap-3">
            <div class="w-10 h-10 bg-yellow-400 rounded-lg flex items-center justify-center font-bold text-indigo-900 text-xl shadow-inner">
                <i class="fas fa-graduation-cap"></i>
            </div>
            <div>
                <h1 class="font-bold text-lg leading-tight tracking-wider">SIGMA</h1>
                <p class="text-[10px] text-indigo-300 uppercase tracking-widest">
                    @if(auth()->user()->role == 'MANAJEMEN')
                        Portal Universitas
                    @elseif(auth()->user()->role == 'TIM_PENJADWALAN')
                        Tim Penjadwalan
                    @else
                        Portal Jurusan
                    @endif
                </p>
            </div>
        </div>

        <nav class="flex-1 p-4 space-y-1 overflow-y-auto">

            {{-- ======================== --}}
            {{-- MENU TIM PENJADWALAN    --}}
            {{-- ======================== --}}
            @if(auth()->user()->role == 'TIM_PENJADWALAN')

            <p class="text-[10px] text-indigo-400 uppercase tracking-widest font-bold px-3 pt-2 pb-1">Menu Utama</p>

            <a href="{{ route('penjadwalan.dashboard') }}"
               class="w-full flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition
                      {{ request()->routeIs('penjadwalan.dashboard') ? 'bg-indigo-800 text-white' : 'text-indigo-200 hover:bg-indigo-800' }}">
                <i class="fas fa-tachometer-alt w-5 text-center"></i> Dashboard
            </a>

            <a href="{{ route('penjadwalan.schedules.index') }}"
               class="w-full flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition
                      {{ request()->routeIs('penjadwalan.schedules.*') ? 'bg-indigo-800 text-white' : 'text-indigo-200 hover:bg-indigo-800' }}">
                <i class="fas fa-calendar-alt w-5 text-center"></i> Kelola Jadwal
            </a>

            <a href="{{ route('penjadwalan.requests.index') }}"
               class="w-full flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition
                      {{ request()->routeIs('penjadwalan.requests.*') ? 'bg-indigo-800 text-white' : 'text-indigo-200 hover:bg-indigo-800' }}">
                <i class="fas fa-inbox w-5 text-center"></i> Request Perubahan
                @php
                    // Badge jumlah pending request
                    $pendingCount = \App\Models\ScheduleRequests::where('status', 'PENDING')->count();
                @endphp
                @if($pendingCount > 0)
                    <span class="ml-auto bg-red-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
                        {{ $pendingCount }}
                    </span>
                @endif
            </a>

            {{-- ======================== --}}
            {{-- MENU ADMIN TU --}}
            {{-- ======================== --}}
            @elseif(auth()->user()->role != 'MANAJEMEN')

            <a href="{{ url('/jurusan/schedules') }}"
               class="w-full flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition
                      {{ request()->is('jurusan/schedules*') ? 'bg-indigo-800 text-white' : 'text-indigo-200 hover:bg-indigo-800' }}">
                <i class="fas fa-calendar-alt w-5 text-center"></i> Kelola Jadwal
            </a>

            <a href="{{ url('/jurusan/announcements') }}"
               class="w-full flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition
                      {{ request()->is('jurusan/announcements*') ? 'bg-indigo-800 text-white' : 'text-indigo-200 hover:bg-indigo-800' }}">
                <i class="fas fa-bullhorn w-5 text-center"></i> Pengumuman
            </a>

            <a href="{{ url('/jurusan/master-matkul') }}"
               class="w-full flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition
                      {{ request()->is('jurusan/master-matkul*') ? 'bg-indigo-800 text-white' : 'text-indigo-200 hover:bg-indigo-800' }}">
                <i class="fas fa-database w-5 text-center"></i> Master Matkul
            </a>

            {{-- ======================== --}}
            {{-- MENU MANAJEMEN          --}}
            {{-- ======================== --}}
            @else

            <a href="{{ url('/manajemen/announcements') }}"
               class="w-full flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition
                      {{ request()->is('manajemen/announcements*') ? 'bg-indigo-800 text-white' : 'text-indigo-200 hover:bg-indigo-800' }}">
                <i class="fas fa-bullhorn w-5 text-center"></i> Pengumuman
                <span class="ml-auto bg-yellow-400 text-indigo-900 text-[10px] font-bold px-2 py-0.5 rounded-full">Umum</span>
            </a>

            @endif

        </nav>

        <!-- Profil Akun Bawah -->
        <div class="p-4 border-t border-indigo-800">
            <div class="flex items-center gap-3 bg-indigo-950 p-3 rounded-lg border border-indigo-800">
                <img src="https://ui-avatars.com/api/?name={{ urlencode(auth()->user()->nama) }}&background=eab308&color=1e3a8a"
                     class="w-10 h-10 rounded-full border-2 border-yellow-400">
                <div class="overflow-hidden">
                    <p class="text-sm font-bold truncate">{{ auth()->user()->nama }}</p>
                    <p class="text-xs text-indigo-300 truncate">{{ auth()->user()->role }}</p>
                </div>
            </div>
        </div>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col h-full overflow-hidden">
        <!-- Header Atas -->
        <header class="bg-white px-6 py-4 shadow-sm flex flex-col md:flex-row justify-between items-center z-10">
            <div>
                <h2 class="font-bold text-xl text-slate-800">@yield('page_title', 'Dashboard SIGMA')</h2>
                <p class="text-xs text-slate-500 mt-1"><i class="fas fa-clock mr-1"></i> Semester Genap 2025/2026</p>
            </div>

            <div class="flex items-center gap-4 mt-4 md:mt-0">
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg text-sm font-semibold hover:bg-red-100 transition shadow-sm">
                        <i class="fas fa-sign-out-alt mr-1"></i> Logout
                    </button>
                </form>
            </div>
        </header>

        <!-- Dynamic Content -->
        <div class="flex-1 overflow-y-auto p-6 md:p-8 bg-slate-50">
            <div class="max-w-6xl mx-auto w-full">
                @yield('content')
            </div>
        </div>
    </main>

</body>
</html>