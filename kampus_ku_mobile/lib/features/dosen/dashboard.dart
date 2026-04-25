import 'package:flutter/material.dart';
import 'package:kampus_ku_mobile/features/auth/data/models/schedule_local_model.dart';

class DashboardDosen extends StatelessWidget {
  final List<ScheduleLocalModel> schedules;
  
  const DashboardDosen({super.key, required this.schedules});

  final Color primaryBlue = const Color(0xFF3F5DB3);
  final Color accentOrange = const Color(0xFFFF7A36);
  final Color darkText = const Color(0xFF1F1F3D);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          "Selamat Datang, Bapak/Ibu! 👋",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
        ),
        const SizedBox(height: 5),
        Text("Jadwal mengajar pertama hari ini jam 08:00.", style: TextStyle(color: darkText.withOpacity(0.6))),
        const SizedBox(height: 20),
        
        _schedulePreviewCard(),
        
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(child: _infoCard("Pending\nRequest", "2", Icons.pending_actions, Colors.amber)),
            const SizedBox(width: 12),
            Expanded(child: _infoCard("Total\nKelas", "4", Icons.class_, Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _infoCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 10, offset: const Offset(0, 4), color: Colors.black.withOpacity(0.05))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: darkText.withOpacity(0.6))),
            ],
          )
        ],
      ),
    );
  }

  Widget _schedulePreviewCard() {
    if (schedules.isEmpty) return const Center(child: CircularProgressIndicator());
    final s = schedules.first;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: primaryBlue, width: 4)),
        boxShadow: [BoxShadow(blurRadius: 12, offset: const Offset(0, 5), color: Colors.black.withOpacity(0.05))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.co_present, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.namaMk, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("${s.jamMulai} - ${s.jamSelesai}", style: TextStyle(color: accentOrange, fontWeight: FontWeight.w600)),
              Text("Ruang: ${s.ruangan}", style: TextStyle(color: darkText.withOpacity(0.7))),
            ],
          ),
        ],
      ),
    );
  }
}