import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// ================= IMPORT DATABASE =================
import 'core/network/mongo_database.dart';

// ================= IMPORT UI =================
import 'features/auth/views/login_page.dart';

// ================= IMPORT MODELS =================
import 'data/models/schedule_local_model.dart';
import 'data/models/announcement_model.dart';
import 'data/models/task_model.dart';
import 'features/admin_tu/master_matkul/models/matkul_model.dart';
import 'features/admin_tu/schedules/models/schedule_model.dart';

// ================= IMPORT SERVICES & REPOS =================
import 'data/services/schedule_service.dart';
import 'data/services/announcement_service.dart';
import 'data/repositories/auth_repository.dart';

// ================= IMPORT VIEWMODELS =================
import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/dosen/schedules/viewmodels/schedule_controller.dart';
import 'features/mahasiswa/tasks/tasks/viewmodels/task_viewmodel.dart';
import 'package:sigma/features/mahasiswa/schedules/viewmodels/schedule_viewmodel.dart';
import 'package:sigma/features/admin_tu/main/viewmodels/admin_main_viewodel.dart';
import 'package:sigma/features/admin_tu/schedules/viewmodels/admin_schedule_viewmodel.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/admin_tu/announcements/viewmodels/admin_announcement_viewmodel.dart';
import 'package:sigma/features/admin_tu/master_matkul/viewmodels/admin_matkul_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  await dotenv.load(fileName: "assets/env/.env");
  await initializeDateFormatting('id_ID', null);
  print("MONGO_URL: ${dotenv.env['MONGO_URL']}");

  // Initialize Hive
  await Hive.initFlutter();

  // ── Register Adapters ──────────────────────────────────────────────────────
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
    Hive.registerAdapter(MatkulModelAdapter()); // ← baru
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(ScheduleModelAdapter()); // ← baru
  }

  // Connect MongoDB
  try {
    await MongoDatabase.connect();
  } catch (e) {
    print("Mode Offline terdeteksi saat startup. Mengabaikan koneksi Mongo.");
  }

  // ── Open Boxes ─────────────────────────────────────────────────────────────
  // Mahasiswa / shared
  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements');
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<AnnouncementModel>('bookmarks');

  // Admin TU — Pengumuman
  await Hive.openBox<AnnouncementModel>('admin_announcements');
  await Hive.openBox<Map>('announcement_queue');

  // Admin TU — Matkul
  await Hive.openBox<MatkulModel>('admin_matkul');
  await Hive.openBox<Map>('matkul_queue');
  await Hive.openBox('admin_prodi'); // dynamic map, no type

  // Admin TU — Jadwal
  await Hive.openBox<ScheduleModel>('admin_schedules');
  await Hive.openBox<Map>('schedule_queue');

  runApp(
    MultiProvider(
      providers: [
        // 1. Auth ViewModel
        ChangeNotifierProvider(create: (_) => LoginViewModel(AuthRepository())),

        // 2. Schedule Controller (Dosen)
        ChangeNotifierProvider(
          create: (_) => ScheduleController(ScheduleService()),
        ),

        // 3. Task Controller (Mahasiswa)
        ChangeNotifierProvider(create: (_) => TaskViewModel()),

        // 4. Announcement ViewModel (Mahasiswa & Dosen — shared)
        ChangeNotifierProvider(
          create: (_) => AnnouncementViewModel(AnnouncementService()),
        ),

        // 5. Schedule ViewModel (Mahasiswa)
        ChangeNotifierProvider(create: (_) => ScheduleViewModel()),

        // 6. Admin TU — Main
        ChangeNotifierProvider(create: (_) => AdminMainViewModel()),

        // 7. Admin TU — Jadwal
        ChangeNotifierProvider(create: (_) => AdminScheduleViewModel()),

        // 8. Admin TU — Pengumuman (offline-first, viewmodel terpisah)
        ChangeNotifierProvider(create: (_) => AdminAnnouncementViewModel()),

        // 9. Admin TU — Master Matkul
        ChangeNotifierProvider(create: (_) => AdminMatkulViewModel()),
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
      home: LoginPage(),
    );
  }
}
