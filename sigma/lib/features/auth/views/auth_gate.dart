import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
// Import halaman Home Anda
import 'package:sigma/features/mahasiswa/dashboard/view/home_page.dart';
import 'package:sigma/features/dosen/dashboard/views/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSavedLogin();
    });
  }

  Future<void> _checkSavedLogin() async {
    final authVm = context.read<LoginViewModel>();

    // Cek apakah ada data user di storage
    final isLoggedIn = await authVm.checkLogin();

    if (!mounted) return;

    if (isLoggedIn && authVm.user != null) {
      // Jika sudah login, cek rolenya untuk diarahkan ke halaman yang tepat
      if (authVm.user!.role.toUpperCase() == 'DOSEN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageDsn()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageMhs()),
        );
      }
    } else {
      // Jika belum login, arahkan ke halaman Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layar putih dengan logo/loading saat mengecek memori lokal
    return const Scaffold(
      backgroundColor: Color(0xFF3F5DB3), // Warna Primary Blue
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
