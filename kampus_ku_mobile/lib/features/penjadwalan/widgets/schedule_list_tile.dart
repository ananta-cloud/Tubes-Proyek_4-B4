import 'package:flutter/material.dart';
import '../../../../data/models/schedule_local_model.dart';
import 'status_badge.dart';
import '../../../../theme/app_colors.dart';

class ScheduleListTile extends StatelessWidget {
  final ScheduleLocalModel jadwal;

  const ScheduleListTile({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal.namaMk,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jadwal.dosen,
                  style: TextStyle(fontSize: 11, color: AppColors.slate500),
                ),
                Text(
                  '${jadwal.hari}, ${jadwal.jamMulai}–${jadwal.jamSelesai} · ${jadwal.ruangan}',
                  style: TextStyle(fontSize: 11, color: AppColors.slate400),
                ),
              ],
            ),
          ),
          StatusBadge(status: jadwal.status),
        ],
      ),
    );
  }
}
