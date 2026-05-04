<?php

namespace App\Models;

<<<<<<< HEAD
use MongoDB\Laravel\Auth\User as Authenticatable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable implements JWTSubject
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
    public function getJWTIdentifier()
    {
        return (string) $this->_id;
    }

    /**
     * Custom claims tambahan di dalam payload JWT.
     * Kita sisipkan role agar middleware bisa baca tanpa query DB.
     */
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
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
>>>>>>> 2e2f4fafcfbb182b74e8f1c9cd50cf201c0a9f42
