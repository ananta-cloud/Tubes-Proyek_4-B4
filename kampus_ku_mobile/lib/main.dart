import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/data/services/schedule_service.dart';

void main() {
  runApp(const MyApp());
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
