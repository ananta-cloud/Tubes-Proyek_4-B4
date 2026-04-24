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
    protected $fillable = ['kode_mk', 'nama_mk', 'sks', 'id_prodi'];
}
