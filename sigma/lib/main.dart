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
import 'features/admin_tu/announcements/models/announcement_model.dart';
import 'data/models/task_model.dart';

// ================= IMPORT SERVICES & REPOS =================
import 'data/services/schedule_service.dart';
import 'data/repositories/auth_repository.dart';

// ================= IMPORT VIEWMODELS =================
import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/dosen/schedules/viewmodels/schedule_viewmodel.dart';
import 'features/mahasiswa/tasks/tasks/viewmodels/task_viewmodel.dart';
import 'package:sigma/features/mahasiswa/schedules/viewmodels/schedule_viewmodel.dart';
import 'package:sigma/features/admin_tu/main/viewmodels/admin_main_viewodel.dart';
import 'package:sigma/features/admin_tu/schedules/viewmodels/admin_schedule_viewmodel.dart';
import 'features/admin_tu/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/admin_tu/master_matkul/viewmodels/admin_matkul_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  await dotenv.load(fileName: "assets/env/.env");
  await initializeDateFormatting('id_ID', null);
  print("MONGO_URL: ${dotenv.env['MONGO_URL']}");

  // Connect MongoDB
  await MongoDatabase.connect();

  // Initialize Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ScheduleLocalModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AnnouncementModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(TaskModelAdapter());
  }

  // OPEN BOXES
  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements');
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<AnnouncementModel>('bookmarks');

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

        // 4. Announcement ViewModel
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),

        ChangeNotifierProvider(create: (_) => ScheduleViewModel()),

        ChangeNotifierProvider(create: (_) => AdminMainViewModel()),

        ChangeNotifierProvider(create: (_) => AdminScheduleViewModel()),

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
