import 'package:flutter/material.dart';

// 1. Ganti menjadi StatefulWidget agar bisa ganti-ganti menu (currentIndex)
class SchedulingDashboard extends StatefulWidget {
  const SchedulingDashboard({super.key});

  @override
  State<SchedulingDashboard> createState() => _SchedulingDashboardState();
}

class _SchedulingDashboardState extends State<SchedulingDashboard> {
  // Pindahkan variabel state ke sini
  int currentIndex = 0;
  final Color primaryBlue = const Color(0xFF4338CA); // Indigo-700

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // PENTING: Supaya navbar melayang tidak menabrak konten
      backgroundColor: const Color(0xFFF8FAFC), // Slate-50
      appBar: AppBar(
        title: const Text(
          "Dashboard Tim Penjadwalan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      // Gunakan IndexedStack agar posisi scroll tidak reset saat ganti menu
      body: IndexedStack(
        index: currentIndex,
        children: [
          _buildDashboardContent(), // Menu 0
          const Center(child: Text("Halaman Kelola Jadwal")), // Menu 1
          const Center(child: Text("Halaman Periode Revisi")), // Menu 2
          const Center(child: Text("Halaman Request Perubahan")), // Menu 3
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // --- KONTEN UTAMA DASHBOARD ---
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        100,
      ), // Padding bawah dilebihkan karena ada floating nav
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("TOTAL JADWAL", "42", Colors.grey),
              _buildStatCard("DRAFT", "12", Colors.grey),
              _buildStatCard("FINAL", "15", Colors.amber),
              _buildStatCard("PUBLISHED", "15", Colors.lightGreenAccent),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(0.35),
          const SizedBox(height: 20),
          _buildRequestAlert(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Jadwal Terbaru",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: const Text("Lihat Semua →")),
            ],
          ),
          _buildScheduleList(),
        ],
      ),
    );
  }

  // --- WIDGET HELPER (Sama seperti punyamu tapi pastikan ditaruh di dalam class State) ---

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Selamat datang,",
            style: TextStyle(color: Colors.white70),
          ),
          const Text(
            "Admin Penjadwalan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Input Baru"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[600],
                  foregroundColor: const Color(0xFF312E81),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text(
                  "Kelola Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progress Publikasi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.lightGreenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestAlert() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.amber[800]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "3 Request Menunggu",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
                Text(
                  "Dosen mengajukan perubahan jadwal",
                  style: TextStyle(fontSize: 11, color: Colors.amber[800]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: const Text(
              "Pemrograman Web",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Senin, 08:00 - 10:00 • R. Lab 1"),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent[50],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    "PUBLISHED",
                    style: TextStyle(
                      color: Colors.lightGreenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }

  // --- BOTTOM NAVIGATION WIDGET ---
  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view_rounded, 0, "Dashboard"),
          _navItem(Icons.calendar_month_rounded, 1, "Jadwal"),
          _navItem(Icons.history_edu_rounded, 2, "Revisi"),
          _navItem(
            Icons.mail_outline_rounded,
            3,
            "Request",
            hasBadge: true,
            badgeCount: 3,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    int index,
    String label, {
    bool hasBadge = false,
    int badgeCount = 0,
  }) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? primaryBlue : const Color(0xFFB0B7C3),
                ),
                if (isActive)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
              ],
            ),
            if (hasBadge && badgeCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
