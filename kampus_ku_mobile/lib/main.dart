import 'package:flutter/material.dart';
import 'presentation/pages/login_page.dart';
import 'data/services/schedule_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/schedule_local_model.dart';
import 'data/models/announcement_model.dart';
import 'package:provider/provider.dart';
import 'controller/schedule_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ScheduleLocalModelAdapter());
  Hive.registerAdapter(AnnouncementModelAdapter());

  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ScheduleController(ScheduleService()),
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
      title: 'KampusKu',
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
