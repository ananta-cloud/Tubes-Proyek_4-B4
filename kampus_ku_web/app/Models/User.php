<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use Illuminate\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Tymon\JWTAuth\Contracts\JWTSubject;


class User extends Model implements AuthenticatableContract, JWTSubject
{
    use Authenticatable, Notifiable;

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

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [

        'id_mk_ampu' => 'array',
        'created_at' => 'datetime'
    ];

    // JWT
    /**
     * Key yang dijadikan "sub" di dalam payload JWT.
     * MongoDB pakai _id (string ObjectId), bukan integer.
     */
    public function getJWTIdentifier()
    {
        return (string) $this->_id;
    }

    /**
     * Custom claims tambahan di dalam payload JWT.
     * Kita sisipkan role agar middleware bisa baca tanpa query DB.
     */
    public function getJWTCustomClaims(): array
    {
        return [
            'role'       => $this->role,
            'id_jurusan' => $this->id_jurusan,
            'id_prodi'   => $this->id_prodi,
        ];
    }
}
