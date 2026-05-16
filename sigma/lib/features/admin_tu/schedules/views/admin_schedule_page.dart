import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_schedule_viewmodel.dart';
import '../models/schedule_model.dart';
import 'import_schedule_page.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';

class AdminSchedulePage extends StatefulWidget {
  const AdminSchedulePage({super.key});

  @override
  State<AdminSchedulePage> createState() => _AdminSchedulePageState();
}

class _AdminSchedulePageState extends State<AdminSchedulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminScheduleViewModel>().fetchSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminScheduleViewModel>();

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          // ── Header ──
          SigmaPageHeader(title: 'Kelola Jadwal', action: _LogoutButton()),

          Expanded(
            child: RefreshIndicator(
              color: SigmaColors.navy,
              onRefresh: () => vm.fetchSchedules(),
              child: CustomScrollView(
                slivers: [
                  // ── Stat Cards ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          SigmaStatCard(
                            label: 'DRAFT',
                            value: '${vm.draftCount}',
                            sublabel: 'Belum difinalisasi',
                            accentColor: SigmaColors.textSub,
                          ),
                          const SizedBox(width: 12),
                          SigmaStatCard(
                            label: 'PUBLISHED',
                            value: '${vm.publishedCount}',
                            sublabel: 'Live di HP mahasiswa',
                            accentColor: SigmaColors.success,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Section title + tombol Import ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            color: SigmaColors.navy,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Daftar Jadwal Kuliah',
                              style: TextStyle(
                                color: SigmaColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SigmaPrimaryButton(
                            label: 'Import',
                            icon: Icons.upload_file_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ImportSchedulePage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ──
                  if (vm.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: SigmaColors.navy,
                        ),
                      ),
                    )
                  else if (vm.schedules.isEmpty)
                    SliverFillRemaining(
                      child: SigmaEmptyState(
                        icon: Icons.calendar_today_outlined,
                        message: 'Belum ada data jadwal perkuliahan.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => GestureDetector(
                            onTap: () =>
                                _showScheduleDetail(context, vm.schedules[i]),
                            child: _ScheduleCard(
                              schedule: vm.schedules[i],
                              onPublish: () =>
                                  vm.publishSchedule(vm.schedules[i].id),
                            ),
                          ),
                          childCount: vm.schedules.length,
                        ),
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

  void _showScheduleDetail(BuildContext context, ScheduleModel schedule) {
    final isPublished = schedule.status.toUpperCase() == 'PUBLISHED';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          color: SigmaColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SigmaColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: nama MK + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    schedule.namaMatkul,
                    style: const TextStyle(
                      color: SigmaColors.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(isPublished: isPublished),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: SigmaColors.cardBorder),
            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Dosen',
              value: schedule.namaDosen,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Hari & Waktu',
              value:
                  '${schedule.hari}, ${schedule.jamMulai}–${schedule.jamSelesai}',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.room_outlined,
              label: 'Ruangan',
              value: schedule.ruangan,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Status',
              value: schedule.status,
            ),

            if (!isPublished) ...[
              const SizedBox(height: 20),
              const Divider(color: SigmaColors.cardBorder),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AdminScheduleViewModel>().publishSchedule(
                      schedule.id,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: SigmaColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.publish_rounded,
                          color: SigmaColors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Publish Jadwal',
                          style: TextStyle(
                            color: SigmaColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Card ────────────────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.onPublish});

  final ScheduleModel schedule;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final isPublished = schedule.status.toUpperCase() == 'PUBLISHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SigmaColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SigmaColors.cardBorder),
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
            // Nama MK + badge status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    schedule.namaMatkul,
                    style: const TextStyle(
                      color: SigmaColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(isPublished: isPublished),
              ],
            ),
            const SizedBox(height: 6),

            // ── Dosen — Flexible agar tidak overflow ──
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    schedule.namaDosen,
                    style: const TextStyle(
                      color: SigmaColors.textSub,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Waktu & ruangan — Flexible agar tidak overflow ──
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${schedule.hari}, ${schedule.jamMulai}–${schedule.jamSelesai}',
                    style: const TextStyle(
                      color: SigmaColors.textSub,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.room_outlined,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    schedule.ruangan,
                    style: const TextStyle(
                      color: SigmaColors.textSub,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Tombol publish (hanya jika masih draft)
            if (!isPublished) ...[
              const SizedBox(height: 12),
              const Divider(color: SigmaColors.cardBorder, height: 1),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onPublish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: SigmaColors.navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.publish_rounded,
                          color: SigmaColors.white,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Publish',
                          style: TextStyle(
                            color: SigmaColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? SigmaColors.success.withOpacity(0.1)
            : SigmaColors.textSub.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isPublished ? 'PUBLISHED' : 'DRAFT',
        style: TextStyle(
          color: isPublished ? SigmaColors.success : SigmaColors.textSub,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: SigmaColors.textSub),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: SigmaColors.textSub, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: SigmaColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Konfirmasi logout
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Logout?',
              style: TextStyle(
                color: SigmaColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            content: const Text(
              'Yakin ingin keluar dari akun ini?',
              style: TextStyle(color: SigmaColors.textSub, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: SigmaColors.textSub),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: SigmaColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirm != true) return;
        if (!context.mounted) return;

        // Panggil logout dari LoginViewModel
        await context.read<LoginViewModel>().logout();

        if (!context.mounted) return;

        // Navigate ke LoginPage, hapus semua route
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: SigmaColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, color: SigmaColors.danger, size: 15),
            SizedBox(width: 5),
            Text(
              'Logout',
              style: TextStyle(
                color: SigmaColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
