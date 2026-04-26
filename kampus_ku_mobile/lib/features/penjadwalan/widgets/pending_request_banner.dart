import 'package:flutter/material.dart';
import 'package:kampus_ku_mobile/features/penjadwalan/requests/request_page.dart';

class PendingRequestBanner extends StatelessWidget {
  final int count;
  final String idJurusan;

  const PendingRequestBanner({
    super.key,
    required this.count,
    required this.idJurusan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Request Menunggu',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                const Text(
                  'Dosen mengajukan perubahan jadwal.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => // ✅ FIX
                        RequestsIndexPage(idJurusan: idJurusan),
              ),
            ),
            child: const Text(
              'Kelola →',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
