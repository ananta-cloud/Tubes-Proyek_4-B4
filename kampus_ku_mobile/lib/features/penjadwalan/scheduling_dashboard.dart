import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
import 'package:kampus_ku_mobile/data/models/schedule_local_model.dart';
import 'schedules/index_page.dart';
import 'requests/request_page.dart';
import '../../../data/repositories/auth_repository.dart';

class ScheduleDashboard extends StatefulWidget {
  final String idJurusan;
  final String namaUser;

  const ScheduleDashboard({
    super.key,
    required this.idJurusan,
    required this.namaUser,
  });

  @override
  State<ScheduleDashboard> createState() => _ScheduleDashboardState();
}

class _ScheduleDashboardState extends State<ScheduleDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleController>().loadDashboard(widget.idJurusan);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScheduleController>();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: RefreshIndicator(
        onRefresh: () => ctrl.loadDashboard(widget.idJurusan),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.indigo900,
              flexibleSpace: FlexibleSpaceBar(
                background: _WelcomeBanner(
                  namaUser: widget.namaUser,
                  pendingRequests: ctrl.pendingRequests,
                  idJurusan: widget.idJurusan,
                ),
              ),
              title: const Text(
                'Dashboard Penjadwalan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Cards ──────────────────────────
                  _buildStatsGrid(ctrl),
                  const SizedBox(height: 16),

                  // ── Progress Bar ─────────────────────────
                  if (ctrl.total > 0) ...[
                    _buildProgressBar(ctrl),
                    const SizedBox(height: 16),
                  ],

                  // ── Pending Request Banner ────────────────
                  if (ctrl.pendingRequests > 0) ...[
                    _PendingRequestBanner(
                      count: ctrl.pendingRequests,
                      idJurusan: widget.idJurusan,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Recent Schedules ──────────────────────
                  _buildRecentSchedules(ctrl),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Grid ────────────────────────────────────────────
  Widget _buildStatsGrid(ScheduleController ctrl) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: 'Total Jadwal',
          value: ctrl.total,
          accent: AppColors.slate400,
        ),
        _StatCard(
          label: 'Draft',
          value: ctrl.countDraft,
          accent: AppColors.slate400,
        ),
        _StatCard(
          label: 'Final',
          value: ctrl.countFinal,
          accent: AppColors.yellow700,
        ),
        _StatCard(
          label: 'Published',
          value: ctrl.countPublished,
          accent: AppColors.emerald700,
        ),
      ],
    );
  }

  // ── Progress Bar ──────────────────────────────────────────
  Widget _buildProgressBar(ScheduleController ctrl) {
    final t = ctrl.total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Publikasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${((ctrl.countPublished / t) * 100).round()}% Published',
                style: TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (ctrl.countDraft > 0)
                  Flexible(
                    flex: ctrl.countDraft,
                    child: Container(height: 10, color: AppColors.slate400),
                  ),
                if (ctrl.countFinal > 0)
                  Flexible(
                    flex: ctrl.countFinal,
                    child: Container(
                      height: 10,
                      color: const Color(0xFFFACC15),
                    ),
                  ),
                if (ctrl.countPublished > 0)
                  Flexible(
                    flex: ctrl.countPublished,
                    child: Container(height: 10, color: AppColors.emerald700),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.slate400, label: 'Draft'),
              const SizedBox(width: 12),
              _LegendDot(color: const Color(0xFFFACC15), label: 'Final'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.emerald700, label: 'Published'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent Schedules ──────────────────────────────────────
  Widget _buildRecentSchedules(ScheduleController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.indigo700,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Jadwal Terbaru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ScheduleIndexPage(idJurusan: widget.idJurusan),
                    ),
                  ),
                  child: Text(
                    'Lihat Semua →',
                    style: TextStyle(
                      color: AppColors.indigo700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (ctrl.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (ctrl.recentSchedules.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada jadwal.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...ctrl.recentSchedules.map(
              (jadwal) => _ScheduleListTile(jadwal: jadwal),
            ),
        ],
      ),
    );
  }
}

// ── Welcome Banner ─────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String namaUser;
  final int pendingRequests;
  final String idJurusan;

  const _WelcomeBanner({
    required this.namaUser,
    required this.pendingRequests,
    required this.idJurusan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang,',
            style: TextStyle(color: Colors.indigo.shade200, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            namaUser,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Tim Penjadwalan · Semester Genap 2025/2026',
            style: TextStyle(color: Colors.indigo.shade300, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BannerButton(
                label: 'Input Jadwal',
                icon: Icons.add,
                bgColor: const Color(0xFFFACC15),
                textColor: const Color(0xFF312E81),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleIndexPage(idJurusan: idJurusan),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _BannerButton(
                label: 'Kelola Request',
                icon: Icons.inbox,
                bgColor: Colors.white.withOpacity(0.15),
                textColor: Colors.white,
                badge: pendingRequests > 0 ? '$pendingRequests' : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestsIndexPage(idJurusan: idJurusan),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.slate500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _PendingRequestBanner extends StatelessWidget {
  final int count;
  final String idJurusan;
  const _PendingRequestBanner({required this.count, required this.idJurusan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Request Menunggu',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                const Text(
                  'Dosen mengajukan perubahan jadwal.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestsIndexPage(idJurusan: idJurusan),
              ),
            ),
            child: const Text(
              'Kelola →',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final String? badge;
  final VoidCallback onTap;

  const _BannerButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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

class _ScheduleListTile extends StatelessWidget {
  final ScheduleLocalModel jadwal;
  const _ScheduleListTile({required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal.namaMk,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jadwal.dosen,
                  style: TextStyle(fontSize: 11, color: AppColors.slate500),
                ),
                Text(
                  '${jadwal.hari}, ${jadwal.jamMulai}–${jadwal.jamSelesai} · ${jadwal.ruangan}',
                  style: TextStyle(fontSize: 11, color: AppColors.slate400),
                ),
              ],
            ),
          ),
          _StatusBadge(status: jadwal.status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text, border;
    switch (status) {
      case 'FINAL':
        bg = AppColors.yellow100;
        text = AppColors.yellow700;
        border = AppColors.yellow200;
        break;
      case 'PUBLISHED':
        bg = AppColors.emerald100;
        text = AppColors.emerald700;
        border = AppColors.emerald200;
        break;
      default:
        bg = AppColors.slate100;
        text = AppColors.slate600;
        border = AppColors.slate200;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
