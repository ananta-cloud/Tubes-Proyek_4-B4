<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\TokenExpiredException;
use Tymon\JWTAuth\Exceptions\TokenInvalidException;
use Tymon\JWTAuth\Exceptions\JWTException;

class JwtMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        try {
            $user = JWTAuth::parseToken()->authenticate();

            if (!$user) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'User tidak ditemukan.',
                ], 401);
            }

            // Jika middleware dipanggil dengan role: jwt:DOSEN atau jwt:MAHASISWA,DOSEN
            if (!empty($roles) && !in_array($user->role, $roles)) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Akses ditolak. Role tidak sesuai.',
                ], 403);
            }

        } catch (TokenExpiredException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Token sudah expired, silakan refresh atau login ulang.',
            ], 401);

        } catch (TokenInvalidException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Token tidak valid.',
            ], 401);

        } catch (JWTException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Token tidak ditemukan.',
            ], 401);
        }

        return $next($request);
    }
}