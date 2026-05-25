import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_schedule_viewmodel.dart';
import '../../../../data/models/schedule_model.dart';
import 'import_schedule_page.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';

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
  // ✅ Filter sinkronisasi: 'LOCAL' = belum ke server, 'SERVER' = sudah
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

      // Filter sinkronisasi
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
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          SigmaPageHeader(title: 'Kelola Jadwal', action: _LogoutButton()),

          // ── Sync status banner ────────────────────────────────────────────
          _SyncStatusBanner(
            status: vm.syncStatus,
            pendingCount: vm.pendingScheduleCount,
          ),

          Expanded(
            child: RefreshIndicator(
              color: SigmaColors.navy,
              onRefresh: () => vm.fetchSchedules(),
              child: CustomScrollView(
                slivers: [
                  // ── Stat cards ──
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
                            accentColor: SigmaColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Filter Panel ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _FilterPanel(
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

                  // ── List header + Import ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            color: SigmaColors.navy,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Daftar Jadwal',
                            style: TextStyle(
                              color: SigmaColors.navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${schedules.length} jadwal',
                            style: const TextStyle(
                              color: SigmaColors.textSub,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
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
                  if (vm.isLoading && vm.schedules.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: SigmaColors.navy,
                        ),
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
                                color: SigmaColors.cardBorder,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                vm.schedules.isEmpty
                                    ? 'Belum ada data jadwal.\nTap "Import" untuk mengunggah.'
                                    : 'Tidak ada jadwal yang cocok\ndengan filter yang dipilih.',
                                style: const TextStyle(
                                  color: SigmaColors.textSub,
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
                            child: _ScheduleCard(
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
          color: SigmaColors.white,
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
                  color: SigmaColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (s.kelas.isNotEmpty) _KelasChip(s.kelas),
                if (s.kelas.isNotEmpty) const SizedBox(width: 8),
                if (s.kodeMk.isNotEmpty) _KodeMkChip(s.kodeMk),
                const Spacer(),
                _TePrChip(s.tePr),
              ],
            ),
            const SizedBox(height: 8),
            // ✅ Indikator sync di detail sheet
            _SyncIndicatorBadge(isPending: isPending, large: true),
            const SizedBox(height: 8),
            Text(
              s.namaMatkul,
              style: const TextStyle(
                color: SigmaColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: SigmaColors.cardBorder),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Dosen',
              value: s.namaDosen.replaceAll(';', '\n'),
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Hari',
              value: _capitalizeFirst(s.hari),
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Jam',
              value:
                  '${s.jamMulai} – ${s.jamSelesai}'
                  '${s.jamKe > 0 ? '  (Jam ke-${s.jamKe})' : ''}',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.room_outlined,
              label: 'Ruangan',
              value: s.ruangan,
            ),
            const SizedBox(height: 10),
            _DetailRow(
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
        // ✅ Fix: tampilkan jumlah jadwal, bukan jumlah item queue
        '$pendingCount jadwal tersimpan lokal — belum terkirim ke server',
      ),
      SyncStatus.syncing => (
        SigmaColors.navy.withValues(alpha: 0.08),
        SigmaColors.navy,
        Icons.sync_rounded,
        'Mengirim $pendingCount jadwal ke server...',
      ),
      SyncStatus.synced => (
        const Color(0xFFE8F5E9),
        SigmaColors.success,
        Icons.cloud_done_rounded,
        'Semua jadwal berhasil tersimpan ke server',
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
//  Sync Indicator Badge — kecil di sudut card, besar di bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SyncIndicatorBadge extends StatelessWidget {
  const _SyncIndicatorBadge({required this.isPending, this.large = false});

  final bool isPending;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (large) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPending ? const Color(0xFFFFF3CD) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPending ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              size: 13,
              color: isPending ? const Color(0xFFB45309) : SigmaColors.success,
            ),
            const SizedBox(width: 5),
            Text(
              isPending ? 'Tersimpan lokal' : 'Tersimpan di server',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPending
                    ? const Color(0xFFB45309)
                    : SigmaColors.success,
              ),
            ),
          ],
        ),
      );
    }

    // Versi kecil untuk sudut card
    return Tooltip(
      message: isPending ? 'Belum terkirim ke server' : 'Sudah di server',
      child: Icon(
        isPending ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
        size: 14,
        color: isPending ? const Color(0xFFB45309) : SigmaColors.success,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Filter Panel
// ─────────────────────────────────────────────────────────────────────────────
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.expanded,
    required this.onToggleExpand,
    required this.activeCount,
    required this.onReset,
    required this.searchCtrl,
    required this.allKelas,
    required this.filterKelas,
    required this.onToggleKelas,
    required this.allHari,
    required this.filterHari,
    required this.onToggleHari,
    required this.filterTePr,
    required this.onToggleTePr,
    required this.filterSync,
    required this.onToggleSync,
    required this.hasPendingSchedules,
  });

  final bool expanded;
  final VoidCallback onToggleExpand;
  final int activeCount;
  final VoidCallback? onReset;
  final TextEditingController searchCtrl;
  final List<String> allKelas;
  final Set<String> filterKelas;
  final void Function(String) onToggleKelas;
  final List<String> allHari;
  final Set<String> filterHari;
  final void Function(String) onToggleHari;
  final Set<String> filterTePr;
  final void Function(String) onToggleTePr;
  final Set<String> filterSync;
  final void Function(String) onToggleSync;
  final bool hasPendingSchedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SigmaColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SigmaColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: SigmaColors.navy,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter Jadwal',
                    style: TextStyle(
                      color: SigmaColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: SigmaColors.navy,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$activeCount aktif',
                        style: const TextStyle(
                          color: SigmaColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onReset != null)
                    GestureDetector(
                      onTap: onReset,
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: SigmaColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (onReset != null) const SizedBox(width: 10),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: SigmaColors.textSub,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(color: SigmaColors.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: SigmaColors.bgPage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SigmaColors.navy,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama MK, dosen, ruangan...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: SigmaColors.textSub,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: SigmaColors.textSub,
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kelas
                  if (allKelas.isNotEmpty) ...[
                    _FilterLabel(icon: Icons.group_outlined, label: 'Kelas'),
                    const SizedBox(height: 6),
                    _ChipGroup(
                      options: allKelas,
                      selected: filterKelas,
                      onTap: onToggleKelas,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Hari
                  if (allHari.isNotEmpty) ...[
                    _FilterLabel(
                      icon: Icons.date_range_outlined,
                      label: 'Hari',
                    ),
                    const SizedBox(height: 6),
                    _ChipGroup(
                      options: allHari,
                      selected: filterHari,
                      onTap: onToggleHari,
                      displayMap: const {
                        'SENIN': 'Senin',
                        'SELASA': 'Selasa',
                        'RABU': 'Rabu',
                        'KAMIS': 'Kamis',
                        'JUMAT': 'Jumat',
                        'SABTU': 'Sabtu',
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Tipe TE/PR
                  _FilterLabel(
                    icon: Icons.label_outline_rounded,
                    label: 'Tipe',
                  ),
                  const SizedBox(height: 6),
                  _ChipGroup(
                    options: const ['TE', 'PR'],
                    selected: filterTePr,
                    onTap: onToggleTePr,
                    displayMap: const {
                      'TE': 'Teori (TE)',
                      'PR': 'Praktik (PR)',
                    },
                  ),

                  // ✅ Filter sinkronisasi — hanya tampil jika ada jadwal pending
                  if (hasPendingSchedules) ...[
                    const SizedBox(height: 14),
                    _FilterLabel(
                      icon: Icons.cloud_outlined,
                      label: 'Status Sinkronisasi',
                    ),
                    const SizedBox(height: 6),
                    _ChipGroup(
                      options: const ['LOCAL', 'SERVER'],
                      selected: filterSync,
                      onTap: onToggleSync,
                      displayMap: const {
                        'LOCAL': '☁ Lokal saja',
                        'SERVER': '✓ Sudah di server',
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Schedule Card — dengan indikator sync di sudut kanan bawah
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.isPending});

  final ScheduleModel schedule;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final dosenDisplay = schedule.namaDosen.replaceAll(';', ', ');
    final isMultiDosen = schedule.namaDosen.contains(';');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SigmaColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // ✅ Border sedikit berbeda untuk jadwal pending
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: kelas + kode MK + TE/PR
            Row(
              children: [
                if (schedule.kelas.isNotEmpty) ...[
                  _KelasChip(schedule.kelas),
                  const SizedBox(width: 6),
                ],
                if (schedule.kodeMk.isNotEmpty) _KodeMkChip(schedule.kodeMk),
                const Spacer(),
                _TePrChip(schedule.tePr),
              ],
            ),
            const SizedBox(height: 8),

            // Nama MK
            Text(
              schedule.namaMatkul,
              style: const TextStyle(
                color: SigmaColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 6),

            // Dosen
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isMultiDosen
                      ? Icons.group_outlined
                      : Icons.person_outline_rounded,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dosenDisplay,
                    style: const TextStyle(
                      color: SigmaColors.textSub,
                      fontSize: 12,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Hari + jam
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_capitalizeFirst(schedule.hari)}, '
                  '${schedule.jamMulai}–${schedule.jamSelesai}',
                  style: const TextStyle(
                    color: SigmaColors.textSub,
                    fontSize: 12,
                  ),
                ),
                if (schedule.jamKe > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: SigmaColors.bgPage,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Jam ke-${schedule.jamKe}',
                      style: const TextStyle(
                        color: SigmaColors.textSub,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),

            // Ruangan + indikator sync di kanan bawah
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.room_outlined,
                  size: 13,
                  color: SigmaColors.textSub,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    schedule.ruangan,
                    style: const TextStyle(
                      color: SigmaColors.textSub,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ✅ Indikator kecil di sudut kanan bawah card
                _SyncIndicatorBadge(isPending: isPending),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────
class _KelasChip extends StatelessWidget {
  const _KelasChip(this.kelas);
  final String kelas;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: SigmaColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      kelas,
      style: const TextStyle(
        color: SigmaColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _KodeMkChip extends StatelessWidget {
  const _KodeMkChip(this.kode);
  final String kode;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: SigmaColors.bgPage,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: SigmaColors.cardBorder),
    ),
    child: Text(
      kode,
      style: const TextStyle(
        color: SigmaColors.textSub,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    ),
  );
}

class _TePrChip extends StatelessWidget {
  const _TePrChip(this.tePr);
  final String tePr;
  @override
  Widget build(BuildContext context) {
    final isTE = tePr.toUpperCase() == 'TE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTE
            ? const Color(0xFFFFF3E0)
            : SigmaColors.navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tePr.isEmpty ? '–' : tePr.toUpperCase(),
        style: TextStyle(
          color: isTE ? const Color(0xFFE65100) : SigmaColors.navy,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: SigmaColors.textSub),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: SigmaColors.textSub,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onTap,
    this.displayMap,
  });
  final List<String> options;
  final Set<String> selected;
  final void Function(String) onTap;
  final Map<String, String>? displayMap;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: options.map((opt) {
      final isActive = selected.contains(opt);
      final label = displayMap?[opt] ?? opt;
      return GestureDetector(
        onTap: () => onTap(opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? SigmaColors.navy : SigmaColors.bgPage,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isActive ? SigmaColors.navy : SigmaColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? SigmaColors.white : SigmaColors.textSub,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

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
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: SigmaColors.textSub),
      const SizedBox(width: 10),
      SizedBox(
        width: 80,
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

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
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
        if (confirm != true || !context.mounted) return;
        await context.read<LoginViewModel>().logout();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: SigmaColors.danger.withValues(alpha: 0.08),
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

String _capitalizeFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
