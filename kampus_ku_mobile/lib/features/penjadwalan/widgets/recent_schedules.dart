import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'schedule_list_tile.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
import '../schedules/index_page.dart';

class RecentSchedules extends StatelessWidget {
  final ScheduleController ctrl;
  final String idJurusan;

  const RecentSchedules({
    super.key,
    required this.ctrl,
    required this.idJurusan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.indigo700,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Jadwal Terbaru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScheduleIndexPage(idJurusan: idJurusan),
                    ),
                  ),
                  child: Text(
                    'Lihat Semua →',
                    style: TextStyle(
                      color: AppColors.indigo700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (ctrl.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (ctrl.recentSchedules.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada jadwal.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...ctrl.recentSchedules.map(
              (jadwal) => ScheduleListTile(jadwal: jadwal),
            ),
        ],
      ),
    );
  }
}
