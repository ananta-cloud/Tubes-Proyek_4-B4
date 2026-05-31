import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.textSub),
      const SizedBox(width: 10),
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
