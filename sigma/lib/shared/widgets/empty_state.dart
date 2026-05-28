import 'package:flutter/material.dart';
import '../app_colors.dart';

class SharedEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? sub;

  const SharedEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.sub,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.slate300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              style: TextStyle(color: AppColors.slate400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}
