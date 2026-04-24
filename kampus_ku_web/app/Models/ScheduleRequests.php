<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class ScheduleRequests extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'schedule_requests';

    protected $fillable = [
        'id_schedule',
        'id_dosen',
        'nama_dosen',
        'tipe_request',
        'detail_perubahan',
        'alasan',
        'status',
        'catatan_admin',
        'id_processor',
        'created_at',
        'updated_at'
    ];

    protected $casts = [
        'id_schedule' => 'objectId',
        'id_dosen' => 'objectId',
        'id_processor' => 'objectId',
        'detail_perubahan' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];
}
