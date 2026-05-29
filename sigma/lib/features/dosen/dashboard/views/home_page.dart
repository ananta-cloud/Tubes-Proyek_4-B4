import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sigma/data/repositories/auth_repository.dart';

import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/dosen_model.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/announcements/views/announcement_detail_page.dart';
import 'package:sigma/features/dosen/tasks/views/task_management_page.dart';
import 'package:sigma/features/dosen/schedules/views/jadwal_mengajar_page.dart';
import 'package:sigma/features/dosen/requests/views/my_requests_page.dart';
import '../widgets/home_page_widget.dart';

class HomePageDsn extends StatefulWidget {
  final UserModel user;
  final DosenModel dosen;
  const HomePageDsn({super.key, required this.user, required this.dosen});

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
      context.read<AnnouncementViewModel>().setUserRole('DOSEN');
      context.read<AnnouncementViewModel>().syncAnnouncements();
    });
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Bapak/Ibu ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
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
              'Keluar',
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
    final activeDosen = context.watch<LoginViewModel>().dosen ?? widget.dosen;

    final namaLengkap = (activeUser?.nama.isNotEmpty == true)
        ? activeUser!.nama
        : activeDosen.namaDosen.isNotEmpty
        ? activeDosen.namaDosen
        : 'Dosen SIGMA';

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            DosenHomeHeader(
              greeting: 'Selamat Datang,',
              lecturerName: namaLengkap,
              onLogout: () => _handleLogout(context),
              showNotification: true,
              backgroundColor: primaryBlue,
              gradient: null,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: IndexedStack(
                  key: ValueKey(currentIndex),
                  index: currentIndex,
                  children: [
                    _home(announcementViewModel),
                    JadwalMengajarPage(
                      user: activeUser ?? widget.user,
                      dosen: activeDosen,
                    ),
                    MyRequestsPage(
                      user: activeUser ?? widget.user,
                      dosen: activeDosen,
                      isActive: currentIndex == 2,
                    ),
                    const TaskManagementPage(),
                    _buildProfileTab(context, activeUser),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DosenBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        primaryBlue: primaryBlue,
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
      authenticated = await _showOtpDialog(email);
    }

    if (authenticated) {
      setState(() => _isPasswordRevealed = true);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _isPasswordRevealed = false);
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
        title: const Text('Verifikasi Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kami telah mengirimkan 4-digit kode ke email:\n$email',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0 0 0 0',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              if (otpCtrl.text == '1234') {
                isSuccess = true;
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kode OTP Salah!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Verifikasi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return isSuccess;
  }

  // ── Home / Pengumuman tab ─────────────────────────────────────────────────
  Widget _home(AnnouncementViewModel viewModel) {
    final List<String> dosenFilters = [
      'Semua',
      'Pengajaran',
      'Penelitian',
      'Pengabdian',
      'Informasi Umum',
    ];

    final filteredAnnouncements = viewModel.announcements.where((data) {
      return data.targetAudience != 'SEMUA_MAHASISWA' &&
          data.targetAudience != 'PRODI_MAHASISWA' &&
          data.targetAudience != 'MAHASISWA';
    }).toList();

    return RefreshIndicator(
      color: accentOrange,
      onRefresh: () async => viewModel.syncAnnouncements(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Text(
            'Jadwal mengajar hari ini',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Pengumuman Terbaru',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dosenFilters.map((filter) {
                final filterKey = filter == 'Semua' ? '' : filter;
                final isActive =
                    viewModel.selectedFilter == filterKey ||
                    (filter == 'Semua' && viewModel.selectedFilter == 'SEMUA');
                return GestureDetector(
                  onTap: () => viewModel.setFilter(filterKey),
                  child: DosenFilterChip(
                    text: filter,
                    active: isActive,
                    activeColor: primaryBlue,
                    darkText: darkText,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 15),
          if (viewModel.isLoading && filteredAnnouncements.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredAnnouncements.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'Tidak ada pengumuman.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...filteredAnnouncements.map(
              (data) => DosenAnnouncementCard(
                judul: data.judul,
                targetAudience: data.targetAudience,
                tingkatKepentingan: data.tingkatKepentingan,
                kategori: data.kategori,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnouncementDetailPage(announcement: data),
                  ),
                ),
                primaryBlue: primaryBlue,
                accentOrange: accentOrange,
                darkText: darkText,
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Profil tab ────────────────────────────────────────────────────────────
  Widget _buildProfileTab(BuildContext context, UserModel? activeUser) {
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
                          (activeUser?.nama.isNotEmpty == true)
                              ? activeUser!.nama
                              : widget.dosen.namaDosen,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        Text(
                          widget.user.role.isNotEmpty
                              ? widget.user.role
                              : 'DOSEN',
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
              DosenInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: widget.user.email,
                darkText: darkText,
              ),
              DosenInfoRow(
                icon: Icons.password,
                label: 'Password',
                value: _isPasswordRevealed ? 'tidak tersedia' : '••••••••••••',
                darkText: darkText,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        'Ganti',
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
          'Pengumuman Tersimpan',
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
                    'Belum ada pengumuman yang disimpan.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }
            return Column(
              children: bookmarkedItems
                  .map(
                    (data) => DosenAnnouncementCard(
                      judul: data.judul,
                      targetAudience: data.targetAudience,
                      tingkatKepentingan: data.tingkatKepentingan,
                      kategori: data.kategori,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AnnouncementDetailPage(announcement: data),
                        ),
                      ),
                      primaryBlue: primaryBlue,
                      accentOrange: accentOrange,
                      darkText: darkText,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Ganti Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordCtrl,
                      obscureText: obscureOld,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Password Lama',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscureOld = !obscureOld),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: obscureNew,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
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
                  // Nonaktifkan tombol batal saat loading
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (oldPasswordCtrl.text.isEmpty ||
                              newPasswordCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua kolom harus diisi!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (newPasswordCtrl.text !=
                              confirmPasswordCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Konfirmasi password baru tidak cocok!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (newPasswordCtrl.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password baru minimal 6 karakter!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final authRepo = AuthRepository();
                            final success = await authRepo.changePassword(
                              widget.user.id,
                              oldPasswordCtrl.text,
                              newPasswordCtrl.text,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✅ Password berhasil diperbarui!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '❌ Gagal: ${e.toString().replaceAll('Exception: ', '')}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text(
                    isSubmitting ? 'Menyimpan...' : 'Simpan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
