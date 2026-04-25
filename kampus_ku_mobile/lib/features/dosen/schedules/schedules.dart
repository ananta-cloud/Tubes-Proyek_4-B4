import 'package:flutter/material.dart';
import 'package:kampus_ku_mobile/features/auth/data/models/schedule_local_model.dart';

class SchedulesDosen extends StatelessWidget {
  final List<ScheduleLocalModel> schedules;
  const SchedulesDosen({super.key, required this.schedules});

  final Color primaryBlue = const Color(0xFF3F5DB3);
  final Color darkText = const Color(0xFF1F1F3D);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text("Jadwal Mengajar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _day("Senin", "18", true),
              _day("Selasa", "19", false),
              _day("Rabu", "20", false),
              _day("Kamis", "21", false),
              _day("Jumat", "22", false),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...schedules.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border(left: BorderSide(color: primaryBlue, width: 4)),
              boxShadow: [BoxShadow(blurRadius: 12, offset: const Offset(0, 5), color: Colors.black.withOpacity(0.05))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${s.jamMulai} - ${s.jamSelesai}", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(s.namaMk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text("Ruangan: ${s.ruangan}"),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _day(String day, String date, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(color: active ? Colors.white : darkText, fontSize: 12)),
          Text(date, style: TextStyle(color: active ? Colors.white : darkText, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}