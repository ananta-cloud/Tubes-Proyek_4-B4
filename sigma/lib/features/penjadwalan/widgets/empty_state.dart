import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String filter;

  const EmptyState({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 52, color: AppColors.slate300),
          const SizedBox(height: 12),
          Text(
            filter == 'SEMUA'
                ? 'Belum ada request masuk'
                : 'Tidak ada request ${filter.toLowerCase()}',
            style: TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
