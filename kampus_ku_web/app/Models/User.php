<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use Illuminate\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;

/**
 * 1. MODEL USER (Mahasiswa, Kajur, Admin TU, Manajemen)
 */
class User extends Model implements AuthenticatableContract
{
    use Authenticatable, Notifiable;

    protected $connection = 'mongodb';
    protected $collection = 'users';

    protected $fillable = [
        'name', 'email', 'password',
        'role', // 'KAJUR', 'ADMIN_TU', 'MANAJEMEN', 'MAHASISWA'
        'id_jurusan', 'id_prodi' // Nullable untuk role Manajemen
    ];

    protected $hidden = ['password', 'remember_token'];
}
