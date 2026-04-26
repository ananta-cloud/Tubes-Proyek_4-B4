<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Tasks;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class TaskAPIController extends Controller
{
    // 1. Mengambil Semua Tugas Server (Untuk login pertama kali di HP baru)
    public function index()
    {
        $user = Auth::user();
        
        // Ambil tugas milik user yang sedang login
        $tasks = Tasks::where('id_user', $user->_id)->get();

        return response()->json([
            'success' => true,
            'data' => $tasks
        ]);
    }

    // 2. Endpoint Sinkronisasi (Jantung dari Offline-First)
    public function sync(Request $request)
    {
        $user = Auth::user();
        $unsyncedTasks = $request->input('tasks'); // Menerima array dari Flutter
        $syncedIdsMap = []; // Untuk memberi tahu Flutter perubahan ID lokal ke Server

        if (!$unsyncedTasks) {
            return response()->json(['success' => true, 'message' => 'Tidak ada data untuk disinkronisasi']);
        }

        foreach ($unsyncedTasks as $taskData) {
            // Cek apakah ID dari Flutter adalah angka timestamp lokal (biasanya panjangnya 13 digit)
            $isNewLocalTask = is_numeric($taskData['id']) && strlen($taskData['id']) > 10;

            if ($isNewLocalTask) {
                // A. BUAT TUGAS BARU DI SERVER
                $task = new Tasks();
                $task->id_user = $user->_id; // Ambil otomatis dari Token JWT
                $task->nama_tugas = $taskData['nama_tugas'];
                $task->id_mk = $taskData['id_mk'] ?? null;
                $task->nama_mk_snapshot = $taskData['nama_mk_snapshot'] ?? null;
                $task->deskripsi = $taskData['deskripsi'] ?? null;
                
                // Konversi tanggal dari format ISO String Flutter ke format MongoDB
                $task->deadline = Carbon::parse($taskData['deadline'])->timezone('UTC');
                $task->status = $taskData['status'] ?? 'BELUM';
                $task->is_synced = true;
                $task->save();

                // Simpan peta: "ID Lokal 167... berubah menjadi ID MongoDB 69e..."
                $syncedIdsMap[] = [
                    'local_id' => $taskData['id'],
                    'server_id' => $task->_id
                ];
            } else {
                // B. UPDATE TUGAS YANG SUDAH ADA (Pakai ID MongoDB)
                $task = Tasks::find($taskData['id']);
                
                // Pastikan tugas ini benar-benar milik user tersebut (Keamanan)
                if ($task && $task->id_user == $user->_id) {
                    $task->nama_tugas = $taskData['nama_tugas'];
                    $task->nama_mk_snapshot = $taskData['nama_mk_snapshot'] ?? null;
                    $task->deadline = Carbon::parse($taskData['deadline'])->timezone('UTC');
                    $task->status = $taskData['status'];
                    $task->is_synced = true;
                    $task->save();
                }
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Sinkronisasi ke Cloud Berhasil',
            'synced_ids_map' => $syncedIdsMap // Dikembalikan ke Flutter
        ]);
    }

    // 3. Menghapus Tugas secara permanen
    public function destroy($id)
    {
        $user = Auth::user();
        $task = Tasks::where('_id', $id)->where('id_user', $user->_id)->first();

        if ($task) {
            $task->delete();
            return response()->json(['success' => true, 'message' => 'Tugas berhasil dihapus dari Cloud']);
        }

        return response()->json(['success' => false, 'message' => 'Tugas tidak ditemukan'], 404);
    }
}
