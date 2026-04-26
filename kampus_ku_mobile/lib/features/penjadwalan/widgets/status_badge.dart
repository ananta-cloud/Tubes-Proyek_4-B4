import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;

    switch (status) {
      case 'FINAL':
        bg = AppColors.yellow100;
        text = AppColors.yellow700;
        break;
      case 'PUBLISHED':
        bg = AppColors.emerald100;
        text = AppColors.emerald700;
        break;
      default:
        bg = AppColors.slate100;
        text = AppColors.slate600;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: bg),
      child: Text(status, style: TextStyle(color: text)),
    );
  }
}
