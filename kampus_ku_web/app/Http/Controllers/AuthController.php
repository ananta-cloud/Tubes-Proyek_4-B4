<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * =========================================================
     * WEB AUTHENTICATION (Kajur, Admin TU, Manajemen Kampus)
     * Menggunakan Session Laravel standar
     * =========================================================
     */

    // Menampilkan halaman form login web
    public function showLogin()
    {
        // Pastikan Anda memiliki view resources/views/auth/login.blade.php
        return view('auth.login');
    }

    // Memproses login dari web admin
    public function processLogin(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();
            $user = Auth::user();

            // Pengecekan RBAC: Arahkan ke dashboard sesuai role
            if ($user->role === 'MANAJEMEN') {
                return redirect('/manajemen/announcements');
            } elseif (in_array($user->role, ['KAJUR', 'ADMIN_TU'])) {
                return redirect('/jurusan/schedules');
            }

            // Mencegah mahasiswa login melalui portal web admin
            Auth::logout();
            return back()->withErrors([
                'email' => 'Akses ditolak. Portal Web ini hanya untuk Admin/Kajur. Mahasiswa harap menggunakan Aplikasi Mobile SIGMA.',
            ]);
        }

        return back()->withErrors([
            'email' => 'Kredensial salah. Pastikan email dan password Anda benar.',
        ]);
    }

    // Logout web admin
    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }

    /**
     * =========================================================
     * API AUTHENTICATION (Khusus Mobile Flutter Mahasiswa)
     * Menggunakan Laravel Sanctum untuk Token API
     * =========================================================
     */

    // Memproses login dari aplikasi mobile
    public function apiLogin(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->email)->first();

        // Validasi ketersediaan user dan kecocokan password
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Email atau password salah.'
            ], 401);
        }

        // Pengecekan RBAC: Hanya role MAHASISWA yang boleh mengakses Mobile App
        if ($user->role !== 'MAHASISWA') {
            return response()->json([
                'status' => 'error',
                'message' => 'Akses ditolak. Aplikasi mobile ini dikhususkan untuk Mahasiswa.'
            ], 403);
        }

        // Membuat Sanctum Token untuk sesi di Flutter
        $token = $user->createToken('sigma-mobile-app')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Login berhasil.',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->_id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'id_jurusan' => $user->id_jurusan,
                    'id_prodi' => $user->id_prodi
                ]
            ]
        ], 200);
    }

    // Memproses logout dari aplikasi mobile
    public function apiLogout(Request $request)
    {
        // Menghapus token yang sedang digunakan saat ini
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Logout berhasil, sesi telah dihapus.'
        ], 200);
    }
}
