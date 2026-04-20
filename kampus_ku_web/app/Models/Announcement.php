<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

/**
 * 6. MODEL ANNOUNCEMENT
 */
class Announcement extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'announcements';

    protected $fillable = [
        'judul', 'isi',
        'kategori', // 'Akademik', 'Beasiswa', 'Lomba' dsb.
        'target_audience', // 'UMUM' atau 'PRODI'
        'target_angkatan', // Filter tambahan (Should Have DOCX)
        'id_prodi', 'id_jurusan',
        'id_publisher',
        'nama_publisher', 'role_publisher' // Partial Embed (PDF Bab 4.2)
    ];

    // Array penyimpan user_id yang sudah membaca (Read Confirmation - Should Have DOCX)
    protected $casts = [
        'read_by_users' => 'array',
        'created_at' => 'datetime',
    ];
}
