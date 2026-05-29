import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_schedule_viewmodel.dart';
import '../../../../data/models/schedule_model.dart';
import 'import_schedule_page.dart';
import 'package:sigma/shared/app_colors.dart';
import 'package:sigma/shared/widgets/page_header.dart';
import 'package:sigma/shared/widgets/primary_button.dart';
import '../widgets/sync_status_banner.dart';
import '../widgets/sync_indicator_badge.dart';
import '../widgets/schedule_filter_panel.dart';
import '../widgets/schedule_card.dart';
import '../widgets/schedule_chips.dart';
import '../widgets/detail_row.dart';
import '../widgets/logout_button.dart';

class AdminSchedulePage extends StatefulWidget {
  const AdminSchedulePage({super.key});

  @override
  State<AdminSchedulePage> createState() => _AdminSchedulePageState();
}

class _AdminSchedulePageState extends State<AdminSchedulePage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final Set<String> _filterKelas = {};
  final Set<String> _filterHari = {};
  final Set<String> _filterTePr = {};
  final Set<String> _filterSync = {};

  bool _filterExpanded = false;

  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  static const _hariOrder = [
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    'JUMAT',
    'SABTU',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminScheduleViewModel>().fetchSchedules();
      _startAutoRefresh();
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) context.read<AdminScheduleViewModel>().fetchSchedules();
    });
  }

  int get _activeFilterCount =>
      (_searchQuery.isNotEmpty ? 1 : 0) +
      _filterKelas.length +
      _filterHari.length +
      _filterTePr.length +
      _filterSync.length;

  void _resetFilters() => setState(() {
    _searchCtrl.clear();
    _searchQuery = '';
    _filterKelas.clear();
    _filterHari.clear();
    _filterTePr.clear();
    _filterSync.clear();
  });

  void _toggle(Set<String> set, String value) =>
      setState(() => set.contains(value) ? set.remove(value) : set.add(value));

  List<ScheduleModel> _applyFilters(
    List<ScheduleModel> all,
    Set<String> pendingIds,
  ) {
    return all.where((s) {
      if (_filterKelas.isNotEmpty && !_filterKelas.contains(s.kelas)) {
        return false;
      }
      if (_filterHari.isNotEmpty && !_filterHari.contains(s.hari.toUpperCase()))
        return false;
      if (_filterTePr.isNotEmpty && !_filterTePr.contains(s.tePr.toUpperCase()))
        return false;
      if (_filterSync.isNotEmpty) {
        final isLocal = pendingIds.contains(s.id);
        if (_filterSync.contains('LOCAL') && !isLocal) return false;
        if (_filterSync.contains('SERVER') && isLocal) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        return s.namaMatkul.toLowerCase().contains(q) ||
            s.namaDosen.toLowerCase().contains(q) ||
            s.kodeMk.toLowerCase().contains(q) ||
            s.kelas.toLowerCase().contains(q) ||
            s.ruangan.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminScheduleViewModel>();
    final pendingIds = vm.pendingIds;
    final schedules = _applyFilters(vm.schedules, pendingIds);

    final allKelas =
        vm.schedules
            .map((s) => s.kelas)
            .where((k) => k.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final allHari = _hariOrder
        .where((h) => vm.schedules.any((s) => s.hari.toUpperCase() == h))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          PageHeader(title: 'Kelola Jadwal', action: const LogoutButton()),

          ScheduleSyncStatusBanner(
            status: vm.syncStatus,
            pendingCount: vm.pendingScheduleCount,
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.navy,
              onRefresh: () => vm.fetchSchedules(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          SigmaStatCard(
                            label: 'TOTAL JADWAL',
                            value: '${vm.schedules.length}',
                            sublabel: 'Semester Genap 2025/2026',
                          ),
                          const SizedBox(width: 12),
                          SigmaStatCard(
                            label: 'KELAS',
                            value: '${allKelas.length}',
                            sublabel: 'kelas terdaftar',
                            accentColor: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: ScheduleFilterPanel(
                        expanded: _filterExpanded,
                        onToggleExpand: () =>
                            setState(() => _filterExpanded = !_filterExpanded),
                        activeCount: _activeFilterCount,
                        onReset: _activeFilterCount > 0 ? _resetFilters : null,
                        searchCtrl: _searchCtrl,
                        allKelas: allKelas,
                        filterKelas: _filterKelas,
                        onToggleKelas: (v) => _toggle(_filterKelas, v),
                        allHari: allHari,
                        filterHari: _filterHari,
                        onToggleHari: (v) => _toggle(_filterHari, v),
                        filterTePr: _filterTePr,
                        onToggleTePr: (v) => _toggle(_filterTePr, v),
                        filterSync: _filterSync,
                        onToggleSync: (v) => _toggle(_filterSync, v),
                        hasPendingSchedules: pendingIds.isNotEmpty,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            color: AppColors.navy,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Daftar Jadwal',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${schedules.length} jadwal',
                            style: const TextStyle(
                              color: AppColors.textSub,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          PrimaryButton(
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
                  if (vm.isLoading && vm.schedules.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.navy),
                      ),
                    )
                  else if (schedules.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                vm.schedules.isEmpty
                                    ? Icons.calendar_today_outlined
                                    : Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.cardBorder,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                vm.schedules.isEmpty
                                    ? 'Belum ada data jadwal.\nTap "Import" untuk mengunggah.'
                                    : 'Tidak ada jadwal yang cocok\ndengan filter yang dipilih.',
                                style: const TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final s = schedules[i];
                          final isPending = pendingIds.contains(s.id);
                          return GestureDetector(
                            onTap: () => _showDetail(context, s, isPending),
                            child: ScheduleCard(
                              schedule: s,
                              isPending: isPending,
                            ),
                          );
                        }, childCount: schedules.length),
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

  void _showDetail(BuildContext ctx, ScheduleModel s, bool isPending) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (s.kelas.isNotEmpty) KelasChip(s.kelas),
                if (s.kelas.isNotEmpty) const SizedBox(width: 8),
                if (s.kodeMk.isNotEmpty) KodeMkChip(s.kodeMk),
                const Spacer(),
                TePrChip(s.tePr),
              ],
            ),
            const SizedBox(height: 8),
            SyncIndicatorBadge(isPending: isPending, large: true),
            const SizedBox(height: 8),
            Text(
              s.namaMatkul,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 12),
            DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Dosen',
              value: s.namaDosen.replaceAll(';', '\n'),
            ),
            const SizedBox(height: 10),
            DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Hari',
              value: _capitalizeFirst(s.hari),
            ),
            const SizedBox(height: 10),
            DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Jam',
              value:
                  '${s.jamMulai} – ${s.jamSelesai}'
                  '${s.jamKe > 0 ? '  (Jam ke-${s.jamKe})' : ''}',
            ),
            const SizedBox(height: 10),
            DetailRow(
              icon: Icons.room_outlined,
              label: 'Ruangan',
              value: s.ruangan,
            ),
            const SizedBox(height: 10),
            DetailRow(
              icon: Icons.school_outlined,
              label: 'Semester',
              value: '${_capitalizeFirst(s.semester)} ${s.tahunAkademik}',
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalizeFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
