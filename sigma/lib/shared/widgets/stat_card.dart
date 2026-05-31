import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Untuk TPJ
class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;

  const StatCard({
    super.key,
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

/// Untuk Admin
class DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color accentColor;

  const DetailStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sublabel,
    this.accentColor = const Color(0xFF1E2A6E),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: accentColor, width: 3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accentColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          style: TextStyle(color: AppColors.textSub, fontSize: 11),
        ),
      ],
    ),
  );
}
