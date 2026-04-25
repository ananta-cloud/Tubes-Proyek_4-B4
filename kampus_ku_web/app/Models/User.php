<?php

namespace App\Models;

use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements JWTSubject
{
    use Notifiable;

    protected $connection = 'mongodb';
    protected $collection = 'users';

    // ==========================================
    // TAMBAHKAN 2 BARIS INI AGAR SESI TIDAK HILANG
    // ==========================================
    protected $keyType = 'string';
    public $incrementing = false;
    // ==========================================

    protected $fillable = [
        'nama',
        'email',
        'password',
        'role',
        'id_jurusan',
        'id_prodi',
        'id_mk_ampu',
        'device_token',
        'angkatan',
        'created_at'
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'id_mk_ampu' => 'array',
        'created_at' => 'datetime'
    ];

    public function getJWTIdentifier()
    {
        return (string) $this->_id;
    }

    public function getJWTCustomClaims(): array
    {
        return [
            'role'       => $this->role,
            'id_jurusan' => $this->id_jurusan,
            'id_prodi'   => $this->id_prodi,
        ];
    }
}
