<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

/**
 * 7. MODEL SCHEDULE
 */
class Schedule extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'schedules';

    protected $fillable = [
        'id_mk',
        'nama_mk', 'kode_mk', // Partial Embed (PDF Bab 4.2)
        'id_prodi', 'id_jurusan',
        'tipe', // 'KULIAH', 'UTS', 'UAS'
        'hari', 'tanggal', 'jam_mulai', 'jam_selesai',
        'ruangan', 'nama_dosen',
        'status', // 'DRAFT', 'FINAL', 'PUBLISHED'
        'pesan_pengantar', 'id_periode'
    ];

    protected $casts = [
        'tanggal' => 'datetime',
        'jam_mulai' => 'datetime',
        'jam_selesai' => 'datetime',
    ];
}
