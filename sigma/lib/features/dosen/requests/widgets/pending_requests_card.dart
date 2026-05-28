import 'package:flutter/material.dart';

class PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const PendingRequestCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final detail = Map<String, dynamic>.from(data['detail_perubahan'] ?? {});
    final namaDosen = data['nama_dosen'] ?? 'Permohonan Baru';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 13),
                SizedBox(width: 6),
                Text(
                  'Menunggu koneksi untuk dikirim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(namaDosen, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '${detail['hari_baru'] ?? '-'}\n'
            '${detail['jam_mulai_baru'] ?? '-'}–${detail['jam_selesai_baru'] ?? '-'}\n'
            '${detail['ruangan_baru'] ?? '-'}',
          ),
        ],
      ),
    );
  }
}
