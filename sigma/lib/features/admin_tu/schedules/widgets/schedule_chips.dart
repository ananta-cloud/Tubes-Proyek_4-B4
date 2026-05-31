import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';

class KelasChip extends StatelessWidget {
  const KelasChip(this.kelas, {super.key});
  final String kelas;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      kelas,
      style: const TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class KodeMkChip extends StatelessWidget {
  const KodeMkChip(this.kode, {super.key});
  final String kode;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.bgPage,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Text(
      kode,
      style: const TextStyle(
        color: AppColors.textSub,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    ),
  );
}

class TePrChip extends StatelessWidget {
  const TePrChip(this.tePr, {super.key});
  final String tePr;

  @override
  Widget build(BuildContext context) {
    final isTE = tePr.toUpperCase() == 'TE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTE
            ? const Color(0xFFFFF3E0)
            : AppColors.navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tePr.isEmpty ? '–' : tePr.toUpperCase(),
        style: TextStyle(
          color: isTE ? const Color(0xFFE65100) : AppColors.navy,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FilterLabel extends StatelessWidget {
  const FilterLabel({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.textSub),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textSub,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class ChipGroup extends StatelessWidget {
  const ChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onTap,
    this.displayMap,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String) onTap;
  final Map<String, String>? displayMap;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: options.map((opt) {
      final isActive = selected.contains(opt);
      final label = displayMap?[opt] ?? opt;
      return GestureDetector(
        onTap: () => onTap(opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.navy : AppColors.bgPage,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isActive ? AppColors.navy : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.white : AppColors.textSub,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      );
    }).toList(),
  );
}
