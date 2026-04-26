import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Pastikan import ini sesuai dengan lokasi file Anda
import 'package:kampus_ku_mobile/features/schedule/schedule_page.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
import 'package:kampus_ku_mobile/controller/announcement_controller.dart';
import 'package:kampus_ku_mobile/features/announcements/announcements_page.dart';
import 'package:kampus_ku_mobile/features/announcements/bookmarks_page.dart';
import 'package:kampus_ku_mobile/features/announcements/announcement_detail_page.dart';
// import 'package:kampus_ku_mobile/features/schedule/request_schedule_page.dart'; 

class DosenMainPage extends StatefulWidget {
  const DosenMainPage({super.key});

  @override
  State<DosenMainPage> createState() => _DosenMainPageState();
}

class _DosenMainPageState extends State<DosenMainPage> {
  int currentIndex = 0;

  final primaryBlue = const Color(0xFF3F5DB3);
  final accentOrange = const Color(0xFFFF7A36);
  final bgColor = const Color(0xFFEAF3FA);
  final darkText = const Color(0xFF1F1F3D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sinkronisasi otomatis saat Dosen masuk
      context.read<ScheduleController>().syncSchedules();
      context.read<AnnouncementController>().syncAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleController = context.watch<ScheduleController>();
    final announcementController = context.watch<AnnouncementController>();

    return Scaffold(
      extendBody: true, // Biar navbar floating menyatu dengan background
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false, // Biar listview bisa nembus ke bawah navbar
        child: Column(
          children: [
            _header(),
            Expanded(
              // KITA HAPUS AnimatedSwitcher & ValueKey AGAR HALAMAN TIDAK HANCUR SAAT PINDAH TAB
              child: IndexedStack(
                index: currentIndex,
                children: [
                  _dashboardDosen(scheduleController, announcementController), // 0
                  const SchedulePage(), // 1
                  const AnnouncementPage(), // 2
                  const Center(child: Text("Fitur Request Jadwal dalam pengembangan")), // 3
                  const BookmarksAnnouncementPage(), // 4
                ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                      "Portal Dosen Polban",
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
                      decoration: const BoxDecoration(
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

  // ================= DASHBOARD DOSEN =================
  Widget _dashboardDosen(ScheduleController sController, AnnouncementController aController) {
    // PERBAIKAN: SEMUA LOGIKA DITARUH DI SINI, SEBELUM RETURN LISTVIEW

    // 1. TENTUKAN HARI INI
    String getTodayString() {
      const days = ['minggu', 'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];
      return days[DateTime.now().weekday % 7];
    }

    String todayStr = getTodayString();

    // 2. FILTER JADWAL HARI INI & URUTKAN JAM TERAWAL
    var todaySchedules = sController.schedules.where((s) => s.hari.toLowerCase() == todayStr).toList();
    todaySchedules.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));

    // 3. BUAT PESAN DINAMIS
    String scheduleMessage = todaySchedules.isNotEmpty
        ? "Jadwal mengajar pertama hari ini jam ${todaySchedules.first.jamMulai} di ruang ${todaySchedules.first.ruangan}."
        : "Tidak ada jadwal mengajar hari ini. Selamat beristirahat!";

    // BARU KITA RETURN UI-NYA
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          "Halo, Bapak/Ibu Dosen! 👋",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
        ),
        const SizedBox(height: 5),
        
        Text(
          scheduleMessage, // Teks Dinamis
          style: TextStyle(color: darkText.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),

        _schedulePreviewCard(sController),

        const SizedBox(height: 25),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Pengumuman Terbaru",
              style: TextStyle(fontWeight: FontWeight.bold, color: darkText),
            ),
            GestureDetector(
              onTap: () => setState(() => currentIndex = 2), // Pindah ke Tab Info
              child: Text(
                "Lihat Semua >",
                style: TextStyle(color: primaryBlue, fontSize: 12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Preview Pengumuman
        if (aController.isLoading && aController.announcements.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (aController.announcements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Belum ada pengumuman terbaru."),
          )
        else
          ...aController.announcements.take(3).map((ann) {
            return GestureDetector(
              onTap: () {
                // Navigasi ke halaman detail saat diklik
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementDetailPage(announcement: ann),
                  ),
                );
              },
              child: _announcementPreview(
                ann.judul,
                ann.kategori.isNotEmpty ? ann.kategori.join(', ') : 'Umum', 
                // Cek penting berdasarkan tanggal ATAU properti isImportant
                ann.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 3))) ,
              ),
            );
          }),
      ],
    );
  }

  // ================= UI COMPONENTS =================
  Widget _schedulePreviewCard(ScheduleController controller) {
    if (controller.isLoading && controller.schedules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.schedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text("Tidak ada jadwal mengajar hari ini")),
      );
    }

    final s = controller.schedules.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(blurRadius: 12, offset: const Offset(0, 5), color: Colors.black.withOpacity(0.05)),
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
              Text(s.namaMk, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("${s.jamMulai} - ${s.jamSelesai}"),
              Text(s.ruangan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _announcementPreview(String title, String subtitle, bool important) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: important ? accentOrange : Colors.transparent, width: 4)),
        boxShadow: [
          BoxShadow(blurRadius: 8, offset: const Offset(0, 2), color: Colors.black.withOpacity(0.04)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(color: darkText.withOpacity(0.6), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ================= NAVBAR 5 MENU =================
  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.all(16), // Memberikan efek floating
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(blurRadius: 20, offset: const Offset(0, 10), color: Colors.black.withOpacity(0.15)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
        children: [
          _navItem(Icons.home, 0),
          _navItem(Icons.calendar_today, 1),
          _navItem(Icons.campaign, 2), 
          _navItem(Icons.swap_horiz, 3), 
          _navItem(Icons.bookmark, 4),
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
          child: Icon(icon, size: 24, color: isActive ? primaryBlue : const Color(0xFFB0B7C3)),
        ),
      ),
    );
  }
}