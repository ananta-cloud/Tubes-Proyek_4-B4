import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// ================= IMPORT DATABASE =================
import 'core/network/mongo_database.dart';

// ================= IMPORT UI =================
import 'features/auth/views/login_page.dart';
import 'features/auth/views/auth_gate.dart';

// ================= IMPORT MODELS =================
import 'data/models/schedule_local_model.dart';
import 'data/models/announcement_model.dart';
import 'data/models/task_model.dart';
import 'data/models/pengajaran_model.dart';

// ================= IMPORT SERVICES & REPOS =================
import 'data/services/schedule_service.dart';
import 'data/services/announcement_service.dart';
import 'data/repositories/auth_repository.dart';

// ================= IMPORT VIEWMODELS =================
import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/dosen/schedules/viewmodels/schedule_controller.dart';
import 'features/mahasiswa/tasks/tasks/viewmodels/task_viewmodel.dart';
import 'features/announcements/viewmodels/announcement_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  await dotenv.load(fileName: ".env");
  print("MONGO_URL: ${dotenv.env['MONGO_URL']}");

  // Initialize Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ScheduleLocalModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AnnouncementModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TaskModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(PengajaranModelAdapter());
  }

  MongoDatabase.connect()
      .then((_) {
        debugPrint("✅ Background Mongo Terhubung!");
      })
      .catchError((e) {
        debugPrint("❌ Background Mongo Gagal: $e");
      });

  // OPEN BOXES
  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements');
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<AnnouncementModel>('bookmarks');
  await Hive.openBox<PengajaranModel>('pengajaran');

  runApp(
    MultiProvider(
      providers: [
        // 1. Auth ViewModel (Wajib ada untuk LoginPage)
        ChangeNotifierProvider(create: (_) => LoginViewModel(AuthRepository())),

        // 2. Schedule Controller
        ChangeNotifierProvider(
          create: (_) => ScheduleController(ScheduleService()),
        ),

        // 3. Task Controller
        ChangeNotifierProvider(create: (_) => TaskViewModel()),

        // 4. Announcement ViewModel (Satu ViewModel, dipakai 2 View Dosen/Mhs) ⬅️ UPDATE DI SINI
        ChangeNotifierProvider(
          create: (_) => AnnouncementViewModel(AnnouncementService()),
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
      title: 'Sigma',
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}
