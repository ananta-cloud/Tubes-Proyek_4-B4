import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sigma/data/repositories/auth_repository.dart';

// ==========================================
// 1. IMPORT DATA & MODELS
// ==========================================
import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/data/models/user_model.dart';

// ==========================================
// 2. IMPORT VIEWMODELS & VIEWS
// ==========================================
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/announcements/views/announcement_detail_page.dart';
import 'package:sigma/features/dosen/tasks/views/task_management_page.dart';

// IMPORT HALAMAN BARU YANG KAMU BUAT
import 'package:sigma/features/dosen/schedules/views/jadwal_mengajar_page.dart';
import 'package:sigma/features/dosen/requests/views/my_requests_page.dart';

class HomePageDsn extends StatefulWidget {
  final UserModel user; // <-- Pastikan tetap menerima user

  const HomePageDsn({super.key, required this.user});

  @override
  State<HomePageDsn> createState() => _HomePageDsnState();
}

class _HomePageDsnState extends State<HomePageDsn> {
  int currentIndex = 0;

  final primaryBlue = const Color(0xFF3F5DB3);
  final accentOrange = const Color(0xFFFF7A36);
  final bgColor = const Color(0xFFEAF3FA);
  final darkText = const Color(0xFF1F1F3D);
  bool _isPasswordRevealed = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = widget.user.id;
      if (userId.isNotEmpty) {
        context.read<AnnouncementViewModel>().syncBookmarks(userId);
      }
    });
  }

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
    final activeUser = context.watch<LoginViewModel>().user;

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
                // Menggunakan IndexedStack untuk menghindari build ulang berlebihan pada Task Management
                child: IndexedStack(
                  key: ValueKey(currentIndex),
                  index: currentIndex,
                  children: [
                    _home(announcementViewModel), // Tab 0: Home / Pengumuman
                    JadwalMengajarPage(user: activeUser ?? widget.user), // Tab 1: Mengajar
                    MyRequestsPage(user: activeUser ?? widget.user), // Tab 2: Permohonan
                    const TaskManagementPage(), // Tab 3: Tugas
                    _buildMainDashboard(context), // Tab 4: Profil (diganti pakai _buildMainDashboard)
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
    final namaLengkap = widget.user.nama.isNotEmpty ? widget.user.nama : "Dosen SIGMA";

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selamat Datang,",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      namaLengkap,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.notifications, color: Colors.white),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () => _handleLogout(context),
                child: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateToRevealPassword(String email) async {
    bool authenticated = false;

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        authenticated = await auth.authenticate(
          localizedReason: 'Pindai sidik jari/wajah untuk melihat password',
        );
      } else {
        authenticated = await _showOtpDialog(email);
      }
    } catch (e) {
      print("Error Biometrik: $e");
      authenticated = await _showOtpDialog(email);
    }

    if (authenticated) {
      setState(() {
        _isPasswordRevealed = true;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isPasswordRevealed = false;
          });
        }
      });
    }
  }

  Future<bool> _showOtpDialog(String email) async {
    final otpCtrl = TextEditingController();
    bool isSuccess = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Verifikasi Email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kami telah mengirimkan 4-digit kode ke email:\n$email",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "0 0 0 0",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              if (otpCtrl.text == "1234") {
                isSuccess = true;
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Kode OTP Salah!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "Verifikasi",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return isSuccess;
  }

  // ================= HOME / PENGUMUMAN =================
  Widget _home(AnnouncementViewModel viewModel) {
    final List<String> dosenFilters = [
      'Semua',
      'Pengajaran',
      'Penelitian',
      'Pengabdian',
      'Informasi Umum'
    ];

    final filteredAnnouncementsForDosen = viewModel.announcements.where((data) {
      return data.targetAudience != 'SEMUA_MAHASISWA' && 
             data.targetAudience != 'PRODI_MAHASISWA' &&
             data.targetAudience != 'MAHASISWA'; 
    }).toList();

    return RefreshIndicator(
      color: accentOrange,
      onRefresh: () async {
        await viewModel.syncAnnouncements();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Text("Jadwal mengajar hari ini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 25),
          Text("Pengumuman Terbaru", style: TextStyle(fontWeight: FontWeight.bold, color: darkText, fontSize: 16)),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dosenFilters.map((filter) {
                final filterKey = filter == 'Semua' ? '' : filter;
                final isActive = viewModel.selectedFilter == filterKey || 
                                 (filter == 'Semua' && viewModel.selectedFilter == 'SEMUA');
                return GestureDetector(
                  onTap: () => viewModel.setFilter(filterKey),
                  child: _chip(filter, isActive),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 15),

          if (viewModel.isLoading && filteredAnnouncementsForDosen.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 30), child: Center(child: CircularProgressIndicator()))
          else if (filteredAnnouncementsForDosen.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(child: Text("Tidak ada pengumuman.", style: TextStyle(color: Colors.grey.shade600))),
            )
          else
            ...filteredAnnouncementsForDosen.map((data) => _announcement(data)).toList(),

          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  Widget _chip(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? primaryBlue : Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : darkText,
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ================= PROFIL / MAIN DASHBOARD =================
  Widget _buildMainDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          widget.user.nama.isNotEmpty ? widget.user.nama : "Nama Tidak Tersedia",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        Text(
                          widget.user.role.isNotEmpty ? widget.user.role : "DOSEN",
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
              _infoRow(Icons.email_outlined, "Email", widget.user.email),

              _infoRow(
                Icons.password,
                "Password",
                _isPasswordRevealed ? "PasswordAsli123!" : "••••••••••••",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPasswordRevealed ? Icons.visibility_off : Icons.visibility,
                        color: _isPasswordRevealed ? accentOrange : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_isPasswordRevealed) {
                          setState(() => _isPasswordRevealed = false);
                        } else {
                          _authenticateToRevealPassword(widget.user.email);
                        }
                      },
                    ),
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
          valueListenable: Hive.box<AnnouncementModel>('bookmarks').listenable(),
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
              children: bookmarkedItems.map((data) => _announcement(data)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Widget? trailing}) {
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
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false; 

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (dialogContext) { 
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: "Password Lama",
                        suffixIcon: IconButton(
                          icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                          onPressed: () => setDialogState(() => obscureOld = !obscureOld),
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
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
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
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        )
                      ),
                    ),
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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

                    setDialogState(() => isSubmitting = true);

                    try {
                      final authRepo = AuthRepository(); 
                      bool success = await authRepo.changePassword(
                        widget.user.id, 
                        oldPasswordCtrl.text, 
                        newPasswordCtrl.text
                      );

                      if (!context.mounted) return;

                      if (success) {
                        Navigator.pop(dialogContext); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Password berhasil diperbarui!"), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("❌ Gagal: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data.targetAudience.replaceAll('_', ' '),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue),
                              ),
                            ),
                            Text(
                              data.tingkatKepentingan,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: indikatorWarna),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.judul,
                          style: TextStyle(fontWeight: FontWeight.bold, color: darkText, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        if (data.kategori.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: data.kategori.map((kat) => Text(
                              "#$kat",
                              style: TextStyle(fontSize: 11, color: accentOrange, fontWeight: FontWeight.w600),
                            )).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          _navItem(Icons.dashboard_rounded, "Beranda", 0), 
          _navItem(Icons.menu_book_rounded, "Mengajar", 1), 
          _navItem(Icons.schedule_send_rounded, "Permohonan", 2), 
          _navItem(Icons.assignment_rounded, "Tugas", 3), 
          _navItem(Icons.person_pin_rounded, "Akun", 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? primaryBlue : const Color(0xFFB0B7C3),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? primaryBlue : const Color(0xFFB0B7C3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}