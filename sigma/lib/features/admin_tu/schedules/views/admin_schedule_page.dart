import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_schedule_viewmodel.dart';
import '../models/schedule_model.dart';

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

                  // ── Section title ──
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
                          const Text(
                            'Daftar Jadwal Kuliah',
                            style: TextStyle(
                              color: SigmaColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
                          (context, i) => _ScheduleCard(
                            schedule: vm.schedules[i],
                            onPublish: () =>
                                vm.publishSchedule(vm.schedules[i].id),
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
                _StatusBadge(isPublished: isPublished),
              ],
            ),
            const SizedBox(height: 6),

            // Dosen
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.namaDosen,
                  style: const TextStyle(
                    color: SigmaColors.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Waktu & ruangan
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  '${schedule.hari}, ${schedule.jamMulai}–${schedule.jamSelesai}',
                  style: const TextStyle(
                    color: SigmaColors.textSub,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.room_outlined,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.ruangan,
                  style: const TextStyle(
                    color: SigmaColors.textSub,
                    fontSize: 12,
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

// ─── Logout Button ────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: panggil logout dari AuthViewModel
        Navigator.of(context).popUntil((r) => r.isFirst);
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
