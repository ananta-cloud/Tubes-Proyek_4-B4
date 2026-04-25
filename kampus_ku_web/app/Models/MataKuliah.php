<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

/**
 * 4. MODEL MATA KULIAH (Master Data)
 */
class MataKuliah extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'mata_kuliah';
<<<<<<< HEAD
    protected $fillable = ['kode_mk', 'nama_mk', 'sks', 'id_prodi'];
=======

    protected $fillable = ['nama_mk', 'kode_mk', 'id_prodi', 'sks'];

    protected $casts = [
         'sks' => 'integer'
    ];
>>>>>>> sasa
}
