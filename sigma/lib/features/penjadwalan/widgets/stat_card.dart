import 'package:flutter/material.dart';
import 'package:sigma/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;
  const StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.slate50,
      borderRadius: BorderRadius.circular(10),
      border: Border(left: BorderSide(color: accent, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.slate500,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
