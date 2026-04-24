<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

/**
 * 3. MODEL PROGRAM STUDI
 */
class ProgramStudi extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'program_studi';

    protected $fillable = ['nama_prodi', 'kode_prodi', 'id_jurusan'];

    protected $casts = [
        'id_jurusan' => 'objectId'
    ];
}

