<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Announcement extends Model
{
    protected $connection = 'mongodb';
<<<<<<< HEAD
<<<<<<< HEAD
=======

>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
    protected $collection = 'announcements';

    public $timestamps = false;

    protected $fillable = [
        'judul', 
        'isi',
        'target_audience',
        'id_prodi', 
        'id_jurusan',
        'id_publisher',
        'nama_publisher', 
        'role_publisher',
        'kategori', // 'Akademik', 'Beasiswa', 'Lomba' dsb.
        'target_angkatan', // Filter tambahan
        'created_at',
        'updated_at',
<<<<<<< HEAD
=======

    protected $collection = 'announcements';

    public $timestamps = false;

    protected $fillable = [
        'judul', 'isi', 'target_audience', 'id_prodi', 'id_jurusan',
        'id_publisher', 'nama_publisher', 'role_publisher',
        'kategori', 'target_angkatan', 'created_at', 'updated_at',
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
=======
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
    ];

    // Array penyimpan user_id yang sudah membaca (Read Confirmation)
    protected $casts = [
        // 'read_by_users' => 'array',
        // 'kategori' => 'array',
        // 'target_angkatan' => 'array',

        'read_by_users' => 'array',

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

    public function getKategoriAttribute($value): array
    {
        if (is_array($value)) return $value;
        if (is_string($value)) return json_decode($value, true) ?? [];
        return [];
    }

    public function getReadByUsersAttribute($value): array
    {
        if (is_array($value)) return $value;
        if (is_string($value)) return json_decode($value, true) ?? [];
        return [];
    }

    public function getTargetAngkatanAttribute($value): array
    {
        if (is_array($value)) return $value;
        if (is_string($value)) return json_decode($value, true) ?? [];
        return [];
    }
}
