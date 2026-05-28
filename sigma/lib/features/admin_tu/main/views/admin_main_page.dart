import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sigma/shared/app_colors.dart';
import '../viewmodels/admin_main_viewodel.dart';
import '../../schedules/views/admin_schedule_page.dart';
import '../../../announcements/views/admin_announcement_page.dart';
import '../../master_matkul/views/admin_matkul_page.dart';
// import 'package:sigma/shared/widgets/page_header.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ADMIN MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class AdminMainPage extends StatelessWidget {
  const AdminMainPage({super.key});

  // static const _semester = 'Semester Genap 2025/2026';

  static final _pages = [
    const AdminSchedulePage(),
    const AdminAnnouncementPage(),
    const AdminMatkulPage(),
  ];

  static const _navItems = [
    _NavData(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Jadwal',
    ),
    _NavData(
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
      label: 'Pengumuman',
    ),
    _NavData(
      icon: Icons.storage_outlined,
      activeIcon: Icons.storage_rounded,
      label: 'Master MK',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.navy,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final vm = context.watch<AdminMainViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: IndexedStack(index: vm.selectedIndex, children: _pages),
      bottomNavigationBar: _SigmaBottomNav(
        selectedIndex: vm.selectedIndex,
        onTap: (i) {
          HapticFeedback.lightImpact();
          context.read<AdminMainViewModel>().selectIndex(i);
        },
        items: _navItems,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────
class _NavData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _SigmaBottomNav extends StatelessWidget {
  const _SigmaBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 36 : 0,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            key: ValueKey(isActive),
                            color: isActive
                                ? AppColors.navy
                                : AppColors.textSub,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isActive
                                ? AppColors.navy
                                : AppColors.textSub,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// class SigmaPageHeader extends StatelessWidget {
//   const SigmaPageHeader({
//     super.key,
//     required this.title,
//     this.subtitle = 'Semester Genap 2025/2026',
//     this.action,
//   });

//   final String title;
//   final String subtitle;
//   final Widget? action;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: AppColors.white,
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top + 16,
//         left: 20,
//         right: 20,
//         bottom: 16,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: AppColors.navy,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(
//               Icons.school_rounded,
//               color: AppColors.gold,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: AppColors.navy,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: -0.3,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.schedule_rounded,
//                       size: 11,
//                       color: AppColors.textSub,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       subtitle,
//                       style: const TextStyle(
//                         color: AppColors.textSub,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           if (action != null) action!,
//         ],
//       ),
//     );
//   }
// }

/// FIX: Hapus `Expanded` dari dalam SigmaStatCard.
/// Widget ini sekarang return Container biasa — Expanded diurus oleh
/// pemanggil (Row di halaman masing-masing) jika memang dibutuhkan.
/// Sebelumnya return Expanded(...) sehingga jika pemanggil juga wrap
/// dengan Expanded, terjadi "Competing ParentDataWidgets" error.
class SigmaStatCard extends StatelessWidget {
  const SigmaStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sublabel,
    this.accentColor = AppColors.navy,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    // FIX: tidak lagi dibungkus Expanded di sini.
    // Gunakan Expanded di Row pemanggil jika perlu mengisi sisa ruang.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: const TextStyle(color: AppColors.textSub, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class SigmaEmptyState extends StatelessWidget {
  const SigmaEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.sub,
  });

  final IconData icon;
  final String message;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.cardBorder),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub!,
                style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// class SigmaPrimaryButton extends StatelessWidget {
//   const SigmaPrimaryButton({
//     super.key,
//     required this.label,
//     required this.onTap,
//     this.icon,
//     this.isLoading = false,
//   });

//   final String label;
//   final VoidCallback onTap;
//   final IconData? icon;
//   final bool isLoading;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
//         decoration: BoxDecoration(
//           color: isLoading ? AppColors.textSub : AppColors.navy,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (isLoading)
//               const SizedBox(
//                 width: 16,
//                 height: 16,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation(AppColors.white),
//                 ),
//               )
//             else if (icon != null)
//               Icon(icon, color: AppColors.white, size: 18),
//             if (!isLoading && icon != null) const SizedBox(width: 8),
//             Text(
//               isLoading ? 'Memuat...' : label,
//               style: const TextStyle(
//                 color: AppColors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
