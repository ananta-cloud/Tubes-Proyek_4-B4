<?php

namespace App\Models;

use MongoDB\Laravel\Auth\User as Authenticatable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable implements JWTSubject
{
    use Notifiable;

    protected $connection = 'mongodb';
    protected $collection = 'users';

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

    protected $hidden = [
        'password'
    ];

    protected $casts = [
        'id_mk_ampu' => 'array',
        'created_at' => 'datetime'
    ];

    // JWT IDENTIFIER
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    // JWT CUSTOM CLAIMS
    public function getJWTCustomClaims(): array
    {
        return [
            'role'       => $this->role,
            'id_jurusan' => $this->id_jurusan,
            'id_prodi'   => $this->id_prodi,
        ];
    }
}