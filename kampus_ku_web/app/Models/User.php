<?php

namespace App\Models;

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;


class User extends Authenticatable implements AuthenticatableContract
{
    use Notifiable;
<<<<<<< HEAD
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
=======
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce

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
<<<<<<< HEAD
    protected $hidden = [
        'password'
    ];

    protected $casts = [
=======
    protected $hidden = ['password', 'remember_token'];

    protected $casts = [

>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
=======
    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
        'id_mk_ampu' => 'array',
        'created_at' => 'datetime'
    ];

<<<<<<< HEAD
<<<<<<< HEAD
    // JWT IDENTIFIER
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    // JWT CUSTOM CLAIMS
=======
    // JWT
    /**
     * Key yang dijadikan "sub" di dalam payload JWT.
     * MongoDB pakai _id (string ObjectId), bukan integer.
     */
=======
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
    public function getJWTIdentifier()
    {
        return (string) $this->_id;
    }

<<<<<<< HEAD
    /**
     * Custom claims tambahan di dalam payload JWT.
     * Kita sisipkan role agar middleware bisa baca tanpa query DB.
     */
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
=======
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
    public function getJWTCustomClaims(): array
    {
        return [
            'role'       => $this->role,
            'id_jurusan' => $this->id_jurusan,
            'id_prodi'   => $this->id_prodi,
        ];
    }
<<<<<<< HEAD
<<<<<<< HEAD
}
=======
}
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
=======
}
>>>>>>> f66267e2a3f7d7545a5491663c8eb55f8478e8ce
