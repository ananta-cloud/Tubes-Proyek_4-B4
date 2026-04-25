import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kampus_ku_mobile/features/auth/data/models/schedule_local_model.dart';
import 'package:kampus_ku_mobile/features/auth/data/services/schedule_service.dart';

// Import komponen yang sudah dipisah
import 'dashboard.dart';
import 'schedules/schedules.dart';
import 'schedules/requests.dart';
import 'announcements/announcements.dart';
import 'announcements/bookmarks.dart';

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

  final scheduleService = ScheduleService();
  List<ScheduleLocalModel> schedules = [];

  @override
  void initState() {
    super.initState();
    syncSchedules();
  }

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
    loadSchedulesFromHive();
  }

  void loadSchedulesFromHive() {
    final box = Hive.box<ScheduleLocalModel>('schedules');
    setState(() {
      schedules = box.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
                    DashboardDosen(schedules: schedules),
                    SchedulesDosen(schedules: schedules),
                    const AnnouncementsDosen(),
                    const RequestsDosen(),
                    const BookmarksDosen()
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

  Widget _header() {
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SIGMA", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text("Portal Dosen", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Stack(
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: accentOrange, shape: BoxShape.circle),
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
                Text("Online - Tersinkronisasi", style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(blurRadius: 20, offset: const Offset(0, 10), color: Colors.black.withOpacity(0.15))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.dashboard_rounded, "Home", 0),
          _navItem(Icons.calendar_month_rounded, "Jadwal", 1),
          _navItem(Icons.campaign_rounded, "Info", 2),
          _navItem(Icons.edit_calendar_rounded, "Request", 3),
          _navItem(Icons.bookmark_rounded, "Simpan", 4),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(icon, size: 22, color: isActive ? primaryBlue : const Color(0xFFB0B7C3)),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold))
            ]
          ],
        ),
      ),
    );
  }
}