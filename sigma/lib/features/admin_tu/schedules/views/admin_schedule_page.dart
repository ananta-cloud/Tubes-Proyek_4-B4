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
  // ── Filter state ──────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final Set<String> _filterKelas = {};
  final Set<String> _filterHari = {};
  final Set<String> _filterTePr = {};

  bool _filterExpanded = true;

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
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount =>
      (_searchQuery.isNotEmpty ? 1 : 0) +
      _filterKelas.length +
      _filterHari.length +
      _filterTePr.length;

  void _resetFilters() => setState(() {
    _searchCtrl.clear();
    _searchQuery = '';
    _filterKelas.clear();
    _filterHari.clear();
    _filterTePr.clear();
  });

  void _toggle(Set<String> set, String value) =>
      setState(() => set.contains(value) ? set.remove(value) : set.add(value));

  List<ScheduleModel> _applyFilters(List<ScheduleModel> all) {
    return all.where((s) {
      if (_filterKelas.isNotEmpty && !_filterKelas.contains(s.kelas)) {
        return false;
      }
      if (_filterHari.isNotEmpty && !_filterHari.contains(s.hari.toUpperCase()))
        return false;
      if (_filterTePr.isNotEmpty && !_filterTePr.contains(s.tePr.toUpperCase()))
        return false;
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
    final schedules = _applyFilters(vm.schedules);

    // Opsi filter dinamis dari data yang ada
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
          // ── Header ──
          SigmaPageHeader(title: 'Kelola Jadwal', action: _LogoutButton()),

          Expanded(
            child: RefreshIndicator(
              color: SigmaColors.navy,
              onRefresh: () => vm.fetchSchedules(),
              child: CustomScrollView(
                slivers: [
                  // ── Stat — hanya total ──
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
                      ),
                    ),
                  ),

                  // ── List header ──
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
                  if (vm.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: SigmaColors.navy,
                        ),
                      ),
                    )
                  else if (schedules.isEmpty)
                    SliverFillRemaining(
                      child: SigmaEmptyState(
                        icon: vm.schedules.isEmpty
                            ? Icons.calendar_today_outlined
                            : Icons.search_off_rounded,
                        message: vm.schedules.isEmpty
                            ? 'Belum ada data jadwal.\nTap "Import" untuk mengunggah.'
                            : 'Tidak ada jadwal yang cocok\ndengan filter yang dipilih.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => GestureDetector(
                            onTap: () => _showDetail(context, schedules[i]),
                            child: _ScheduleCard(schedule: schedules[i]),
                          ),
                          childCount: schedules.length,
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

  // ── Bottom sheet detail ───────────────────────────────────────────────────
  void _showDetail(BuildContext context, ScheduleModel s) {
    showModalBottomSheet(
      context: context,
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

            // Kelas chip + kode MK
            Row(
              children: [
                if (s.kelas.isNotEmpty) _KelasChip(s.kelas),
                if (s.kelas.isNotEmpty) const SizedBox(width: 8),
                if (s.kodeMk.isNotEmpty) _KodeMkChip(s.kodeMk),
                const Spacer(),
                _TePrChip(s.tePr),
              ],
            ),
            const SizedBox(height: 10),

            // Nama MK
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
          // ── Header filter (selalu tampil) ──
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

          // ── Isi filter (collapsible) ──
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
                      displayMap: {
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

                  // Tipe (TE / PR)
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
//  Schedule Card — info lengkap, tanpa status publish
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});
  final ScheduleModel schedule;

  @override
  Widget build(BuildContext context) {
    final dosenDisplay = schedule.namaDosen.replaceAll(';', ', ');
    final isMultiDosen = schedule.namaDosen.contains(';');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris atas: kelas + kode MK + tePr chip ──
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

            // ── Nama MK ──
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

            // ── Dosen (icon users jika multi) ──
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

            // ── Hari + jam ──
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

            // ── Ruangan ──
            Row(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _KelasChip extends StatelessWidget {
  const _KelasChip(this.kelas);
  final String kelas;

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class _KodeMkChip extends StatelessWidget {
  const _KodeMkChip(this.kode);
  final String kode;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  Widget build(BuildContext context) {
    return Row(
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
  Widget build(BuildContext context) {
    return Wrap(
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
  Widget build(BuildContext context) {
    return Row(
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  Logout Button
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _capitalizeFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
