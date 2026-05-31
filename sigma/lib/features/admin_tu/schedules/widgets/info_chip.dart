import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';

class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: AppColors.success, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
