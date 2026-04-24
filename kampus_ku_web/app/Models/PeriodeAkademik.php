<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

/**
 * 5. MODEL PERIODE AKADEMIK
 */
class PeriodeAkademik extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'periode_akademik';
    protected $fillable = [
        'tahun_akademik', 'jenis_semester', 'is_aktif', 'tanggal_mulai', 'tanggal_selesai'
    ];
    protected $casts = [
        'is_aktif' => 'boolean',
        'tanggal_mulai' => 'datetime',
        'tanggal_selesai' => 'datetime',
    ];
}
