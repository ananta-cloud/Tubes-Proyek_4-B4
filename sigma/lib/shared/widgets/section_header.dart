import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const SectionHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    ],
  );
}
