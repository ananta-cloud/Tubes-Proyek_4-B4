import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../data/services/notification_service.dart';

// ==========================================
// 1. IMPORT DATA & MODELS
// ==========================================
import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/data/models/schedule_model.dart';

// ==========================================
// 2. IMPORT VIEWMODELS & VIEWS
// ==========================================
import 'package:sigma/features/announcements/views/announcement_detail_page.dart';
import 'package:sigma/features/mahasiswa/tasks/views/student_task_card.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/announcements/widgets/announcement_widget.dart';
import 'package:sigma/features/mahasiswa/schedules/viewmodels/schedule_viewmodel.dart';
import 'package:sigma/features/mahasiswa/tasks/viewmodels/task_viewmodel.dart';

class HomePageMhs extends StatefulWidget {
  const HomePageMhs({super.key});

  @override
  State<HomePageMhs> createState() => _HomePageMhsState();
}

class _HomePageMhsState extends State<HomePageMhs> {
  int currentIndex = 0;

  final primaryBlue = const Color(0xFF3F5DB3);
  final accentOrange = const Color(0xFFFF7A36);
  final bgColor = const Color(0xFFEAF3FA);
  final darkText = const Color(0xFF1F1F3D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Panggil fungsi syncSchedules di sini saat module jadwal sudah siap
      context.read<ScheduleViewModel>().syncSchedules(
        context.read<LoginViewModel>().user!,
      );

      // 1. Tarik ID User yang sedang aktif
      final userId = context.read<LoginViewModel>().user?.id;

      if (userId != null) {
        // 2. Lakukan sinkronisasi Bookmark
        context.read<AnnouncementViewModel>().syncBookmarks(userId);
        context.read<TaskViewModel>().syncTasks(
          context.read<LoginViewModel>().user!,
        );
      }

      NotificationService().initNotification();
    });
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              // Lakukan proses logout
              await context.read<LoginViewModel>().logout();

              if (context.mounted) {
                // Tendang kembali ke halaman Login dan hapus seluruh tumpukan halaman
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
    //MENGAMBIL VIEWMODEL DARI PROVIDER (Sesuai dengan main.dart)
    final announcementViewModel = context.watch<AnnouncementViewModel>();
    final taskViewModel = context.watch<TaskViewModel>();
    final scheduleViewModel = context.watch<ScheduleViewModel>();

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
                    _home(announcementViewModel), // Tab 0: Home
                    _schedule(scheduleViewModel), // Tab 1: Jadwal
                    _tasks(taskViewModel), // Tab 2: Tugas
                    _bookmark(), // Tab 3: Bookmark
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

    // 1. Ambil Nama (Sekarang dijamin muncul karena AuthRepository & MahasiswaModel sudah sinkron)
    final namaLengkap = user?.nama ?? "Mahasiswa";

    // 2. Ambil Data Akademik dari Model secara aman (Type-Safe)
    final namaKelas = user?.profilMahasiswa?.kelas?.namaKelas ?? "-";
    final prodi =
        user?.profilMahasiswa?.kelas?.namaProdi ??
        user?.profilMahasiswa?.kelas?.idProdi ??
        "-";
    final angkatan = user?.profilMahasiswa?.kelas?.angkatan?.toString() ?? "-";

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
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      namaLengkap,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildInfoBadge("Kelas: $namaKelas"),
                        const SizedBox(width: 6),
                        _buildInfoBadge("Prodi: $prodi"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              // --- Tombol Logout ---
              GestureDetector(
                onTap: () => _handleLogout(context),
                child: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // --- Indikator Status Online / Offline ---
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              // Secara default kita anggap online, sampai stream mendeteksi offline
              bool isOffline = false;

              if (snapshot.hasData) {
                isOffline = snapshot.data!.contains(ConnectivityResult.none);
              }

              return AnimatedContainer(
                duration: const Duration(
                  milliseconds: 300,
                ), // Efek transisi warna yang halus
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // Jika offline berubah merah redup, jika online hijau redup
                  color: isOffline
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOffline ? "Offline" : "Online",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 💡 Fungsi Helper untuk membuat kotak Badge Informasi agar kode di atas tidak terlalu panjang
  Widget _buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ================= HOME / PENGUMUMAN =================
  Widget _home(AnnouncementViewModel viewModel) {
    final user = context.read<LoginViewModel>().user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.setUserRole(user?.role ?? 'MAHASISWA');
    });

    return RefreshIndicator(
      onRefresh: () async {
        await viewModel.syncOfflineActions();
        await viewModel.syncAnnouncements();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pengumuman Terbaru",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter Horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: viewModel.filters.map((filter) {
                final isActive = viewModel.selectedFilter == filter;
                return GestureDetector(
                  onTap: () => viewModel.setFilter(filter),
                  child: _chip(filter, isActive),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 15),

          // Daftar Pengumuman Dinamis
          if (viewModel.isLoading && viewModel.announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (viewModel.announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  "Tidak ada pengumuman.",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...viewModel.announcements.map((data) {
              return AnnouncementCard(
                announcement: data,
                isLecturer: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AnnouncementDetailPage(announcement: data),
                    ),
                  );
                },
              );
            }).toList(),

          const SizedBox(
            height: 80,
          ), // Padding bawah agar tidak tertutup nav bar
        ],
      ),
    );
  }

  // ================= JADWAL =================
  Widget _schedule(ScheduleViewModel viewModel) {
    final grouped = viewModel.scheduleByDay;
    final user = context.read<LoginViewModel>().user;

    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) {
          await viewModel.syncSchedules(user);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text(
            "Jadwal Kuliah",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Semester Genap 2025/2026",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
      
          // Jadwal Hari Ini
          _todayCard(viewModel),
          const SizedBox(height: 20),
      
          // Loading indicator
          if (viewModel.isLoading)
            const Center(child: CircularProgressIndicator()),
      
          // Error message
          if (viewModel.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      
          // Kosong
          if (!viewModel.isLoading && grouped.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 50,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Belum ada jadwal tersedia.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
      
          // Jadwal per Hari
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...entry.value.map((s) => _scheduleItem(s)),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _todayCard(ScheduleViewModel viewModel) {
    final todayList = viewModel.todaySchedules;
    const hariMap = {
      1: 'SENIN',
      2: 'SELASA',
      3: 'RABU',
      4: 'KAMIS',
      5: 'JUMAT',
      6: 'SABTU',
      7: 'MINGGU',
    };
    final hariIni = hariMap[DateTime.now().weekday] ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, primaryBlue.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                "Hari Ini — $hariIni",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${todayList.length} MK",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todayList.isEmpty)
            const Text(
              "Tidak ada kuliah hari ini 🎉",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            )
          else
            ...todayList.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.namaMatkul,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${s.jamMulai} – ${s.jamSelesai} • ${s.ruangan}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scheduleItem(ScheduleModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Jam
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  s.jamMulai,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    fontSize: 12,
                  ),
                ),
                Text(
                  s.jamSelesai,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.namaMatkul,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkText,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.namaDosen,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.room_outlined,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.ruangan,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Indikator warna kanan
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
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

  // ================= TASK / TUGAS =================
  Widget _tasks(TaskViewModel viewModel) {
    final allTasks = viewModel.tasks;
    final user = context.read<LoginViewModel>().user;

    return RefreshIndicator(
      onRefresh: () async {
        await viewModel.syncTasks(user!);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daftar Tugas",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (allTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 50, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      "Tidak ada tugas. Selamat bersantai!",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ...allTasks
                .map(
                  (task) => StudentTaskCard(task: task, viewModel: viewModel),
                )
                .toList(),
        ],
      ),
    );
  }

  // ================= BOOKMARK =================
  Widget _bookmark() {
    // ValueListenableBuilder akan membuat halaman ini otomatis ter-refresh (rebuild)
    // setiap kali ada data baru yang masuk/keluar dari kotak 'bookmarks' di Hive.
    return ValueListenableBuilder<Box<AnnouncementModel>>(
      valueListenable: Hive.box<AnnouncementModel>('bookmarks').listenable(),
      builder: (context, box, _) {
        // Ambil datanya dan urutkan dari yang paling baru
        final bookmarkedItems = box.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            Text(
              "Pengumuman Tersimpan",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 20),

            // Jika kosong, tampilkan pesan ramah
            if (bookmarkedItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Belum ada pengumuman yang disimpan.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            // Jika ada isinya, panggil widget _announcement untuk menggambar kartunya
            else
              ...bookmarkedItems.map((data) {
                return AnnouncementCard(
                  announcement: data,
                  isLecturer: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnnouncementDetailPage(announcement: data),
                      ),
                    );
                  },
                );
              }).toList(),

            const SizedBox(
              height: 100,
            ), // Spasi agar tidak tertutup bottom navbar
          ],
        );
      },
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
          _navItem(Icons.home, 0),
          _navItem(Icons.calendar_today, 1),
          _navItem(Icons.check_box, 2),
          _navItem(Icons.bookmark, 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedScale(
          scale: isActive ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Icon(
            icon,
            size: 24,
            color: isActive ? primaryBlue : const Color(0xFFB0B7C3),
          ),
        ),
      ),
    );
  }
}
