import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'features/auth/presentation/pages/login_page.dart';

import 'features/schedule/data/services/schedule_service.dart';
import 'features/schedule/data/models/schedule_local_model.dart';
import 'features/schedule/controller/schedule_controller.dart';

import 'features/announcements/controller/announcement_controller.dart';
import 'features/announcements/data/models/announcement_local_model.dart';
import 'features/announcements/data/services/announcement_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ========================================================
  // 1. PENGAMAN HOT-RESTART FLUTTER WEB
  // ========================================================
  final scheduleAdapter = ScheduleLocalModelAdapter();
  if (!Hive.isAdapterRegistered(scheduleAdapter.typeId)) {
    Hive.registerAdapter(scheduleAdapter);
  }

  final announcementAdapter = AnnouncementLocalModelAdapter();
  if (!Hive.isAdapterRegistered(announcementAdapter.typeId)) {
    Hive.registerAdapter(announcementAdapter);
  }

  // ========================================================
  // 2. BUKA BOX (Pastikan tidak ada duplikat)
  // ========================================================
  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementLocalModel>('announcements');
  await Hive.openBox<AnnouncementLocalModel>('bookmarks');

  runApp(
    MultiProvider(
      providers: [
        // ========================================================
        // 3. GUNAKAN ChangeNotifierProvider BUKAN Provider.value
        // ========================================================
        ChangeNotifierProvider(
          create: (_) => ScheduleController(ScheduleService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AnnouncementController(AnnouncementService()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(), // ⬅️ tetap mulai dari login
    );
  }
}

// =========================
// ✅ HOME PAGE (TEST API)
// =========================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  void fetchSchedules() async {
    final data = await scheduleService.getSchedules();
    print("SCHEDULE DATA: $data");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: const Center(child: Text("Login berhasil 🎉")),
    );
  }
}