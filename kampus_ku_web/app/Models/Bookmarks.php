<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;;

class Bookmarks extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'bookmarks';

    protected $fillable = [
        'id_user',
        'id_announcement',
        'judul_snapshot',
        'isi_snapshot',
        'bookmarked_at',
        'is_synced',
        'updated_at'
    ];

    protected $casts = [
        'id_user' => 'objectId',
        'bookmarked_at' => 'datetime',
        'updated_at' => 'datetime',
        'is_synced' => 'boolean'
    ];
}
