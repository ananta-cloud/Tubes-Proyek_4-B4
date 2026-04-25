<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Schedule extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'schedules';

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

    protected $casts = [
        'tanggal' => 'datetime',
        'updated_at' => 'datetime'
    ];
}
