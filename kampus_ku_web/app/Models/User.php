<?php

namespace App\Models;

<<<<<<< HEAD
use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;


class User extends Authenticatable implements AuthenticatableContract
{
    use Notifiable;
=======
use MongoDB\Laravel\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use Illuminate\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Tymon\JWTAuth\Contracts\JWTSubject;


class User extends Model implements AuthenticatableContract, JWTSubject
{
    use Authenticatable, Notifiable;
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42

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

<<<<<<< HEAD
    protected $hidden = [
        'password'
    ];

    protected $casts = [
=======
    protected $hidden = ['password', 'remember_token'];

    protected $casts = [

>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
        'id_mk_ampu' => 'array',
        'created_at' => 'datetime'
    ];

    // JWT IDENTIFIER
    public function getJWTIdentifier()
    {
        return (string) $this->_id;
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
<<<<<<< HEAD
}
=======
}