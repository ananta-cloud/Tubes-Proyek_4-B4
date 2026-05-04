import 'package:flutter/material.dart';
import 'package:sigma/theme/app_colors.dart';

class TipeBadge extends StatelessWidget {
  final String tipe;
  const TipeBadge({required this.tipe});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    IconData icon;
    switch (tipe) {
      case 'PINDAH_JAM':
        bg = const Color(0xFFF5F3FF);
        text = const Color(0xFF6D28D9);
        icon = Icons.access_time;
        break;
      case 'PINDAH_RUANGAN':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        icon = Icons.room;
        break;
      case 'KEDUANYA':
        bg = const Color(0xFFFFF7ED);
        text = const Color(0xFFC2410C);
        icon = Icons.swap_horiz;
        break;
      default:
        bg = AppColors.slate100;
        text = AppColors.slate600;
        icon = Icons.edit;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 4),
          Text(
            tipe.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
