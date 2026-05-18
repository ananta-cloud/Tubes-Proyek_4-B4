import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sigma/data/repositories/auth_repository.dart';

// ==========================================
// 1. IMPORT DATA & MODELS
// ==========================================
import 'package:sigma/data/models/announcement_model.dart';

// ==========================================
// 2. IMPORT VIEWMODELS & VIEWS
// ==========================================
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/announcements/views/announcement_detail_page.dart';
import 'package:sigma/features/dosen/tasks/views/task_management_page.dart';

class HomePageDsn extends StatefulWidget {
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
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
            child: const Text(
              "Keluar",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementViewModel = context.watch<AnnouncementViewModel>();

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: IndexedStack(
                  key: ValueKey(currentIndex),
                  index: currentIndex,
                  children: [
                    _home(announcementViewModel), // Tab 0: Home / Pengumuman
                    const Center(
                      child: Text("Halaman Jadwal Mengajar (Segera Hadir)"),
                    ), // Tab 1: Mengajar
                    const TaskManagementPage(), // Tab 2: Tugas
                    _profile(context), // Tab 3: Profil & Bookmark
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ================= HEADER =================
  Widget _header(BuildContext context) {
    final user = context.watch<LoginViewModel>().user;
    final namaLengkap = user?.nama ?? "Dosen SIGMA";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      decoration: BoxDecoration(
        color: primaryBlue,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryBlue.withOpacity(0.1),
                    child: Icon(Icons.person, color: primaryBlue, size: 35),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nama ?? "Nama Tidak Tersedia",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        Text(
                          user?.role ?? "Dosen",
                          style: TextStyle(
                            fontSize: 14,
                            color: accentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              _infoRow(Icons.email_outlined, "Email", user?.email ?? "-"),

              // Baris Password dengan Tombol Ganti
              _infoRow(
                Icons.password,
                "Password",
                // Jika _isPasswordRevealed true, tampilkan password asli (disimulasikan dengan teks ini)
                // Jika false, tampilkan titik-titik
                _isPasswordRevealed ? "PasswordAsli123!" : "••••••••••••",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tombol Lihat (Mata)
                    IconButton(
                      icon: Icon(
                        _isPasswordRevealed
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _isPasswordRevealed ? accentOrange : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_isPasswordRevealed) {
                          // Jika sedang terlihat, langsung tutup saja tanpa biometrik
                          setState(() => _isPasswordRevealed = false);
                        } else {
                          // Jika tertutup, minta autentikasi sebelum membuka
                          _authenticateToRevealPassword(user?.email ?? "");
                        }
                      },
                    ),
                    // Tombol Ganti
                    TextButton(
                      onPressed: () => _showChangePasswordDialog(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Ganti",
                        style: TextStyle(
                          color: accentOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Bagian Bookmark Pengumuman
        Text(
          "Pengumuman Tersimpan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 15),
        ValueListenableBuilder<Box<AnnouncementModel>>(
          valueListenable: Hive.box<AnnouncementModel>(
            'bookmarks',
          ).listenable(),
          builder: (context, box, _) {
            final bookmarkedItems = box.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (bookmarkedItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "Belum ada pengumuman yang disimpan.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }
            return Column(
              children: bookmarkedItems
                  .map((data) => _announcement(data))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // Info Row diperbarui agar bisa menerima widget tambahan di sisi kanan (trailing)
  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
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
          if (trailing != null) trailing, // Menampilkan tombol jika ada
        ],
      ),
    );
  }

  // ================= DIALOG GANTI PASSWORD =================
  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    
    // 1. Tambahkan state untuk mendeteksi proses loading
    bool isSubmitting = false; 

    showDialog(
      context: context,
      // 2. Kunci dialog agar tidak bisa ditutup dengan menyentuh area luar
      barrierDismissible: false, 
      // 3. Gunakan nama 'dialogContext' agar tidak tertukar dengan context halaman utama
      builder: (dialogContext) { 
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Ganti Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordCtrl,
                      obscureText: obscureOld,
                      enabled: !isSubmitting, // Kunci field saat loading
                      decoration: InputDecoration(
                        labelText: "Password Lama",
                        suffixIcon: IconButton(
                          icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => obscureOld = !obscureOld),
                        )
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: obscureNew,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: "Password Baru",
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => obscureNew = !obscureNew),
                        )
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: "Konfirmasi Password Baru",
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                        )
                      ),
                    ),
                    // Indikator Loading berputar
                    if (isSubmitting)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  // Nonaktifkan tombol batal saat loading
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  // Nonaktifkan tombol simpan saat loading untuk mencegah klik berkali-kali
                  onPressed: isSubmitting ? null : () async {
                    if (oldPasswordCtrl.text.isEmpty || newPasswordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom harus diisi!"), backgroundColor: Colors.red));
                      return;
                    }
                    if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password baru tidak cocok!"), backgroundColor: Colors.red));
                      return;
                    }
                    if (newPasswordCtrl.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password baru minimal 6 karakter!"), backgroundColor: Colors.red));
                      return;
                    }

                    // Mulai animasi loading
                    setState(() => isSubmitting = true);

                    try {
                      // Gunakan file auth_repository Anda yang sudah diupdate
                      final authRepo = AuthRepository(); 
                      final user = context.read<LoginViewModel>().user;

                      if (user?.id != null) {
                        bool success = await authRepo.changePassword(
                          user!.id, 
                          oldPasswordCtrl.text, 
                          newPasswordCtrl.text
                        );

                        // 4. Pastikan context masih aktif sebelum melakukan aksi UI
                        if (!context.mounted) return;

                        if (success) {
                          Navigator.pop(dialogContext); // Gunakan dialogContext untuk menutup secara spesifik
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Password berhasil diperbarui!"), 
                              backgroundColor: Colors.green
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Matikan loading jika gagal agar user bisa mencoba lagi
                      setState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("❌ Gagal: ${e.toString().replaceAll('Exception: ', '')}"), 
                          backgroundColor: Colors.red
                        ),
                      );
                    }
                  },
                  child: Text(isSubmitting ? "Menyimpan..." : "Simpan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // ================= KOMPONEN CARD PENGUMUMAN =================
  Widget _announcement(AnnouncementModel data) {
    Color indikatorWarna = (data.tingkatKepentingan == 'SANGAT PENTING')
        ? Colors.red
        : (data.tingkatKepentingan == 'PENTING')
        ? accentOrange
        : (data.tingkatKepentingan == 'LUMAYAN PENTING')
        ? Colors.amber
        : primaryBlue.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnnouncementDetailPage(announcement: data),
          ),
        );
      },
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
                Container(width: 6, color: indikatorWarna),
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
                                data.targetAudience.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            Text(
                              data.tingkatKepentingan,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: indikatorWarna,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.judul,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        if (data.kategori.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: data.kategori
                                .map(
                                  (kat) => Text(
                                    "#$kat",
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

  // ================= NAVBAR =================
  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 10),
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
        children: [
          _navItem(Icons.dashboard_rounded, 0), // Beranda
          _navItem(Icons.menu_book_rounded, 1), // Mengajar
          _navItem(Icons.assignment_rounded, 2), // Tugas (Task Management)
          _navItem(Icons.person_pin_rounded, 3), // Akun
        ],
      ),
    );
  }
}