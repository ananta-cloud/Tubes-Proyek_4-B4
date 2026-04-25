<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model; // <-- Wajib gunakan Model MongoDB

class Schedule extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'schedules';

    // Matikan pengiriman created_at, biarkan updated_at tetap jalan
    const CREATED_AT = null;

    protected $fillable = [
<<<<<<< HEAD
        'id_mk', 'nama_mk', 'kode_mk', 'id_prodi', 'id_jurusan', 'id_periode',
        'tipe', 'hari', 'tanggal', 'jam_mulai', 'jam_selesai', 'ruangan',
        'nama_dosen', 'status', 'pesan_pengantar'
=======
        'id_mk',
        'nama_mk', 'kode_mk', // Partial Embed (PDF Bab 4.2)
        'id_prodi', 'id_jurusan',
        'id_periode',
        'tipe', // 'KULIAH', 'UTS', 'UAS'
        'hari', 'tanggal', 'jam_mulai', 'jam_selesai',
        'ruangan', 'nama_dosen',
        'status', // 'DRAFT', 'FINAL', 'PUBLISHED'
        'pesan_pengantar'
>>>>>>> sasa
    ];

    // Opsional: Untuk memastikan ID cast kembali ke string saat diambil via API
    protected $casts = [
<<<<<<< HEAD
        'id_mk' => 'string',
        'id_prodi' => 'string',
        'id_jurusan' => 'string',
        'id_periode' => 'string',
=======
        'tanggal' => 'datetime',
        'updated_at' => 'datetime'
>>>>>>> sasa
    ];
}
