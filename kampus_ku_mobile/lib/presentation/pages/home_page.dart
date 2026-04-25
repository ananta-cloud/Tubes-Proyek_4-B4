import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
import 'package:kampus_ku_mobile/controller/announcement_controller.dart';
import 'package:kampus_ku_mobile/data/repositories/announcement_repository.dart';
import 'package:kampus_ku_mobile/data/models/announcement_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  late final AnnouncementController _controller;

  final primaryBlue = const Color(0xFF3F5DB3);
  final accentOrange = const Color(0xFFFF7A36);
  final bgColor = const Color(0xFFEAF3FA);
  final darkText = const Color(0xFF1F1F3D);

  @override
  void initState() {
    super.initState();

    final repository = AnnouncementRepository();
    _controller = AnnouncementController(repository: repository);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleController>().syncSchedules();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();

    return Scaffold(
      extendBody: true, // 🔥 biar navbar floating
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: IndexedStack(
                  key: ValueKey(currentIndex),
                  index: currentIndex,
                  children: [
                    _home(controller),
                    _schedule(controller),
                    _tasks(),
                    _bookmark(),
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
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SIGMA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "D3 Teknik Informatika",
                      style: TextStyle(color: Colors.white70),
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
                        color: Color(0xFFFF7A36),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
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

  // ================= HOME =================
  Widget _home(ScheduleController controller) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ListView(
          children: [
            Text(
              "Halo, Fahraj! 👋",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Jadwal pertamamu hari ini jam 07:00.",
              style: TextStyle(color: darkText.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),

            _schedulePreviewCard(controller),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pengumuman Terbaru",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                Text(
                  "Lihat Semua >",
                  style: TextStyle(color: primaryBlue, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: _controller.filters.map((namaFilter) {
                return GestureDetector(
                  onTap: () => _controller.setFilter(namaFilter),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _chip(
                      namaFilter,
                      _controller.selectedFilter ==
                          namaFilter, // Aktif jika sama dengan filter yang dipilih
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            if (_controller.announcements.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    "Belum ada pengumuman.",
                    style: TextStyle(color: darkText),
                  ),
                ),
              ),

            // Menggambar pengumuman sebanyak data yang ada di controller
            ..._controller.announcements.map((pengumuman) {
              // Karena data pengumuman dinamis, kamu perlu memodifikasi fungsi _announcement
              // agar menerima objek AnnouncementModel, bukan cuma boolean.
              return _announcement(pengumuman);
            }),

            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _schedulePreviewCard(ScheduleController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.schedules.isEmpty) {
      return const Text("Tidak ada jadwal");
    }

    final s = controller.schedules.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book, color: accentOrange),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.namaMk,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text("${s.jamMulai} - ${s.jamSelesai}"),
              Text(s.ruangan),
            ],
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
      ),
      child: Text(
        text,
        style: TextStyle(color: active ? Colors.white : darkText, fontSize: 12),
      ),
    );
  }

  // Widget _announcement(AnnouncementModel data) {
  //   final primaryBlue = const Color(0xFF3F5DB3);
  //   final accentOrange = const Color(0xFFFF7A36);
  //   final darkText = const Color(0xFF1F1F3D);
    
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(18),
  //       border: Border(
  //         left: BorderSide(
  //           color: data.isImportant ? accentOrange : Colors.transparent,
  //           width: 4,
  //         ),
  //       ),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(data.judul, style: TextStyle(fontWeight: FontWeight.bold)),
  //         const SizedBox(height: 5),
  //         Text(data.isi, style: TextStyle(color: darkText.withOpacity(0.6))),
  //       ],
  //     ),
  //   );
  // }

  // 1. Pastikan fungsi menerima objek AnnouncementModel dari Hive
  Widget _announcement(AnnouncementModel data) {
    final primaryBlue = const Color(0xFF3F5DB3);
    final accentOrange = const Color(0xFFFF7A36);
    final darkText = const Color(0xFF1F1F3D);

    // 2. Logika Warna Pengganti isImportant
    // Cek apakah di dalam array kategori terdapat tag tertentu yang dianggap penting
    final bool isHighlight = data.kategori.contains('BEASISWA') || 
                            data.kategori.contains('LOMBA');

    return GestureDetector(
      onTap: () {
        // // Navigasi ke halaman detail
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => AnnouncementDetailPage(announcement: data),
        //   ),
        // );
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
                // ==========================================
                // GARIS INDIKATOR (Pengganti isImportant)
                // ==========================================
                Container(
                  width: 6,
                  color: isHighlight ? accentOrange : primaryBlue.withOpacity(0.5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================
                        // HEADER: Target Audience & Tanggal
                        // ==========================================
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
                                // Mengambil target_audience (cth: 'PRODI_MAHASISWA')
                                data.targetAudience.replaceAll('_', ' '), 
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            Text(
                              "${data.createdAt.day}/${data.createdAt.month}/${data.createdAt.year}",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ==========================================
                        // JUDUL PENGUMUMAN
                        // ==========================================
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

                        // ==========================================
                        // LIST KATEGORI (Tag/Chip kecil di bawah judul)
                        // ==========================================
                        if (data.kategori.isNotEmpty)
                          Wrap(
                            spacing: 6, // Jarak antar tag
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

                        // ==========================================
                        // PENERBIT
                        // ==========================================
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Text(
                              data.namaPublisher,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  // ================= SCHEDULE =================
  Widget _schedule(ScheduleController controller) {
    //  LOADING STATE
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    //  EMPTY STATE
    if (controller.schedules.isEmpty) {
      return const Center(
        child: Text("Tidak ada jadwal", style: TextStyle(fontSize: 16)),
      );
    }

    //  DATA STATE
    final schedules = controller.schedules;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          "Jadwal Kuliah",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            _day("Senin", "18", true),
            _day("Selasa", "19", false),
            _day("Rabu", "20", false),
            _day("Kamis", "21", false),
          ],
        ),

        const SizedBox(height: 20),

        ...schedules.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border(left: BorderSide(color: primaryBlue, width: 4)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${s.jamMulai} - ${s.jamSelesai}"),
                const SizedBox(height: 5),
                Text(
                  s.namaMk,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text("${s.ruangan} - ${s.dosen}"),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _day(String day, String date, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: active ? Colors.white : darkText,
              fontSize: 12,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              color: active ? Colors.white : darkText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= TASK =================
  Widget _tasks() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          "Reminder Tugas",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 20),
        _task("Selesaikan Proposal Proyek 4", "Besok"),
        _task("Tugas UI/UX Figma", "Lusa"),
      ],
    );
  }

  Widget _task(String title, String deadline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_box_outline_blank),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(
            deadline,
            style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ================= BOOKMARK =================
  Widget _bookmark() {
    return const Center(child: Text("Pengumuman Tersimpan"));
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
            color: isActive
                ? primaryBlue
                : const Color(0xFFB0B7C3), // 🔥 FIX ICON
          ),
        ),
      ),
    );
  }
}
