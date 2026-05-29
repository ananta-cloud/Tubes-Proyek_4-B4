import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';
import '../models/schedule_model.dart';
import 'schedule_chips.dart';
import 'sync_indicator_badge.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.isPending,
  });

  final ScheduleModel schedule;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final dosenDisplay = schedule.namaDosen.replaceAll(';', ', ');
    final isMultiDosen = schedule.namaDosen.contains(';');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xFFB45309).withValues(alpha: 0.3)
              : AppColors.cardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (schedule.kelas.isNotEmpty) ...[
                  KelasChip(schedule.kelas),
                  const SizedBox(width: 6),
                ],
                if (schedule.kodeMk.isNotEmpty) KodeMkChip(schedule.kodeMk),
                const Spacer(),
                TePrChip(schedule.tePr),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              schedule.namaMatkul,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isMultiDosen
                      ? Icons.group_outlined
                      : Icons.person_outline_rounded,
                  size: 13,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dosenDisplay,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_capitalizeFirst(schedule.hari)}, '
                  '${schedule.jamMulai}–${schedule.jamSelesai}',
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 12,
                  ),
                ),
                if (schedule.jamKe > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgPage,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Jam ke-${schedule.jamKe}',
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.room_outlined,
                  size: 13,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    schedule.ruangan,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SyncIndicatorBadge(isPending: isPending),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalizeFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
