import 'package:flutter/material.dart';
import 'package:sigma/shared/app_colors.dart';
import 'schedule_chips.dart';

class ScheduleFilterPanel extends StatelessWidget {
  const ScheduleFilterPanel({
    super.key,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
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
                    color: AppColors.navy,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter Jadwal',
                    style: TextStyle(
                      color: AppColors.navy,
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
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$activeCount aktif',
                        style: const TextStyle(
                          color: AppColors.white,
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
                          color: AppColors.danger,
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
                    color: AppColors.textSub,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(color: AppColors.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgPage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.navy,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama MK, dosen, ruangan...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSub,
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (allKelas.isNotEmpty) ...[
                    const FilterLabel(
                      icon: Icons.group_outlined,
                      label: 'Kelas',
                    ),
                    const SizedBox(height: 6),
                    ChipGroup(
                      options: allKelas,
                      selected: filterKelas,
                      onTap: onToggleKelas,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (allHari.isNotEmpty) ...[
                    const FilterLabel(
                      icon: Icons.date_range_outlined,
                      label: 'Hari',
                    ),
                    const SizedBox(height: 6),
                    ChipGroup(
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
                  const FilterLabel(
                    icon: Icons.label_outline_rounded,
                    label: 'Tipe',
                  ),
                  const SizedBox(height: 6),
                  ChipGroup(
                    options: const ['TE', 'PR'],
                    selected: filterTePr,
                    onTap: onToggleTePr,
                    displayMap: const {
                      'TE': 'Teori (TE)',
                      'PR': 'Praktik (PR)',
                    },
                  ),
                  if (hasPendingSchedules) ...[
                    const SizedBox(height: 14),
                    const FilterLabel(
                      icon: Icons.cloud_outlined,
                      label: 'Status Sinkronisasi',
                    ),
                    const SizedBox(height: 6),
                    ChipGroup(
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
