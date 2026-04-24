import 'package:flutter/material.dart';
import 'package:kampus_ku_mobile/view/home_page.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {

  bool _obscurePassword = true;
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_box_outlined, 
                      size: 100, 
                      color: Color(0xFF3652AD)
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "SIGMA", 
                      style: TextStyle(
                        fontSize: 40, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF280274)
                      )
                    ),
                    Text(
                      "Sistem Informasi Jadwal &\nPengumuman Mahasiswa", 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      )
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter, // <-- Ini yang memindahkannya ke bawah
              child: Container(
                height: 535,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color(0xFF280274), // Background form ungu gelap
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Selamat Datang,\nSilakan Login', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w600,
                          color: Colors.white // Mengubah teks menjadi putih
                        )
                      ),
                      const SizedBox(height: 32),
                      
                      // Input Username
                      TextFormField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person, color: Colors.white70),
                          labelText: "Username",
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: const BorderSide(color: Colors.white38)
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: const BorderSide(color: Colors.white)
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Input Password
                      TextFormField(
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: const BorderSide(color: Colors.white38)
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: const BorderSide(color: Colors.white)
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Tombol Login
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, 
                              MaterialPageRoute(builder: (context) => const HomePage())
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFE7A36), // Warna Orange
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
