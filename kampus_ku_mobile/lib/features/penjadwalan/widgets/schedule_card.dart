import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../data/models/schedule_local_model.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
import '../schedules/edit_page.dart';
import 'action_btn.dart';
import 'status_badge.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleLocalModel jadwal;
  final String role;
  final String idJurusan;

  const ScheduleCard({
    super.key,
    required this.jadwal,
    required this.role,
    required this.idJurusan,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ScheduleController>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jadwal.namaMk,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              StatusBadge(status: jadwal.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            jadwal.dosen,
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),

          const SizedBox(height: 8),
          Divider(color: AppColors.slate100),
          const SizedBox(height: 8),

          Text(
            '${jadwal.hari}, ${jadwal.jamMulai}–${jadwal.jamSelesai} · ${jadwal.ruangan}',
            style: TextStyle(fontSize: 12, color: AppColors.slate700),
          ),

          const SizedBox(height: 10),

          if (role == 'TIM_PENJADWALAN' && jadwal.status == 'DRAFT')
            ActionBtn(
              label: 'Edit',
              icon: Icons.edit,
              color: AppColors.indigo700,
              bg: const Color(0xFFEEF2FF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScheduleEditPage(jadwal: jadwal, idJurusan: idJurusan),
                ),
              ).then((_) => ctrl.loadSchedules(idJurusan)),
            ),
        ],
      ),
    );
  }
}
