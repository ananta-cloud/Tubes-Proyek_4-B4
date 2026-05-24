import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../admin_tu/main/views/admin_main_page.dart';
import '../viewmodels/admin_announcement_viewmodel.dart';
import 'create_announcement_page.dart';
import 'package:sigma/data/models/announcement_model.dart';
import 'admin_announcement_detail_page.dart';

class AdminAnnouncementPage extends StatefulWidget {
  const AdminAnnouncementPage({super.key});

  @override
  State<AdminAnnouncementPage> createState() => _AdminAnnouncementPageState();
}

class _AdminAnnouncementPageState extends State<AdminAnnouncementPage> {
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAnnouncementViewModel>().init();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) context.read<AdminAnnouncementViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminAnnouncementViewModel>();

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          // ── Header ──
          SigmaPageHeader(title: 'Pengumuman'),

          //  Sync status banner
          _SyncStatusBanner(
            status: vm.syncStatus,
            pendingCount: vm.pendingAnnouncementCount,
          ),

          Expanded(
            child: RefreshIndicator(
              color: SigmaColors.navy,
              onRefresh: () => vm.init(),
              child: CustomScrollView(
                slivers: [
                  // ── Stat Cards ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: SigmaStatCard(
                              label: 'TOTAL',
                              value: '${vm.announcements.length}',
                              sublabel: 'Semua pengumuman',
                              accentColor: SigmaColors.navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SigmaStatCard(
                              label: 'BULAN INI',
                              value: '${vm.thisMonthCount}',
                              sublabel: 'Diterbitkan bulan ini',
                              accentColor: SigmaColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Section title + tombol buat ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.campaign_rounded,
                            color: SigmaColors.navy,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Daftar Pengumuman',
                              style: TextStyle(
                                color: SigmaColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SigmaPrimaryButton(
                            label: 'Buat',
                            icon: Icons.add_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateAnnouncementPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ──
                  if (vm.isLoading && vm.announcements.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: SigmaColors.navy,
                        ),
                      ),
                    )
                  else if (vm.announcements.isEmpty)
                    SliverFillRemaining(
                      child: SigmaEmptyState(
                        icon: Icons.campaign_outlined,
                        message: 'Belum ada pengumuman diterbitkan.',
                        sub: 'Buat pengumuman pertama →',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final item = vm.announcements[i];
                          final isPending = vm.isAnnouncementPending(item.id);
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminAnnouncementDetailPage(
                                  announcement: item,
                                ),
                              ),
                            ),
                            child: _AnnouncementCard(
                              item: item,
                              isPending: isPending,
                            ),
                          );
                        }, childCount: vm.announcements.length),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sync Status Banner
// ─────────────────────────────────────────────────────────────────────────────
class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.status, required this.pendingCount});

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
        '$pendingCount pengumuman tersimpan lokal — belum terkirim ke server',
      ),
      SyncStatus.syncing => (
        SigmaColors.navy.withValues(alpha: 0.08),
        SigmaColors.navy,
        Icons.sync_rounded,
        'Mengirim $pendingCount pengumuman ke server...',
      ),
      SyncStatus.synced => (
        const Color(0xFFE8F5E9),
        SigmaColors.success,
        Icons.cloud_done_rounded,
        'Semua pengumuman berhasil tersimpan ke server',
      ),
      SyncStatus.failed => (
        SigmaColors.danger.withValues(alpha: 0.08),
        SigmaColors.danger,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Announcement Card — dengan indikator sync
// ─────────────────────────────────────────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item, required this.isPending});

  final AnnouncementModel item;
  final bool isPending;

  static const _kategoriColors = <String, Color>{
    'Akademik': SigmaColors.navy,
    'Beasiswa': SigmaColors.success,
    'Lomba': Color(0xFFF59E0B),
    'UKM': Color(0xFF8B5CF6),
    'Karir': Color(0xFF0EA5E9),
    'Penelitian': Color(0xFF059669),
    'Pengabdian': Color(0xFFD97706),
    'Pengajaran': Color(0xFF7C3AED),
  };

  @override
  Widget build(BuildContext context) {
    final kategori = item.kategori.isNotEmpty ? item.kategori.first : 'Umum';
    final color = _kategoriColors[kategori] ?? SigmaColors.accent;
    final tanggal = DateFormat('d MMM yyyy', 'id_ID').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SigmaColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          //  Border berbeda untuk item pending
          color: isPending
              ? const Color(0xFFB45309).withValues(alpha: 0.3)
              : SigmaColors.cardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul + badge kategori
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.judul,
                    style: const TextStyle(
                      color: SigmaColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    kategori,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            // Kategori tambahan
            if (item.kategori.length > 1) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: item.kategori.skip(1).map((k) {
                  final c = _kategoriColors[k] ?? SigmaColors.accent;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      k,
                      style: TextStyle(
                        color: c,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 6),

            // Preview isi
            Text(
              item.isi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SigmaColors.textSub,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: SigmaColors.cardBorder, height: 1),
            const SizedBox(height: 10),

            // Footer: target + tanggal + sync indicator
            Row(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  item.targetAudience,
                  style: const TextStyle(
                    color: SigmaColors.textSub,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),

                //  Sync indicator di footer card
                Tooltip(
                  message: isPending
                      ? 'Belum terkirim ke server'
                      : 'Sudah di server',
                  child: Icon(
                    isPending
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    size: 13,
                    color: isPending
                        ? const Color(0xFFB45309)
                        : SigmaColors.success,
                  ),
                ),
                const SizedBox(width: 8),

                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  tanggal,
                  style: const TextStyle(
                    color: SigmaColors.textSub,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
