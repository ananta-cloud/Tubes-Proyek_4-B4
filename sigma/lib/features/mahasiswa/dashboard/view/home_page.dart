import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sigma/features/mahasiswa/dashboard/viewmodels/home_page_viewmodel.dart';
import 'package:sigma/features/mahasiswa/dashboard/widgets/home_page_widgets.dart';

import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';

class HomePageMhs extends StatelessWidget {
  const HomePageMhs({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
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
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Column(
        children: [
          // Header Widget
          HomeHeader(
            greeting: vm.greeting,
            userName: "Mahasiswa SIGMA", // Nanti ambil dari AuthRepository
            onLogout: () => _showLogoutDialog(context),
          ),

          Expanded(
            child: IndexedStack(
              index: vm.currentIndex,
              children: [
                _buildHomeTab(context),
                const Center(child: Text("Halaman Jadwal")),
                const Center(child: Text("Halaman Tugas")),
                const Center(child: Text("Halaman Profil")),
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
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Jadwal"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: "Tugas"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Menu Utama",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            children: [
              MenuGridItem(
                icon: Icons.grid_view_rounded,
                label: "KRS",
                color: Colors.blue,
                onTap: () {},
              ),
              MenuGridItem(
                icon: Icons.receipt_long_rounded,
                label: "KHS",
                color: Colors.orange,
                onTap: () {},
              ),
              MenuGridItem(
                icon: Icons.account_balance_wallet_rounded,
                label: "UKT",
                color: Colors.green,
                onTap: () {},
              ),
              MenuGridItem(
                icon: Icons.more_horiz_rounded,
                label: "Lainnya",
                color: Colors.purple,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}