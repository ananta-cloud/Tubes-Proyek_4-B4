import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/admin_main_viewodel.dart';
import '../../schedules/views/admin_schedule_page.dart';
import '../../announcements/views/admin_announcement_page.dart';
import '../../master_matkul/views/admin_matkul_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WARNA BRAND SIGMA — pakai di semua file fitur admin_tu
// ─────────────────────────────────────────────────────────────────────────────
class SigmaColors {
  static const navy = Color(0xFF1E2A6E);
  static const navyDark = Color(0xFF151E55);
  static const navyLight = Color(0xFF2D3E8C);
  static const gold = Color(0xFFF5A623);
  static const accent = Color(0xFF5C6BC0);
  static const bgPage = Color(0xFFF4F6FA);
  static const textSub = Color(0xFF8A94AD);
  static const success = Color(0xFF00897B);
  static const danger = Color(0xFFE53935);
  static const white = Color(0xFFFFFFFF);

  static const cardBorder = Color(0xFFE8ECF4);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADMIN MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class AdminMainPage extends StatelessWidget {
  const AdminMainPage({super.key});

  static const _semester = 'Semester Genap 2025/2026';

  // Pages sesuai urutan bottom nav
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
    // Pastikan status bar gelap agar kontras dengan navy
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: SigmaColors.navy,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final vm = context.watch<AdminMainViewModel>();

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      // ── Body: IndexedStack agar state halaman tidak hilang saat ganti tab ──
      body: IndexedStack(index: vm.selectedIndex, children: _pages),
      // ── Bottom Navigation Bar ──
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
//  BOTTOM NAV — custom agar bisa pakai desain brand SIGMA
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
        color: SigmaColors.white,
        border: Border(
          top: BorderSide(color: SigmaColors.cardBorder, width: 1),
        ),
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
                        // Pill indicator di atas icon saat aktif
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 36 : 0,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: SigmaColors.navy,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            key: ValueKey(isActive),
                            color: isActive
                                ? SigmaColors.navy
                                : SigmaColors.textSub,
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
                                ? SigmaColors.navy
                                : SigmaColors.textSub,
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
//  SHARED WIDGETS — dipakai bersama oleh semua halaman admin_tu
// ─────────────────────────────────────────────────────────────────────────────

/// Header standar tiap halaman (judul + subtitle semester + tombol logout)
class SigmaPageHeader extends StatelessWidget {
  const SigmaPageHeader({
    super.key,
    required this.title,
    this.subtitle = 'Semester Genap 2025/2026',
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SigmaColors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Logo kecil
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SigmaColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: SigmaColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SigmaColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: SigmaColors.textSub,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
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
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Stat card standar (Draft/Published/Total, dll.)
class SigmaStatCard extends StatelessWidget {
  const SigmaStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sublabel,
    this.accentColor = SigmaColors.navy,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SigmaColors.white,
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
                color: SigmaColors.navy,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: const TextStyle(color: SigmaColors.textSub, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state standar
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
            Icon(icon, size: 56, color: SigmaColors.cardBorder),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: SigmaColors.textSub,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub!,
                style: const TextStyle(
                  color: SigmaColors.textSub,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tombol aksi utama bercorak navy
class SigmaPrimaryButton extends StatelessWidget {
  const SigmaPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isLoading ? SigmaColors.textSub : SigmaColors.navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(SigmaColors.white),
                ),
              )
            else if (icon != null)
              Icon(icon, color: SigmaColors.white, size: 18),
            if (!isLoading && icon != null) const SizedBox(width: 8),
            Text(
              isLoading ? 'Memuat...' : label,
              style: const TextStyle(
                color: SigmaColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
