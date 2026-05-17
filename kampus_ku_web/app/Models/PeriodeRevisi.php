<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class PeriodeRevisi extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'periode_revisi';

    public function getTable(): string
    {
        return 'periode_revisi';
    }

    protected $fillable = [
        'judul',
        'scope',
        'id_jadwal',
        'nama_jadwal',
        'nama_dosen',
        'tanggal_mulai',
        'tanggal_selesai',
        'is_active',
        'created_by',
        'created_at',
        'updated_at',
    ];

    protected $casts = [
        'tanggal_mulai'   => 'datetime',
        'tanggal_selesai' => 'datetime',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];

    // Accessor is_active
    public function getIsActiveAttribute($value): bool
    {
        return (bool) $value;
    }

    // Scope: hanya yang aktif & belum lewat tanggal
    public function scopeAktif($query)
    {
        return $query->where('is_active', true)
                     ->where('tanggal_selesai', '>=', now());
    }

    // Scope: filter by scope type
    public function scopeSemester($query)
    {
        return $query->where('scope', 'SEMESTER');
    }

    public function scopeMatkul($query)
    {
        return $query->where('scope', 'MATKUL');
    }

    // Cek apakah sekarang masih dalam periode
    public function isOngoing(): bool
    {
        $now = now();
        return $this->is_active
            && $now->gte($this->tanggal_mulai)
            && $now->lte($this->tanggal_selesai);
    }

    // Cek apakah tanggal tertentu sudah lewat deadline
    public function isLate(): bool
    {
        return now()->gt($this->tanggal_selesai);
    }
}