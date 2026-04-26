import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';

import 'widgets/welcome_banner.dart';
import 'widgets/stats_grid.dart';
import 'widgets/progress_bar.dart';
import 'widgets/pending_request_banner.dart';
import 'widgets/recent_schedules.dart';

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
                background: WelcomeBanner(
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

            // ── Content ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Grid ──────────────────────────
                  StatsGrid(ctrl: ctrl),
                  const SizedBox(height: 16),

                  // ── Progress Bar ─────────────────────────
                  if (ctrl.total > 0) ...[
                    ProgressBar(ctrl: ctrl),
                    const SizedBox(height: 16),
                  ],

                  // ── Pending Request Banner ────────────────
                  if (ctrl.pendingRequests > 0) ...[
                    PendingRequestBanner(
                      count: ctrl.pendingRequests,
                      idJurusan: widget.idJurusan,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Recent Schedules ──────────────────────
                  RecentSchedules(ctrl: ctrl, idJurusan: widget.idJurusan),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
