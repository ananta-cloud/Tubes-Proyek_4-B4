<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ScheduleController;
use App\Http\Controllers\AnnouncementController;
use App\Http\Controllers\MasterMatkulController;
use App\Http\Controllers\AuthController;

// Rute Publik (Login)
Route::get('/', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'processLogin']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Grup Rute yang membutuhkan Login
Route::middleware(['auth'])->group(function () {

    // ==================================================
    // RUTE KAJUR & ADMIN TU
    // ==================================================
    Route::middleware(['role:KAJUR,ADMIN_TU'])->prefix('jurusan')->group(function () {
        // Render view jadwal
        Route::get('/schedules', [ScheduleController::class, 'index']);

        // Render view pengumuman jurusan
        Route::get('/announcements', [AnnouncementController::class, 'index']);

        // Render view Master Data Matkul (Yang ada di Canvas)
        Route::get('/master-matkul', [MasterMatkulController::class, 'index']);
    });

    // ==================================================
    // RUTE MANAJEMEN KAMPUS
    // ==================================================
    Route::middleware(['role:MANAJEMEN'])->prefix('manajemen')->group(function () {
        // Manajemen Kampus hanya mengurus pengumuman umum
        Route::get('/announcements', [AnnouncementController::class, 'index']);
    });

});
