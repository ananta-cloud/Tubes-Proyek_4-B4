import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';
import '../viewmodels/admin_schedule_viewmodel.dart';

class ScheduleSyncStatusBanner extends StatelessWidget {
  const ScheduleSyncStatusBanner({
    super.key,
    required this.status,
    required this.pendingCount,
  });

  final SyncStatus status;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.idle) return const SizedBox.shrink();

    final (Color bg, Color fg, IconData icon, String text) = switch (status) {
      SyncStatus.pending => (
        const Color(0xFFFFF3CD),
        const Color(0xFFB45309),
        Icons.cloud_off_rounded,
        '$pendingCount jadwal tersimpan lokal — belum terkirim ke server',
      ),
      SyncStatus.syncing => (
        AppColors.navy.withValues(alpha: 0.08),
        AppColors.navy,
        Icons.sync_rounded,
        'Mengirim $pendingCount jadwal ke server...',
      ),
      SyncStatus.synced => (
        const Color(0xFFE8F5E9),
        AppColors.success,
        Icons.cloud_done_rounded,
        'Semua jadwal berhasil tersimpan ke server',
      ),
      SyncStatus.failed => (
        AppColors.danger.withValues(alpha: 0.08),
        AppColors.danger,
        Icons.cloud_off_rounded,
        'Gagal mengirim ke server — akan dicoba ulang saat online',
      ),
      SyncStatus.idle => (
        Colors.transparent,
        Colors.transparent,
        Icons.check,
        '',
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bg,
      child: Row(
        children: [
          status == SyncStatus.syncing
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Icon(icon, color: fg, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
