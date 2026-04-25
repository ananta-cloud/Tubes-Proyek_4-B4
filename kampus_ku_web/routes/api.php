<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ScheduleApiController;
use App\Http\Controllers\MahasiswaApiController;
use App\Http\Controllers\PeriodeRevisiApiController;

// ============================================================
// PUBLIC: Auth (tidak butuh token)
// ============================================================
Route::prefix('auth')->group(function () {
    Route::post('/login',   [AuthController::class, 'apiLogin']);
    Route::post('/refresh', [AuthController::class, 'refresh']);           // opsional

    // Logout tetap butuh token yang valid untuk di-invalidate
    Route::post('/logout',  [AuthController::class, 'apiLogout'])->middleware('jwt');
});


// ============================================================
// PROTECTED: Semua route butuh JWT Bearer Token
// ============================================================
Route::middleware('jwt')->group(function () {

    // JADWAL — Mahasiswa & Dosen
    Route::prefix('schedules')->group(function () {
        Route::get('/',   [ScheduleApiController::class, 'index']);
        Route::get('/my', [ScheduleApiController::class, 'mySchedules']);
    });

    // SCHEDULE REQUESTS — Khusus Dosen
    Route::middleware('jwt:DOSEN')->prefix('schedule-requests')->group(function () {
        Route::get('/my',       [ScheduleApiController::class, 'myRequests']);
        Route::post('/',        [ScheduleApiController::class, 'storeRequest']);
        Route::delete('/{id}',  [ScheduleApiController::class, 'cancelRequest']);
    });

    Route::middleware('jwt:DOSEN')->prefix('periode-revisi')->group(function () {
 
    // PERIODE REVISI — Khusus Dosen
    // Periode aktif yang relevan untuk dosen yang login
    Route::get('/',                        [PeriodeRevisiApiController::class, 'index']);
 
    // Semua periode — untuk dosen lihat riwayat deadline
    // HARUS didefinisikan SEBELUM /{id} agar tidak tertangkap wildcard
    Route::get('/semua',                   [PeriodeRevisiApiController::class, 'semua']);
 
    // Cek apakah jadwal tertentu masih dalam periode revisi
    Route::get('/cek-jadwal/{id_jadwal}',  [PeriodeRevisiApiController::class, 'cekJadwal']);
 
    // Detail satu periode
    Route::get('/{id}',                    [PeriodeRevisiApiController::class, 'show']);
});

    // MAHASISWA — Khusus Mahasiswa
    Route::middleware('jwt:MAHASISWA')->prefix('mahasiswa')->group(function () {
        Route::get('/schedules',                          [MahasiswaApiController::class, 'schedules']);
        Route::get('/bookmarks',                          [MahasiswaApiController::class, 'bookmarks']);
        Route::post('/bookmarks/{id_schedule}',           [MahasiswaApiController::class, 'addBookmark']);
        Route::delete('/bookmarks/{id_schedule}',         [MahasiswaApiController::class, 'removeBookmark']);
    });

});