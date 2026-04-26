// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Import AppColors

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status.toUpperCase()) {
      case 'FINAL':
        bgColor = AppColors.yellow100;
        textColor = AppColors.yellow700;
        borderColor = AppColors.yellow200;
        break;
      case 'PUBLISHED':
        bgColor = AppColors.emerald100;
        textColor = AppColors.emerald700;
        borderColor = AppColors.emerald200;
        break;
      default: // DRAFT
        bgColor = AppColors.slate100;
        textColor = AppColors.slate600;
        borderColor = AppColors.slate200;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
