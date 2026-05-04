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
    // RUTE ADMIN TU
    // ==================================================
    Route::middleware(['role:ADMIN_TU'])->prefix('jurusan')->name('admin.')->group(function () {
        Route::get('/announcements',                [AnnouncementController::class, 'index'])->name('announcements.index');
        Route::get('/announcements/create',         [AnnouncementController::class, 'create'])->name('announcements.create');
        Route::post('/announcements',               [AnnouncementController::class, 'store'])->name('announcements.store');
        Route::delete('/announcements/{id}',        [AnnouncementController::class, 'destroy'])->name('announcements.destroy');
        Route::get('/master-matkul', [MasterMatkulController::class, 'index']);

        // Finalisasi jadwal (DRAFT → FINAL)
        Route::get('/schedules', [ScheduleController::class, 'index']);
        Route::patch('/schedules/{id}/finalize', [ScheduleController::class, 'finalize']);
        // Publikasi jadwal (FINAL → PUBLISHED) — Dikontrol RBAC di Controller/Policy
        Route::patch('/schedules/{id}/publish', [ScheduleController::class, 'publish']);
    });

    // ==================================================
    // RUTE TIM PENJADWALAN
    // ==================================================
    Route::middleware(['role:TIM_PENJADWALAN'])->prefix('penjadwalan')->name('penjadwalan.')->group(function () {

        // --- Dashboard Utama ---
        Route::get('/dashboard', [ScheduleController::class, 'dashboard'])->name('dashboard');

        // --- CRUD Jadwal ---
        Route::prefix('schedules')->name('schedules.')->group(function () {
            Route::get('/',            [ScheduleController::class, 'index'])->name('index');   // List + Filter
            Route::get('/create',      [ScheduleController::class, 'create'])->name('create'); // Form input baru
            Route::post('/',           [ScheduleController::class, 'store'])->name('store');   // Simpan jadwal baru
            Route::get('/{id}/edit',   [ScheduleController::class, 'edit'])->name('edit');     // Form edit
            Route::put('/{id}',        [ScheduleController::class, 'update'])->name('update'); // Update jadwal
        });

        // --- Kelola Request Perubahan dari Dosen ---
        Route::prefix('requests')->name('requests.')->group(function () {
            Route::get('/',                        [ScheduleController::class, 'requests'])->name('index');         // List semua request
            Route::get('/{id}',                    [ScheduleController::class, 'requestDetail'])->name('detail');  // Detail request
            Route::patch('/{id}/approve',          [ScheduleController::class, 'approveRequest'])->name('approve'); // Approve
            Route::patch('/{id}/reject',           [ScheduleController::class, 'rejectRequest'])->name('reject');  // Reject
        });

        Route::get('/master-matkul', [MasterMatkulController::class, 'index'])->name('master-matkul.index');
    });

    // ==================================================
    // RUTE MANAJEMEN KAMPUS
    // ==================================================
    Route::middleware(['auth', 'role:MANAJEMEN'])->prefix('manajemen')->name('manajemen.')->group(function () {

        // Dashboard & Arsip
        Route::get('/dashboard', [AnnouncementController::class, 'index'])->name('dashboard');

        // CRUD Pengumuman
        Route::resource('announcements', AnnouncementController::class);

        // Fitur Tambahan (Read Confirmation & Helper)
        Route::get('/announcements/{id}/details', [AnnouncementController::class, 'show'])->name('announcements.show');
        Route::post('/announcements/{id}/broadcast', [AnnouncementController::class, 'broadcast'])->name('announcements.broadcast');
    });

});
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
    // RUTE ADMIN TU
    // ==================================================
    Route::middleware(['role:ADMIN_TU'])->prefix('jurusan')->group(function () {
        Route::get('/schedules', [ScheduleController::class, 'index']);
        Route::get('/announcements', [AnnouncementController::class, 'index']);
        Route::get('/master-matkul', [MasterMatkulController::class, 'index']);

        // Finalisasi jadwal (DRAFT → FINAL)
        Route::patch('/schedules/{id}/finalize', [ScheduleController::class, 'finalize']);

        // Publikasi jadwal (FINAL → PUBLISHED) — Dikontrol RBAC di Controller/Policy
        Route::patch('/schedules/{id}/publish', [ScheduleController::class, 'publish']);
    });

    // ==================================================
    // RUTE TIM PENJADWALAN
    // ==================================================
    Route::middleware(['role:TIM_PENJADWALAN'])->prefix('penjadwalan')->name('penjadwalan.')->group(function () {

        // --- Dashboard Utama ---
        Route::get('/dashboard', [ScheduleController::class, 'dashboard'])->name('dashboard');

        // --- CRUD Jadwal ---
        Route::prefix('schedules')->name('schedules.')->group(function () {
            Route::get('/',            [ScheduleController::class, 'index'])->name('index');   // List + Filter
            Route::get('/create',      [ScheduleController::class, 'create'])->name('create'); // Form input baru
            Route::post('/',           [ScheduleController::class, 'store'])->name('store');   // Simpan jadwal baru
            Route::get('/{id}/edit',   [ScheduleController::class, 'edit'])->name('edit');     // Form edit
            Route::put('/{id}',        [ScheduleController::class, 'update'])->name('update'); // Update jadwal
            Route::patch('/{id}/finalize', [ScheduleController::class, 'finalize'])->name('finalize'); // DRAFT→FINAL
            Route::patch('/{id}/publish',  [ScheduleController::class, 'publish'])->name('publish');   // FINAL→PUBLISHED
        });

        // --- Kelola Request Perubahan dari Dosen ---
        Route::prefix('requests')->name('requests.')->group(function () {
            Route::get('/',                        [ScheduleController::class, 'requests'])->name('index');         // List semua request
            Route::get('/{id}',                    [ScheduleController::class, 'requestDetail'])->name('detail');  // Detail request
            Route::patch('/{id}/approve',          [ScheduleController::class, 'approveRequest'])->name('approve'); // Approve
            Route::patch('/{id}/reject',           [ScheduleController::class, 'rejectRequest'])->name('reject');  // Reject
        });
    });

    // ==================================================
    // RUTE MANAJEMEN KAMPUS
    // ==================================================
    Route::middleware(['role:MANAJEMEN'])->prefix('manajemen')->group(function () {
        Route::get('/announcements', [AnnouncementController::class, 'index']);
    });

});