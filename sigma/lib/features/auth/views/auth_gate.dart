import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/mahasiswa/dashboard/view/home_page.dart';
import 'package:sigma/features/dosen/dashboard/views/home_page.dart';
import 'package:sigma/features/penjadwalan/penjadwalan_main_page.dart'; // ← tambah

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
    await authVm.checkLogin();
    final currentUser = authVm.user;

    if (!mounted) return;

    if (currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final role = currentUser.role.toUpperCase();

    if (role == 'DOSEN') {
      final currentDosen = authVm.dosen;
      if (currentDosen != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePageDsn(user: currentUser, dosen: currentDosen),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else if (role == 'TIM_PENJADWALAN') {
      final tim = authVm.timPenjadwalan;
      if (tim != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PenjadwalanMainPage(user: currentUser, timPenjadwalan: tim),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePageMhs()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF3F5DB3),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
