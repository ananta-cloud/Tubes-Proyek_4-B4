import 'package:flutter/material.dart';
import 'package:kampus_ku_mobile/theme/app_colors.dart';

class RequestDetailPage extends StatelessWidget {
  const RequestDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Detail Request", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER INFO
            _buildHeaderInfo(),
            const SizedBox(height: 20),

            // 2. PERBANDINGAN JADWAL
            const Text(
              "PERBANDINGAN JADWAL",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.slate500,
              ),
            ),
            const SizedBox(height: 10),
            _buildComparisonCard(
              "Jadwal Saat Ini",
              "Senin, 08:00 - 10:00",
              "GK-301",
              AppColors.slate500,
            ),
            const Center(
              child: Icon(Icons.arrow_downward, color: Colors.indigo, size: 20),
            ),
            _buildComparisonCard(
              "Permintaan Perubahan",
              "Selasa, 13:00 - 15:00",
              "Lab RPL 2",
              Colors.indigo,
            ),

            const SizedBox(height: 24),

            // 3. ACTION BUTTONS (Hanya jika PENDING)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      "TOLAK",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald700,
                    ),
                    child: const Text(
                      "APPROVE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bapak Nazriel, M.T.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Basis Data Terdistribusi",
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 30),
          const Text(
            "ALASAN DOSEN:",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Mohon izin merubah jadwal karena ruangan GK-301 sedang digunakan untuk sertifikasi kompetensi.",
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    String title,
    String time,
    String room,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: color),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: color),
              const SizedBox(width: 8),
              Text(room),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tolak Request"),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Masukkan alasan penolakan (wajib)...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("TOLAK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
