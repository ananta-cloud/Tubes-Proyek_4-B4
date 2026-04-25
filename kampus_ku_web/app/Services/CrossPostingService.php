<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class CrossPostingService
{
    public static function sendToWhatsApp($announcement, $photoUrl = null)
    {
        $kategoriArr = is_object($announcement->kategori) ? $announcement->kategori->getArrayCopy() : (array) $announcement->kategori;
        $kategori = implode(', ', $kategoriArr);

        $waText = "*PENGUMUMAN PUSAT*\n"
                . "Kategori: {$kategori}\n\n"
                . "*{$announcement->judul}*\n\n"
                . "{$announcement->isi}\n\n"
                . "_Info lebih lanjut, cek aplikasi SIGMA Kampusku_";

        $payload = [
            'target' => env('WA_GROUP_TARGET'),
            'message' => $waText,
        ];

        if ($photoUrl) {
            $payload['url'] = $photoUrl;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => env('WA_GATEWAY_TOKEN')
            ])->post(env('WA_GATEWAY_URL'), $payload);

            Log::info('WA Gateway Response: ' . $response->body());
            return $response->successful();
        } catch (\Exception $e) {
            Log::error('WA Gateway Error: ' . $e->getMessage());
            return false;
        }
    }
}
