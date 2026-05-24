<?php

namespace App\Models;

<<<<<<< HEAD
<<<<<<< HEAD
use MongoDB\Laravel\Eloquent\Model; // <-- Wajib gunakan Model MongoDB
=======
use MongoDB\Laravel\Eloquent\Model;
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
=======
use MongoDB\Laravel\Eloquent\Model;
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce

class Schedule extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'schedules';

<<<<<<< HEAD
<<<<<<< HEAD
    // Matikan pengiriman created_at, biarkan updated_at tetap jalan
    const CREATED_AT = null;

=======
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
=======
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
    protected $fillable = [
        'id_mk',
        'nama_mk', 'kode_mk',
        'id_prodi', 'id_jurusan',
        'id_periode',
        'tipe', // 'KULIAH', 'UTS', 'UAS'
        'hari', 'tanggal', 'jam_mulai', 'jam_selesai',
        'ruangan', 'nama_dosen',
        'status', // 'DRAFT', 'FINAL', 'PUBLISHED'
        'pesan_pengantar'
    ];

<<<<<<< HEAD
<<<<<<< HEAD
    // Opsional: Untuk memastikan ID cast kembali ke string saat diambil via API
=======
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
=======
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
    protected $casts = [
        'tanggal' => 'datetime',
        'updated_at' => 'datetime'
    ];
}
