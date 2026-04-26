<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ScheduleApiController;
use App\Http\Controllers\AnnouncementAPIController;
use App\Http\Controllers\MahasiswaApiController;
use App\Http\Controllers\TaskAPIController;

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

    Route::get('/announcements', [AnnouncementAPIController::class, 'index']);

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

    // MAHASISWA — Khusus Mahasiswa
    Route::middleware('jwt:MAHASISWA')->prefix('mahasiswa')->group(function () {
        Route::get('/schedules',                          [MahasiswaApiController::class, 'schedules']);
        Route::get('/bookmarks',                          [MahasiswaApiController::class, 'bookmarks']);
        Route::post('/bookmarks/{id_schedule}',           [MahasiswaApiController::class, 'addBookmark']);
        Route::delete('/bookmarks/{id_schedule}',         [MahasiswaApiController::class, 'removeBookmark']);
    });

    // TASKS — Khusus Mahasiswa
    Route::get('/tasks', [TaskAPIController::class, 'index']);
    Route::post('/tasks/sync', [TaskAPIController::class, 'sync']);
    Route::delete('/tasks/{id}', [TaskAPIController::class, 'destroy']);
});