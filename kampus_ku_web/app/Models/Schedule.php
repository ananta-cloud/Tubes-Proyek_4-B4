<?php

namespace App\Models;

<<<<<<< HEAD
use MongoDB\Laravel\Eloquent\Model; // <-- Wajib gunakan Model MongoDB
=======
use MongoDB\Laravel\Eloquent\Model;
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42

class Schedule extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'schedules';

<<<<<<< HEAD
    // Matikan pengiriman created_at, biarkan updated_at tetap jalan
    const CREATED_AT = null;

=======
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
    protected $fillable = [
        'id_mk',
        'nama_mk', 'kode_mk', // Partial Embed (PDF Bab 4.2)
        'id_prodi', 'id_jurusan',
        'id_periode',
        'tipe', // 'KULIAH', 'UTS', 'UAS'
        'hari', 'tanggal', 'jam_mulai', 'jam_selesai',
        'ruangan', 'nama_dosen',
        'status', // 'DRAFT', 'FINAL', 'PUBLISHED'
        'pesan_pengantar'
    ];

<<<<<<< HEAD
    // Opsional: Untuk memastikan ID cast kembali ke string saat diambil via API
=======
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
    protected $casts = [
        'tanggal' => 'datetime',
        'updated_at' => 'datetime'
    ];
}
