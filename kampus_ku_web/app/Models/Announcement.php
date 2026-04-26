<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Announcement extends Model
{
    protected $connection = 'mongodb';

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
    ];

    // Array penyimpan user_id yang sudah membaca (Read Confirmation)
    protected $casts = [
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
