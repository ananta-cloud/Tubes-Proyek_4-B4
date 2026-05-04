import 'package:flutter/material.dart';
import 'package:sigma/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    switch (status) {
      case 'APPROVED':
        bg = AppColors.emerald100;
        text = AppColors.emerald700;
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEE2E2);
        text = Colors.red;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
