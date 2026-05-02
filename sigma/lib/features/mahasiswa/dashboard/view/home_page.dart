import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ==========================================
// 1. IMPORT DATA & MODELS
// ==========================================
import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/data/models/task_model.dart';

// ==========================================
// 2. IMPORT VIEWMODELS & VIEWS
// ==========================================
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/announcements/views/announcement_detail_page.dart';
import 'package:sigma/features/mahasiswa/tasks/tasks/viewmodels/task_viewmodel.dart';
import 'package:sigma/features/mahasiswa/tasks/tasks/views/task_page.dart';

// Catatan: Jika ScheduleViewModel sudah siap, uncomment ini:
// import 'package:sigma/features/mahasiswa/schedules/viewmodels/schedule_viewmodel.dart';

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
      // context.read<ScheduleController>().syncSchedules();

      // 1. Tarik ID User yang sedang aktif
      final userId = context.read<LoginViewModel>().user?.id;
      
      if (userId != null) {
        // 2. Lakukan sinkronisasi Bookmark
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
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
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
            child: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 MENGAMBIL VIEWMODEL DARI PROVIDER (Sesuai dengan main.dart)
    final announcementViewModel = context.watch<AnnouncementViewModel>();
    final taskViewModel = context.watch<TaskViewModel>();

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
                    const Center(child: Text("Halaman Jadwal (Segera Hadir)")), // Tab 1: Jadwal
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
    
    final namaLengkap = user?.nama ?? "Mahasiswa";
    
    // final listKata = namaLengkap.split(' ');

    // final namaPanggilan = (listKata.length > 1 && (listKata[0].toLowerCase() == 'muhammad' || listKata[0].toLowerCase() == 'm.')) 
    //     ? listKata[1] 
    //     : listKata[0];

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
                    Text(
                      "Selamat Datang,",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$namaLengkap",
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () => _handleLogout(context),
                child: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  "Online - Tersinkronisasi",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HOME / PENGUMUMAN =================
  Widget _home(AnnouncementViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        Text(
          "Jadwal pertamamu hari ini adalah",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 25),
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
            GestureDetector(
              onTap: () {
                // Aksi lihat semua (Bisa diarahkan ke halaman list penuh)
              },
              child: Text(
                "Lihat Semua >",
                style: TextStyle(color: primaryBlue, fontSize: 12),
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
          ...viewModel.announcements.map((data) => _announcement(data)).toList(),

        const SizedBox(height: 80), // Padding bawah agar tidak tertutup nav bar
      ],
    );
  }

  Widget _chip(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? primaryBlue : Colors.grey.shade300,
        ),
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

  Widget _announcement(AnnouncementModel data) {
    // Logika warna garis berdasarkan tingkat kepentingan
    Color indikatorWarna;
    switch (data.tingkatKepentingan) {
      case 'SANGAT PENTING':
        indikatorWarna = Colors.red;
        break;
      case 'PENTING':
        indikatorWarna = accentOrange;
        break;
      case 'LUMAYAN PENTING':
        indikatorWarna = Colors.amber;
        break;
      default:
        indikatorWarna = primaryBlue.withOpacity(0.5);
    }

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
                Container(
                  width: 6,
                  color: indikatorWarna,
                ),
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
                            children: data.kategori.map((kat) {
                              return Text(
                                "#$kat",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Text(
                              data.namaPublisher,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TASK / TUGAS =================
  Widget _tasks(TaskViewModel viewModel) {
    final allTasks = viewModel.tasks;

    return ListView(
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
            IconButton(
              icon: Icon(Icons.add_circle, color: accentOrange, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskPage(controller: viewModel),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

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
                  Text("Tidak ada tugas. Selamat bersantai!", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
        else
          ...allTasks.map((task) => _taskItem(viewModel, task)).toList(),
      ],
    );
  }

  Widget _taskItem(TaskViewModel viewModel, TaskModel task) {
    bool isTerlambat = task.status == 'TERLAMBAT' ||
        (task.deadline.isBefore(DateTime.now()) && task.status == 'BELUM');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskPage(
                  controller: viewModel,
                  taskToEdit: task,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => viewModel.toggleStatus(task),
                  child: Icon(
                    task.status == 'SELESAI' ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: task.status == 'SELESAI' ? Colors.green : accentOrange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.namaTugas,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: task.status == 'SELESAI' ? Colors.grey : darkText,
                          decoration: task.status == 'SELESAI' ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.namaMkSnapshot != null)
                        Text(
                          task.namaMkSnapshot!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${task.deadline.day}/${task.deadline.month}/${task.deadline.year}",
                      style: TextStyle(
                        color: isTerlambat && task.status != 'SELESAI' ? Colors.red : primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (!task.isSynced)
                      const Icon(Icons.cloud_off, size: 12, color: Colors.grey)
                  ],
                ),
              ],
            ),
          ),
        ),
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
                        Icon(Icons.bookmark_border, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text("Belum ada pengumuman yang disimpan.", style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
              // Jika ada isinya, panggil widget _announcement untuk menggambar kartunya
              else
                ...bookmarkedItems.map((data) => _announcement(data)).toList(),

              const SizedBox(height: 100), // Spasi agar tidak tertutup bottom navbar
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