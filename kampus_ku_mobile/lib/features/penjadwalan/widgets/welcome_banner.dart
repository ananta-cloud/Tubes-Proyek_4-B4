import 'package:flutter/material.dart';
import 'package:kampus_ku_mobile/features/penjadwalan/widgets/banner_button.dart';
import 'package:kampus_ku_mobile/features/penjadwalan/requests/request_page.dart';
import 'package:kampus_ku_mobile/features/penjadwalan/schedules/index_page.dart';

class WelcomeBanner extends StatelessWidget {
  final String namaUser;
  final int pendingRequests;
  final String idJurusan;

  const WelcomeBanner({
    super.key, // ✅ ini aja yang wajib ditambah
    required this.namaUser,
    required this.pendingRequests,
    required this.idJurusan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang,',
            style: TextStyle(color: Colors.indigo.shade200, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            namaUser,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Tim Penjadwalan · Semester Genap 2025/2026',
            style: TextStyle(color: Colors.indigo.shade300, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              BannerButton(
                label: 'Input Jadwal',
                icon: Icons.add,
                bgColor: const Color(0xFFFACC15),
                textColor: const Color(0xFF312E81),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ScheduleIndexPage(idJurusan: idJurusan),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              BannerButton(
                label: 'Kelola Request',
                icon: Icons.inbox,
                bgColor: Colors.white.withOpacity(0.15),
                textColor: Colors.white,
                badge: pendingRequests > 0 ? '$pendingRequests' : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RequestsIndexPage(idJurusan: idJurusan),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
