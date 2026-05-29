import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/viewmodels/login_viewmodel.dart';
import '../../auth/views/login_page.dart';
import 'package:sigma/features/announcements/views/admin_announcement_page.dart';

class ManajemenMainPage extends StatelessWidget {
  const ManajemenMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel Manajemen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F1F3D), // primaryBlue Sigma
        actions: [
          // Tombol Keluar (Logout)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Keluar',
            onPressed: () {
              // Jika Anda punya fungsi logout di LoginViewModel, panggil di sini
              // context.read<LoginViewModel>().logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      // Langsung tembak ke halaman Pengumuman tanpa BottomNavigationBar
      body: const AdminAnnouncementPage(),
    );
  }
}
