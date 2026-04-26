import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'stat_card.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';

class StatsGrid extends StatelessWidget {
  final ScheduleController ctrl;

  const StatsGrid({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        StatCard(
          label: 'Total Jadwal',
          value: ctrl.total,
          accent: AppColors.slate400,
        ),
        StatCard(
          label: 'Draft',
          value: ctrl.countDraft,
          accent: AppColors.slate400,
        ),
        StatCard(
          label: 'Final',
          value: ctrl.countFinal,
          accent: AppColors.yellow700,
        ),
        StatCard(
          label: 'Published',
          value: ctrl.countPublished,
          accent: AppColors.emerald700,
        ),
      ],
    );
  }
}
