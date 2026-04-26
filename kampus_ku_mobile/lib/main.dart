import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import Auth & Pages
import 'package:kampus_ku_mobile/presentation/pages/login_page.dart';

// Import Schedule
import 'package:kampus_ku_mobile/data/services/schedule_service.dart';
import 'package:kampus_ku_mobile/data/models/schedule_local_model.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';

// Import Announcement 
import 'package:kampus_ku_mobile/data/services/announcement_service.dart';
import 'package:kampus_ku_mobile/data/models/announcement_model.dart';
import 'package:kampus_ku_mobile/controller/announcement_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pastikan file .env sudah didaftarkan di pubspec.yaml bagian assets
  await dotenv.load(fileName: ".env"); 

  await Hive.initFlutter();

  // 1. REGISTRASI ADAPTER HIVE
  Hive.registerAdapter(ScheduleLocalModelAdapter());
  Hive.registerAdapter(AnnouncementModelAdapter()); 

  // 2. BUKA BOX (LACI PENYIMPANAN OFFLINE)
  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements'); 
  await Hive.openBox<AnnouncementModel>('bookmarks');    

  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      title: 'KampusKu',
      debugShowCheckedModeBanner: false,
      home: LoginPage(), 
    );
  }
}