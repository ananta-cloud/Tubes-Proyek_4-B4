import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F6FF),
      body: SafeArea(
        child: Column(
          children: const [
            _Header(),
            Expanded(child: _Content()),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

// ================= HEADER =================
class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF3652AD),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("SIGMA",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text("D3 Teknik Informatika",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: Color(0xFFFE7A36),
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text("Online - Tersinkronisasi",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ================= CONTENT =================
class _Content extends StatelessWidget {
  const _Content({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Halo, Fahraj! 👋",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF280274))),
          const SizedBox(height: 6),
          const Text("Jadwal pertamamu hari ini jam 07:00.",
              style: TextStyle(fontSize: 13, color: Color(0xFF280274))),
          const SizedBox(height: 20),

          // CARD JADWAL
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Kelas Berikutnya",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF280274))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF3652AD).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("Hari Ini",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3652AD))),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE7A36)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book,
                          color: Color(0xFFFE7A36)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Pemrograman Berbasis Mobile",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF280274))),
                        SizedBox(height: 6),
                        Text("07:00 - 10:40",
                            style: TextStyle(fontSize: 12)),
                        Text("Lab Komputer 4",
                            style: TextStyle(fontSize: 12)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text("Pengumuman Terbaru",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF280274))),

          const SizedBox(height: 10),

          _announcement(true),
          _announcement(false),
        ],
      ),
    );
  }

  Widget _announcement(bool important) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          if (important)
            Container(width: 4, height: 60, color: const Color(0xFFFE7A36)),
          if (important) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: important
                            ? const Color(0xFF3652AD)
                                .withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                          important ? "Jurusan" : "Umum",
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Text("10 Menit",
                        style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 5),
                const Text("Perubahan Ruangan PBO",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                const Text("Dipindah ke Lab RPL",
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ================= BOTTOM NAV =================
class _BottomNav extends StatelessWidget {
  const _BottomNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(icon: Icons.home, label: "Beranda", active: true),
          _NavItem(icon: Icons.calendar_today, label: "Jadwal"),
          _NavItem(icon: Icons.check_box, label: "Tugas"),
          _NavItem(icon: Icons.bookmark, label: "Simpan"),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem(
      {Key? key,
      required this.icon,
      required this.label,
      this.active = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF3652AD).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 22,
              color: active
                  ? const Color(0xFF3652AD)
                  : Colors.grey),
        ),
        if (active) const SizedBox(height: 3),
        if (active)
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF3652AD)))
      ],
    );
  }
}

// ================= TEST NOTES =================
// 1. Run with: flutter run
// 2. Ensure no overflow in small devices
// 3. Navbar height should remain compact (65px)
// 4. UI should match design (header, card, announcement)
