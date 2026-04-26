import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'legend_dot.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';

class ProgressBar extends StatelessWidget {
  final ScheduleController ctrl;

  const ProgressBar({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final t = ctrl.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Publikasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${((ctrl.countPublished / t) * 100).round()}% Published',
                style: TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (ctrl.countDraft > 0)
                  Flexible(
                    flex: ctrl.countDraft,
                    child: Container(height: 10, color: AppColors.slate400),
                  ),
                if (ctrl.countFinal > 0)
                  Flexible(
                    flex: ctrl.countFinal,
                    child: Container(
                      height: 10,
                      color: const Color(0xFFFACC15),
                    ),
                  ),
                if (ctrl.countPublished > 0)
                  Flexible(
                    flex: ctrl.countPublished,
                    child: Container(height: 10, color: AppColors.emerald700),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              LegendDot(color: AppColors.slate400, label: 'Draft'),
              SizedBox(width: 12),
              LegendDot(color: Color(0xFFFACC15), label: 'Final'),
              SizedBox(width: 12),
              LegendDot(color: AppColors.emerald700, label: 'Published'),
            ],
          ),
        ],
      ),
    );
  }
}
