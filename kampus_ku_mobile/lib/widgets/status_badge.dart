import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Definisi warna berdasarkan logic @if di blade
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status.toUpperCase()) {
      case 'FINAL':
        bgColor = const Color(0xFFFEF9C3); // yellow-100
        textColor = const Color(0xFFA16207); // yellow-700
        borderColor = const Color(0xFFFEF08A); // yellow-200
        break;
      case 'PUBLISHED':
        bgColor = const Color(0xFFD1FAE5); // emerald-100
        textColor = const Color(0xFF047857); // emerald-700
        borderColor = const Color(0xFFA7F3D0); // emerald-200
        break;
      case 'DRAFT':
      default:
        bgColor = const Color(0xFFF1F5F9); // slate-100
        textColor = const Color(0xFF475569); // slate-600
        borderColor = const Color(0xFFE2E8F0); // slate-200
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
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
