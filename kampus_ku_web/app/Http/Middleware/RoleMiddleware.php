<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle incoming request berdasarkan Role (RBAC)
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        // 1. Pastikan user sudah login
        if (!Auth::check()) {
            return redirect('/');
        }

        // 2. Ambil data user yang sedang login
        $user = Auth::user();

        // 3. Cek apakah role user tersebut ada di dalam daftar role yang diizinkan di routes
        if (in_array($user->role, $roles)) {
            return $next($request);
        }

        // 4. Jika role tidak sesuai, tolak aksesnya
        abort(403, 'Akses Ditolak. Anda tidak memiliki kewenangan untuk mengakses halaman ini.');
    }
}
