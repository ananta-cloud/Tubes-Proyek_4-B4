import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';

class SyncIndicatorBadge extends StatelessWidget {
  const SyncIndicatorBadge({
    super.key,
    required this.isPending,
    this.large = false,
  });

  final bool isPending;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (large) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPending ? const Color(0xFFFFF3CD) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPending ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              size: 13,
              color: isPending ? const Color(0xFFB45309) : AppColors.success,
            ),
            const SizedBox(width: 5),
            Text(
              isPending ? 'Tersimpan lokal' : 'Tersimpan di server',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPending ? const Color(0xFFB45309) : AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Tooltip(
      message: isPending ? 'Belum terkirim ke server' : 'Sudah di server',
      child: Icon(
        isPending ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
        size: 14,
        color: isPending ? const Color(0xFFB45309) : AppColors.success,
      ),
    );
  }
}
