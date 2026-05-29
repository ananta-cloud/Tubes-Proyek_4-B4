import 'package:flutter/material.dart';
import 'package:sigma/features/mahasiswa/dashboard/view/home_page.dart';
import 'package:sigma/features/dosen/dashboard/views/home_page.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/admin_tu/main/views/admin_main_page.dart';
import 'package:sigma/features/manajemen/views/manajemen_main_page.dart';
import 'package:sigma/features/penjadwalan/penjadwalan_main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAutoLogin();
    });
  }

  void _runAutoLogin() async {
    final viewModel = context.read<LoginViewModel>();
    final user = await viewModel.checkLogin();
    final currentDosen = viewModel.dosen;

    if (!mounted) return;

    if (user != null) {
      if (user.role.toUpperCase() == 'DOSEN' && currentDosen != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePageDsn(user: user, dosen: currentDosen),
          ),
        );
      } else if (user.role.toUpperCase() == 'MAHASISWA') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageMhs()),
        );
      } else if (user.role.toUpperCase() == 'TIM_PENJADWALAN') {
        final tim = viewModel.timPenjadwalan;
        if (tim != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PenjadwalanMainPage(user: user, timPenjadwalan: tim),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final viewModel = context.read<LoginViewModel>();

    await viewModel.login(emailController.text, passwordController.text);

    if (!mounted) return;

    final currentUser = viewModel.user;

    if (currentUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login sukses: ${currentUser.nama}")),
      );

      final role = currentUser.role.toUpperCase();

      if (role == 'DOSEN') {
        final dosen = viewModel.dosen;
        if (dosen != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePageDsn(user: currentUser, dosen: dosen),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Data dosen tidak ditemukan"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (role == 'MAHASISWA') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageMhs()),
        );
      } else if (user.role?.toUpperCase() == 'ADMIN_TU') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainPage()),
        );  
      } else if (user.role.toUpperCase() == 'MANAJEMEN') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManajemenMainPage()));
      } 
      } else if (role == 'TIM_PENJADWALAN') {
        final tim = viewModel.timPenjadwalan;
        if (tim != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PenjadwalanMainPage(user: currentUser, timPenjadwalan: tim),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Data tim penjadwalan tidak ditemukan"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (role == 'ADMIN_TU' || role == 'MANAJEMEN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainPage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login gagal"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 110),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan watch untuk memantau perubahan state (loading)
    final isLoading = context.watch<LoginViewModel>().isLoading;

    return Scaffold(
      body: Container(
        // GRADIENT BACKGROUND
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFDCE6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ================= LOGO =================
                  Column(
                    children: const [
                      Icon(Icons.school, size: 60, color: Color(0xFF3F5DB3)),
                      SizedBox(height: 10),
                      Text(
                        "SIGMA POLBAN",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1F3D),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Portal Akademik Mahasiswa",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ================= CARD =================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 30,
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Masuk ke Akun",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ================= EMAIL =================
                        _inputField(
                          controller: emailController,
                          hint: "Email kampus",
                          icon: Icons.email,
                        ),

                        const SizedBox(height: 15),

                        // ================= PASSWORD =================
                        _inputField(
                          controller: passwordController,
                          hint: "Password",
                          icon: Icons.lock,
                          obscure: true,
                        ),

                        const SizedBox(height: 25),

                        // ================= BUTTON =================
                        GestureDetector(
                          onTap: isLoading ? null : _handleLogin,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3F5DB3), Color(0xFF5B7BFF)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.blue.withOpacity(0.3),
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Masuk",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "© 2026 SIGMA POLBAN",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF3F5DB3)),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F7FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
