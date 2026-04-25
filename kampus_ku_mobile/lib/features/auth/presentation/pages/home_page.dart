import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kampus_ku_mobile/features/auth/data/models/schedule_local_model.dart';
import 'package:kampus_ku_mobile/features/auth/data/services/schedule_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final primaryBlue = const Color(0xFF3F5DB3);
  final accentOrange = const Color(0xFFFF7A36);
  final bgColor = const Color(0xFFEAF3FA);
  final darkText = const Color(0xFF1F1F3D);

  final scheduleService = ScheduleService();
  List<ScheduleLocalModel> schedules = [];

  void syncSchedules() async {
    final apiData = await scheduleService.getSchedules();

    final box = Hive.box<ScheduleLocalModel>('schedules');

    for (var item in apiData) {
      final schedule = ScheduleLocalModel(
        id: item['id'],
        namaMk: item['nama_mk'],
        hari: item['hari'],
        jamMulai: item['jam_mulai'],
        jamSelesai: item['jam_selesai'],
        ruangan: item['ruangan'],
        dosen: item['nama_dosen'],
      );

      await box.put(schedule.id, schedule);
    }

    print("SYNC DONE: ${box.values.toList()}");

    loadSchedulesFromHive();
  }

  void loadSchedulesFromHive() {
    final box = Hive.box<ScheduleLocalModel>('schedules');

    setState(() {
      schedules = box.values.toList();
    });

    print("LOADED FROM HIVE: $schedules");
  }

  @override
  void initState() {
    super.initState();
    syncSchedules();
  }

  @override
  Widget build(BuildContext context) {
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
                  children: [_home(), _schedule(), _tasks(), _bookmark()],
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
  Widget _home() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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

        _schedulePreviewCard(),

        const SizedBox(height: 25),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Pengumuman Terbaru",
              style: TextStyle(fontWeight: FontWeight.bold, color: darkText),
            ),
            Text(
              "Lihat Semua >",
              style: TextStyle(color: primaryBlue, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            _chip("Semua", true),
            _chip("Jurusan TKI", false),
            _chip("Umum", false),
          ],
        ),

        const SizedBox(height: 10),

        _announcement(true),
        _announcement(false),
        _announcement(false),
      ],
    );
  }

  Widget _schedulePreviewCard() {
    if (schedules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final s = schedules.first;

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

  Widget _announcement(bool important) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(
            color: important ? accentOrange : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Perubahan Ruangan PBO",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "Perkuliahan dipindah ke Lab RPL",
            style: TextStyle(color: darkText.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  // ================= SCHEDULE =================
  Widget _schedule() {
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
