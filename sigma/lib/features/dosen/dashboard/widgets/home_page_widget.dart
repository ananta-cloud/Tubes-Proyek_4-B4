import 'package:flutter/material.dart';

class DosenHomeHeader extends StatelessWidget {
  final String greeting;
  final String lecturerName;
  final VoidCallback onLogout;
  final bool showNotification;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onNotificationTap;

  const DosenHomeHeader({
    super.key,
    required this.greeting,
    required this.lecturerName,
    required this.onLogout,
    this.showNotification = false,
    this.backgroundColor,
    this.gradient,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 45, 20, 25),
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? const Color(0xFF3F5DB3))
            : null,
        gradient:
            gradient ??
            (backgroundColor != null
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF3F5DB3), Color(0xFF2A3F80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lecturerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showNotification) ...[
                IconButton(
                  onPressed: onNotificationTap,
                  icon: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
              IconButton(
                onPressed: onLogout,
                icon: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DosenMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const DosenMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1F3D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Announcement Card
// ─────────────────────────────────────────────────────────────────────────────
class DosenAnnouncementCard extends StatelessWidget {
  const DosenAnnouncementCard({
    super.key,
    required this.judul,
    required this.targetAudience,
    required this.tingkatKepentingan,
    required this.kategori,
    required this.onTap,
    this.primaryBlue = const Color(0xFF3F5DB3),
    this.accentOrange = const Color(0xFFFF7A36),
    this.darkText = const Color(0xFF1F1F3D),
  });

  final String judul;
  final String targetAudience;
  final String tingkatKepentingan;
  final List<String> kategori;
  final VoidCallback onTap;
  final Color primaryBlue;
  final Color accentOrange;
  final Color darkText;

  Color get _indikatorWarna => (tingkatKepentingan == 'SANGAT PENTING')
      ? Colors.red
      : (tingkatKepentingan == 'PENTING')
      ? accentOrange
      : (tingkatKepentingan == 'LUMAYAN PENTING')
      ? Colors.amber
      : primaryBlue.withOpacity(0.5);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: _indikatorWarna),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                targetAudience.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            Text(
                              tingkatKepentingan,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _indikatorWarna,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          judul,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        if (kategori.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: kategori
                                .map(
                                  (kat) => Text(
                                    '#$kat',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: accentOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Filter Chip Item
// ─────────────────────────────────────────────────────────────────────────────
class DosenFilterChip extends StatelessWidget {
  const DosenFilterChip({
    super.key,
    required this.text,
    required this.active,
    this.activeColor = const Color(0xFF3F5DB3),
    this.darkText = const Color(0xFF1F1F3D),
  });

  final String text;
  final bool active;
  final Color activeColor;
  final Color darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? activeColor : Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : darkText,
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom Nav
// ─────────────────────────────────────────────────────────────────────────────
class DosenBottomNav extends StatelessWidget {
  const DosenBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.primaryBlue = const Color(0xFF3F5DB3),
  });

  final int currentIndex;
  final void Function(int) onTap;
  final Color primaryBlue;

  static const _items = [
    (Icons.dashboard_rounded, 'Beranda'),
    (Icons.menu_book_rounded, 'Mengajar'),
    (Icons.schedule_send_rounded, 'Permohonan'),
    (Icons.assignment_rounded, 'Tugas'),
    (Icons.person_pin_rounded, 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final (icon, label) = _items[i];
          final isActive = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? primaryBlue.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isActive ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isActive ? primaryBlue : const Color(0xFFB0B7C3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? primaryBlue : const Color(0xFFB0B7C3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Info Row
// ─────────────────────────────────────────────────────────────────────────────
class DosenInfoRow extends StatelessWidget {
  const DosenInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.darkText = const Color(0xFF1F1F3D),
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color darkText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
