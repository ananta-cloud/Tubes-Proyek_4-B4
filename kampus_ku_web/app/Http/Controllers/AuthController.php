<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;


class AuthController extends Controller
{
    /**
     * =========================================================
     * WEB AUTHENTICATION (Admin TU, Manajemen Kampus, Tim Penjadwalan)
     * =========================================================
     */

    public function showLogin()
    {
        return view('auth.login');
    }

    public function processLogin(Request $request)
    {
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required'
        ]);

        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();
            $user = Auth::user();

            if ($user->role === 'MANAJEMEN') {
                return redirect('/manajemen/announcements');
            } elseif ($user->role === 'TIM_PENJADWALAN') {
                return redirect('/penjadwalan/dashboard');
            } elseif ($user->role === 'ADMIN_TU') {
                return redirect('/jurusan/announcements');
            }

            // Cegah role lain login via web admin
            Auth::logout();
            return back()->withErrors([
                'email' => 'Akses ditolak. Portal Web ini hanya untuk Admin/Tim Penjadwalan. Gunakan aplikasi mobile SIGMA.',
            ]);
        }

        return back()->withErrors([
            'email' => 'Kredensial salah. Pastikan email dan password Anda benar.',
        ]);
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }

    /**
     * =========================================================
     * API AUTHENTICATION (Mobile Flutter — Mahasiswa & Dosen)
     * =========================================================
     */

    /**
     * POST /api/auth/login
     */
    public function apiLogin(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Email atau password salah.',
            ], 401);
        }

        if (!in_array($user->role, ['MAHASISWA', 'DOSEN'])) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Akses ditolak. Aplikasi mobile dikhususkan untuk Mahasiswa dan Dosen.',
            ], 403);
        }

        try {
            // Buat token dari object $user (bukan credentials array)
            // karena password di MongoDB mungkin di-hash manual, bukan lewat attempt()
            $token = JWTAuth::fromUser($user);
        } catch (JWTException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Gagal membuat token, coba lagi.',
            ], 500);
        }

        return response()->json([
            'status'  => 'success',
            'message' => 'Login berhasil.',
            'data'    => [
                'token'      => $token,
                'token_type' => 'bearer',
                'expires_in' => config('jwt.ttl') * 60, // dalam detik
                'user'       => [
                    'id'         => (string) $user->_id,
                    'nama'       => $user->nama,
                    'email'      => $user->email,
                    'role'       => $user->role,
                    'id_jurusan' => $user->id_jurusan,
                    'id_prodi'   => $user->id_prodi,
                ],
            ],
        ], 200);
    }

    /**
     * POST /api/auth/logout
     * Header: Authorization: Bearer <token>
     */
    public function apiLogout(Request $request)
    {
        try {
            JWTAuth::invalidate(JWTAuth::getToken());

            return response()->json([
                'status'  => 'success',
                'message' => 'Logout berhasil, token telah diinvalidasi.',
            ], 200);

        } catch (JWTException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Gagal logout, token tidak valid.',
            ], 400);
        }
    }

    /**
     * POST /api/auth/refresh
     * Opsional — perpanjang token sebelum expired
     */
    public function refresh()
    {
        try {
            $newToken = JWTAuth::refresh(JWTAuth::getToken());

            return response()->json([
                'status' => 'success',
                'data'   => [
                    'token'      => $newToken,
                    'token_type' => 'bearer',
                    'expires_in' => config('jwt.ttl') * 60,
                ],
            ], 200);

        } catch (JWTException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Token tidak bisa di-refresh, silakan login ulang.',
            ], 401);
        }
    }
}
