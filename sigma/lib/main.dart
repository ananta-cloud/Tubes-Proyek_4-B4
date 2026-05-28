import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ================= IMPORT DATABASE =================
import 'core/network/mongo_database.dart';

// ================= IMPORT UI =================
import 'features/auth/views/login_page.dart';

// ================= IMPORT MODELS =================
import 'data/models/schedule_local_model.dart';
import 'data/models/announcement_model.dart';
import 'data/models/dosen_model.dart';
import 'data/models/task_model.dart';
import 'features/admin_tu/master_matkul/models/matkul_model.dart';
import 'features/admin_tu/schedules/models/schedule_model.dart';
import 'data/models/pengajaran_model.dart';

// ================= IMPORT SERVICES & REPOS =================
import 'data/services/schedule_service.dart';
import 'data/services/announcement_service.dart';
import 'data/repositories/auth_repository.dart';
import 'features/admin_tu/schedules/services/dosen_cache_service.dart';

// ================= IMPORT VIEWMODELS =================
import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/dosen/tasks/viewmodels/task_form_viewmodel.dart';
import 'features/dosen/schedules/viewmodels/schedule_controller.dart';
import 'features/mahasiswa/tasks/viewmodels/task_viewmodel.dart';
import 'package:sigma/features/mahasiswa/schedules/viewmodels/schedule_viewmodel.dart';
import 'package:sigma/features/admin_tu/main/viewmodels/admin_main_viewodel.dart';
import 'package:sigma/features/admin_tu/schedules/viewmodels/admin_schedule_viewmodel.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';
import 'package:sigma/features/announcements/viewmodels/admin_announcement_viewmodel.dart';
import 'package:sigma/features/admin_tu/master_matkul/viewmodels/admin_matkul_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
  print("MONGO_URL: ${dotenv.env['MONGO_URL']}");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ScheduleLocalModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AnnouncementModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TaskModelAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(MatkulModelAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ScheduleModelAdapter());
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(PengajaranModelAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(DosenModelAdapter());
  }

  // ── MongoDB ────────────────────────────────────────────────────────────────
  try {
    await MongoDatabase.connect();
  } catch (e) {
    print("Mode Offline terdeteksi saat startup.");
  }

  // ── Open Boxes ─────────────────────────────────────────────────────────────
  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements');
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<AnnouncementModel>('bookmarks');

  await Hive.openBox<AnnouncementModel>('admin_announcements');
  await Hive.openBox<Map>('announcement_queue');

  await Hive.openBox<MatkulModel>('admin_matkul');
  await Hive.openBox<Map>('matkul_queue');
  await Hive.openBox('admin_prodi');

  await Hive.openBox<ScheduleModel>('admin_schedules');
  await Hive.openBox<Map>('schedule_queue');
  await Hive.openBox<PengajaranModel>('pengajaran');
  await Hive.openBox<DosenModel>('dosen_box');

  // Buka box cache dosen — harus sebelum runApp agar parser bisa akses
  await DosenCacheService.openBox();

  // Isi cache dosen dari MongoDB (best-effort — tidak fatal jika offline)
  await DosenCacheService.warmUp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel(AuthRepository())),
        ChangeNotifierProvider(
          create: (_) => ScheduleController(ScheduleService()),
        ),
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => TaskFormViewModel()),
        ChangeNotifierProvider(
          create: (_) => AnnouncementViewModel(AnnouncementService()),
        ),
        ChangeNotifierProvider(create: (_) => ScheduleViewModel()),
        ChangeNotifierProvider(create: (_) => AdminMainViewModel()),
        ChangeNotifierProvider(create: (_) => AdminScheduleViewModel()),
        ChangeNotifierProvider(create: (_) => AdminAnnouncementViewModel()),
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
    return MaterialApp(
      title: 'Sigma',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      builder: (context, child) => _ConnectivityListener(child: child!),
    );
  }
}

// ── Connectivity Listener ──────────────────────────────────────────────────────
class _ConnectivityListener extends StatefulWidget {
  final Widget child;
  const _ConnectivityListener({required this.child});

  @override
  State<_ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends State<_ConnectivityListener> {
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((result) {
      final isOffline = (result as List).contains(ConnectivityResult.none);

      if (_wasOffline && !isOffline) {
        debugPrint(' Koneksi kembali online, memulai sync...');
        _syncAll();
      }
      _wasOffline = isOffline;
    });
  }

  Future<void> _syncAll() async {
    if (!mounted) return;
    await MongoDatabase.ensureConnected();

    await DosenCacheService.warmUp();

    await context.read<AdminAnnouncementViewModel>().onConnectionRestored();
    await context.read<AdminMatkulViewModel>().onConnectionRestored();
    await context.read<AdminScheduleViewModel>().onConnectionRestored();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
