import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sigma/features/dosen/dashboard/viewmodels/home_page_viewmodel.dart';
import 'package:sigma/features/dosen/dashboard/widgets/home_page_widget.dart';

import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';

class HomePageDsn extends StatelessWidget {
  const HomePageDsn({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DosenHomeViewModel(),
      child: const _DosenHomeView(),
    );
  }
}

class _DosenHomeView extends StatelessWidget {
  const _DosenHomeView();

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Bapak/Ibu ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await context.read<LoginViewModel>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenHomeViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          DosenHomeHeader(
            greeting: vm.greeting,
            lecturerName: "Dr. Sigma, M.T.", // Integrasikan dengan data User asli
            onLogout: () => _handleLogout(context),
          ),
          Expanded(
            child: IndexedStack(
              index: vm.currentIndex,
              children: [
                _buildMainDashboard(context),
                const Center(child: Text("Halaman Jadwal Mengajar")),
                const Center(child: Text("Halaman Input Nilai")),
                const Center(child: Text("Halaman Profil Dosen")),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: vm.currentIndex,
        onTap: vm.setIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3F5DB3),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedItemColor: Colors.grey.shade400,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Mengajar"),
          BottomNavigationBarItem(icon: Icon(Icons.grade_rounded), label: "Penilaian"),
          BottomNavigationBarItem(icon: Icon(Icons.person_pin_rounded), label: "Akun"),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Panel Manajemen",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F3D)),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              DosenMenuItem(
                icon: Icons.people_alt_rounded,
                label: "Daftar Mahasiswa",
                color: Colors.indigo,
                onTap: () {},
              ),
              DosenMenuItem(
                icon: Icons.analytics_rounded,
                label: "Rekap Presensi",
                color: Colors.teal,
                onTap: () {},
              ),
              DosenMenuItem(
                icon: Icons.edit_calendar_rounded,
                label: "Atur Jadwal",
                color: Colors.amber.shade800,
                onTap: () {},
              ),
              DosenMenuItem(
                icon: Icons.assignment_turned_in_rounded,
                label: "Validasi Tugas",
                color: Colors.redAccent,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}