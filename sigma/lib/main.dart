import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sigma/data/services/dosen_request_service.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';

// ================= IMPORT DATABASE =================
import 'core/network/mongo_database.dart';

// ================= IMPORT UI =================
import 'features/auth/views/login_page.dart';
import 'package:sigma/features/dosen/schedules/views/jadwal_mengajar_page.dart';
import 'features/auth/views/auth_gate.dart';

// ================= IMPORT MODELS =================
import 'data/models/schedule_local_model.dart';
import 'data/models/announcement_model.dart';
import 'data/models/task_model.dart';
import 'data/models/schedule_request_model.dart';
import 'data/models/pengajaran_model.dart';

// ================= IMPORT SERVICES & REPOS =================
import 'data/services/schedule_service.dart';
import 'data/services/announcement_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/schedule_request_service.dart';

// ================= IMPORT VIEWMODELS =================
import 'features/auth/viewmodels/login_viewmodel.dart';
// import 'features/dosen/schedules/viewmodels/schedule_viewmodel.dart';
import 'features/mahasiswa/tasks/tasks/viewmodels/task_viewmodel.dart';
import 'features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/mahasiswa/schedules/viewmodels/schedule_viewmodel.dart';
import 'package:sigma/features/admin_tu/main/viewmodels/admin_main_viewodel.dart';
import 'package:sigma/features/admin_tu/schedules/viewmodels/admin_schedule_viewmodel.dart';
import 'features/admin_tu/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/admin_tu/master_matkul/viewmodels/admin_matkul_viewmodel.dart';
import 'features/penjadwalan/viewmodels/schedule_request_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
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
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(DetailPerubahanAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ScheduleRequestModelAdapter());
  }

  // OPEN BOXES
  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements');
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<AnnouncementModel>('bookmarks');
  await Hive.openBox('pending_requests');
  await Hive.openBox('schedule_cache');
  await Hive.openBox('cancel_queue');
  await Hive.openBox<PengajaranModel>('pengajaran');

  runApp(
    MultiProvider(
      providers: [
        // 1. Auth ViewModel (Wajib ada untuk LoginPage)
        ChangeNotifierProvider(create: (_) => LoginViewModel(AuthRepository())),

        // 2. Schedule Controller
        // ChangeNotifierProvider(
        //   create: (_) => ScheduleController(ScheduleService()),
        // ),

        // 3. Task Controller
        ChangeNotifierProvider(create: (_) => TaskViewModel()),

        // 4. Announcement ViewModel
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),

        ChangeNotifierProvider(create: (_) => ScheduleViewModel()),

        ChangeNotifierProvider(create: (_) => AdminMainViewModel()),

        ChangeNotifierProvider(create: (_) => AdminScheduleViewModel()),

        ChangeNotifierProvider(create: (_) => AdminMatkulViewModel()),

        ChangeNotifierProvider(
          create: (_) => DosenRequestController(DosenRequestService()),
        ),
        // ChangeNotifierProvider(
        //   create: (_) => ScheduleController(ScheduleService()),
        // ),
        ChangeNotifierProvider(
          create: (_) => ScheduleRequestController(ScheduleRequestService()),
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
