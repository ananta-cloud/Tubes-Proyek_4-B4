import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
