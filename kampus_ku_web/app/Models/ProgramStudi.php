<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class ProgramStudi extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'program_studi';

    // pakai getTable() untuk resolve collection name
    public function getTable(): string
    {
        return 'program_studi';
    }

    protected $fillable = ['nama_prodi', 'kode_prodi', 'id_jurusan'];
}