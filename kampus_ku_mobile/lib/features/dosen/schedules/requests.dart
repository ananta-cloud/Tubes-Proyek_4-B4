import 'package:flutter/material.dart';

class RequestsDosen extends StatelessWidget {
  const RequestsDosen({super.key});

  final Color primaryBlue = const Color(0xFF3F5DB3);
  final Color darkText = const Color(0xFF1F1F3D);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Request Jadwal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text("Buat Baru", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            )
          ],
        ),
        const SizedBox(height: 20),
        _requestItem("Pemrograman Berbasis Objek", "Pindah ke Lab RPL - 20 Mei 2026", "Menunggu"),
        _requestItem("Struktur Data", "Ganti Jam ke 13:00 - 15 Mei 2026", "Disetujui"),
      ],
    );
  }

  Widget _requestItem(String mk, String detail, String status) {
    Color statusColor = status == "Disetujui" ? Colors.green : Colors.amber.shade700;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(blurRadius: 10, offset: const Offset(0, 4), color: Colors.black.withOpacity(0.05))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(mk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail, style: TextStyle(color: darkText.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }
}