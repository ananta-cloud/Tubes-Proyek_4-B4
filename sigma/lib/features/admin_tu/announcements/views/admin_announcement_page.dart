import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/announcement_viewmodel.dart';
import 'create_announcement_page.dart';
import 'package:sigma/data/models/announcement_model.dart';

class AdminAnnouncementPage extends StatefulWidget {
  const AdminAnnouncementPage({super.key});

  @override
  State<AdminAnnouncementPage> createState() => _AdminAnnouncementPageState();
}

class _AdminAnnouncementPageState extends State<AdminAnnouncementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementViewModel>().fetchAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          // ── Header ──
          SigmaPageHeader(title: 'Pengumuman'),

          Expanded(
            child: RefreshIndicator(
              color: SigmaColors.navy,
              onRefresh: () => vm.fetchAnnouncements(),
              child: CustomScrollView(
                slivers: [
                  // ── Stat Cards ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          SigmaStatCard(
                            label: 'TOTAL',
                            value: '${vm.announcements.length}',
                            sublabel: 'Semua pengumuman',
                            accentColor: SigmaColors.navy,
                          ),
                          const SizedBox(width: 12),
                          SigmaStatCard(
                            label: 'BULAN INI',
                            value: '${vm.thisMonthCount}',
                            sublabel: 'Diterbitkan bulan ini',
                            accentColor: SigmaColors.success,
                          ),
                          const SizedBox(width: 12),
                          SigmaStatCard(
                            label: 'DIBACA',
                            value: '${vm.totalRead}',
                            sublabel: 'Konfirmasi mahasiswa',
                            accentColor: SigmaColors.gold,
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
                  if (vm.isLoading)
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
                        delegate: SliverChildBuilderDelegate(
                          (context, i) =>
                              _AnnouncementCard(item: vm.announcements[i]),
                          childCount: vm.announcements.length,
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

// ─── Announcement Card ────────────────────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});
  final AnnouncementModel item;

  static const _kategoriColors = <String, Color>{
    'Akademik': SigmaColors.navy,
    'Beasiswa': SigmaColors.success,
    'Lomba': Color(0xFFF59E0B),
    'UKM': Color(0xFF8B5CF6),
    'Karir': Color(0xFF0EA5E9),
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

            // Footer: target + tanggal
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
