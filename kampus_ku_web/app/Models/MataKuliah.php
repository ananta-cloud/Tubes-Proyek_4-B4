<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class MataKuliah extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'mata_kuliah';

    protected $fillable = ['nama_mk', 'kode_mk', 'id_prodi', 'sks'];

    protected $casts = [
         'sks' => 'integer'
    ];
}
