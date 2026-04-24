<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Tasks extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'tasks';

    protected $fillable = [
        'id_user',
        'nama_tugas',
        'deskripsi',
        'id_mk',
        'nama_mk_snapshot',
        'deadline',
        'status',
        'is_synced',
        'created_at',
        'updated_at'
    ];

    protected $casts = [
        'id_user' => 'objectId',
        'deadline' => 'datetime',
        'is_synced' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];
}
