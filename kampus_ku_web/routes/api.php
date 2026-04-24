<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ScheduleApiController;
use App\Http\Controllers\MahasiswaApiController;

/*
--------------------------------------------------------------------------
API Routes — SIGMA Mobile (Flutter)
Base URL: /api/...
Auth: Laravel Sanctum (Bearer Token)
--------------------------------------------------------------------------

Dua role yang mengakses API ini:
   - MAHASISWA : Melihat jadwal, bookmark, notifikasi
   - DOSEN     : Melihat jadwal mengajar, ajukan request perubahan

*/

// ============================================================
// PUBLIC: Auth (tidak butuh token)
// ============================================================
Route::prefix('auth')->group(function () {
    Route::post('/login',  [AuthController::class, 'apiLogin']);
    Route::post('/logout', [AuthController::class, 'apiLogout'])->middleware('auth:sanctum');
});


// ============================================================
// PROTECTED: Semua route di bawah butuh Bearer Token Sanctum
// ============================================================
Route::middleware('auth:sanctum')->group(function () {

    // JADWAL — Diakses Mahasiswa & Dosen
    Route::prefix('schedules')->group(function () {

        // GET /api/schedules
        // Semua jadwal published, bisa difilter ?id_prodi=&hari=
        Route::get('/',    [ScheduleApiController::class, 'index']);

        // GET /api/schedules/my
        // Jadwal mengajar dosen yang sedang login (scope nama_dosen)
        // Harus didefinisikan SEBELUM /{id} agar tidak tertangkap sebagai wildcard
        Route::get('/my',  [ScheduleApiController::class, 'mySchedules']);

    });


    // SCHEDULE REQUESTS — Khusus Dosen
    Route::prefix('schedule-requests')->group(function () {

        // GET  /api/schedule-requests/my
        // Riwayat semua request yang pernah diajukan dosen ini
        Route::get('/my',    [ScheduleApiController::class, 'myRequests']);

        // POST /api/schedule-requests
        // Dosen mengajukan request perubahan jadwal
        // Body: { id_schedule, tipe_request, detail_perubahan: {}, alasan }
        Route::post('/',     [ScheduleApiController::class, 'storeRequest']);

        // DELETE /api/schedule-requests/{id}
        // Dosen membatalkan request yang masih PENDING
        Route::delete('/{id}', [ScheduleApiController::class, 'cancelRequest']);

    });


    // MAHASISWA — Endpoint khusus aplikasi mahasiswa
    // Diasumsikan MahasiswaApiController sudah ada di proyekmu
    Route::prefix('mahasiswa')->group(function () {

        // GET /api/mahasiswa/schedules
        // Jadwal berdasarkan prodi mahasiswa yang login
        Route::get('/schedules',  [MahasiswaApiController::class, 'schedules']);

        // GET /api/mahasiswa/bookmarks
        // Daftar jadwal yang di-bookmark mahasiswa
        Route::get('/bookmarks',  [MahasiswaApiController::class, 'bookmarks']);

        // POST /api/mahasiswa/bookmarks/{id_schedule}
        // Tambah bookmark
        Route::post('/bookmarks/{id_schedule}',   [MahasiswaApiController::class, 'addBookmark']);

        // DELETE /api/mahasiswa/bookmarks/{id_schedule}
        // Hapus bookmark
        Route::delete('/bookmarks/{id_schedule}', [MahasiswaApiController::class, 'removeBookmark']);

    });

});