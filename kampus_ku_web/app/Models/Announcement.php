<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Announcement extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'announcements';

    protected $fillable = [
        'judul', 
        'isi',
        'target_audience',
        'id_prodi', 
        'id_jurusan',
        'id_publisher',
        'nama_publisher', 
        'role_publisher', // Partial Embed (PDF Bab 4.2)
        'kategori', // 'Akademik', 'Beasiswa', 'Lomba' dsb.
        'target_angkatan', // Filter tambahan (Should Have DOCX),
        'created_at',
        'updated_at',
    ];

    // Array penyimpan user_id yang sudah membaca (Read Confirmation - Should Have DOCX)
    protected $casts = [
        'read_by_users' => 'array',

        'kategori' => 'array',
        'target_angkatan' => 'array',

        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    const TARGET_AUDIENCE = [
        'SEMUA',
        'SEMUA_MAHASISWA',
        'SEMUA_DOSEN',
        'PRODI_MAHASISWA',
        'PRODI_DOSEN',
        'PRODI_SEMUA'
    ];

    const ROLE_PUBLISHER = [
        'ADMIN_TU',
        'MANAJEMEN'
    ];

    const KATEGORI = [
        'AKADEMIK',
        'BEASISWA',
        'LOMBA',
        'UKM',
        'KARIR',
        'PKM',
        'WIRAUSAHA',
        'KONSELING',
        'FASILITAS',
        'LAINNYA'
    ];
}
