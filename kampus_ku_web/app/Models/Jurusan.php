<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

/**
 * 2. MODEL JURUSAN
 */
class Jurusan extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'jurusan';
    protected $fillable = ['nama_jurusan', 'kode_jurusan'];
}
