import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;

  const EmptyState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 48, color: AppColors.slate300),
          const SizedBox(height: 12),
          Text(
            'Belum ada jadwal',
            style: TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Input Jadwal Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
