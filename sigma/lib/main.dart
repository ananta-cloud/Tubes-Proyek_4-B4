import 'dart:async';
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
import 'data/models/announcement_model.dart';
import 'data/models/dosen_model.dart';
import 'data/models/task_model.dart';
import 'data/models/matkul_model.dart';
import 'data/models/schedule_model.dart';
import 'data/models/schedule_request_model.dart';
import 'data/models/pengajaran_model.dart';
import 'data/models/tpj_model.dart';

// ================= IMPORT SERVICES & REPOS =================
import 'data/services/schedule_service.dart';
import 'data/services/announcement_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/schedule_request_service.dart';
import 'data/services/dosen_cache_service.dart';
import 'package:sigma/data/services/dosen_request_service.dart';
import 'package:sigma/data/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';
import 'features/penjadwalan/viewmodels/schedule_request_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
  debugPrint("MONGO_URL: ${dotenv.env['MONGO_URL']}");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().initNotification();
  

  await Hive.initFlutter();

  // Registrasi Adapter Hive
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AnnouncementModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DetailPerubahanAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ScheduleRequestModelAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ScheduleModelAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(MatkulModelAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(DosenModelAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(TimPenjadwalanModelAdapter());
  if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(PengajaranModelAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TaskModelAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel(AuthRepository())),
        ChangeNotifierProvider(create: (_) => ScheduleController(ScheduleService())),
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => TaskFormViewModel()),
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel(AnnouncementService())),
        ChangeNotifierProvider(create: (_) => ScheduleViewModel()),
        ChangeNotifierProvider(create: (_) => AdminMainViewModel()),
        ChangeNotifierProvider(create: (_) => AdminScheduleViewModel()),
        ChangeNotifierProvider(create: (_) => AdminAnnouncementViewModel()),
        ChangeNotifierProvider(create: (_) => AdminMatkulViewModel()),
        ChangeNotifierProvider(create: (_) => DosenRequestController(DosenRequestService())),
        ChangeNotifierProvider(create: (_) => ScheduleRequestController(ScheduleRequestService())),
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
      home: SplashScreenLoader(),
    );
  }
}

// ── SPLASH SCREEN LOADER (Mencegah Layar Putih & Membuka Memori dengan Benar) ────────
class SplashScreenLoader extends StatefulWidget {
  const SplashScreenLoader({super.key});

  @override
  State<SplashScreenLoader> createState() => _SplashScreenLoaderState();
}

class _SplashScreenLoaderState extends State<SplashScreenLoader> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Membuka memori Hive secara paralel agar instan
    await Future.wait([
      Hive.openBox<AnnouncementModel>('announcements'),
      Hive.openBox<TaskModel>('tasks'),
      Hive.openBox<AnnouncementModel>('bookmarks'),
      Hive.openBox('pending_requests'),
      Hive.openBox<ScheduleModel>('schedules'),
      Hive.openBox('schedule_cache'),
      Hive.openBox('cancel_queue'),
      Hive.openBox('student_action_queue'),
      Hive.openBox<AnnouncementModel>('admin_announcements'),
      Hive.openBox<Map>('announcement_queue'),
      Hive.openBox<MatkulModel>('admin_matkul'),
      Hive.openBox<Map>('matkul_queue'),
      Hive.openBox('admin_prodi'),
      Hive.openBox<ScheduleModel>('admin_schedules'),
      Hive.openBox<Map>('schedule_queue'),
      Hive.openBox<PengajaranModel>('pengajaran'),
      Hive.openBox<DosenModel>('dosen_box'),
      Hive.openBox<String>('kelasCacheBox'),
    ]);

    await ScheduleRequestService.openBoxes();
    await DosenCacheService.openBox();

    // Pindah ke Halaman Utama setelah semua box memori siap
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const _ConnectivityListenerWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }

    // Sambungkan MongoDB di Latar Belakang agar tidak menahan layar (Anti-Freeze)
    try {
      await MongoDatabase.connect().timeout(const Duration(seconds: 5));
      await DosenCacheService.warmUp();
    } catch (e) {
      debugPrint("Koneksi awal lambat, fallback ke Mode Offline.");
      MongoDatabase.isOffline = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1F1F3D),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7A36)), 
      ),
    );
  }
}

class _ConnectivityListenerWrapper extends StatelessWidget {
  const _ConnectivityListenerWrapper();
  @override
  Widget build(BuildContext context) => const _ConnectivityListener(child: LoginPage());
}

// ── Connectivity Listener ──────────────────────────────────────────────────────
class _ConnectivityListener extends StatefulWidget {
  final Widget child;
  const _ConnectivityListener({required this.child});

  @override
  State<_ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends State<_ConnectivityListener> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final isOffline = result.contains(ConnectivityResult.none);

      if (isOffline) {
        MongoDatabase.isOffline = true;
        if (mounted) {
          context.read<ScheduleRequestController>().setOffline(true);
        }
      }

      if (_wasOffline && !isOffline) {
        debugPrint('🌐 Koneksi kembali online, memulai auto-sync...');
        _syncAll();
      }
      _wasOffline = isOffline;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); 
    super.dispose();
  }

  Future<void> _syncAll() async {
    if (!mounted) return;
    
    try {
      await MongoDatabase.ensureConnected();
      await DosenCacheService.warmUp();

      if (!mounted) return;

      final user = context.read<LoginViewModel>().user;

      if (user != null) {
        if (user.role == 'ADMIN_TU' || user.role == 'MANAJEMEN') {
          await context.read<AdminAnnouncementViewModel>().onConnectionRestored();
          await context.read<AdminMatkulViewModel>().onConnectionRestored();
          await context.read<AdminScheduleViewModel>().onConnectionRestored();
        }

        if (user.role == 'MAHASISWA') {
          final announcementVM = context.read<AnnouncementViewModel>();
          final taskVM = context.read<TaskViewModel>();
          final scheduleVM = context.read<ScheduleViewModel>();
          
          await announcementVM.syncOfflineActions();
          await announcementVM.syncAnnouncements();
          await taskVM.syncTasks(user); 
          await scheduleVM.syncSchedules(user);
        }

        if (user.role == 'DOSEN') {
          final announcementVM = context.read<AnnouncementViewModel>();
          final dosenReqCtrl = context.read<DosenRequestController>();

          await announcementVM.syncOfflineActions();
          await announcementVM.syncAnnouncements();
          await dosenReqCtrl.syncPendingRequests();
        }

        if (user.role == 'TIM_PENJADWALAN') {
          await context.read<ScheduleRequestController>().onConnectionRestored();
        }
      }
    } catch (e) {
      debugPrint("❌ Gagal melakukan sinkronisasi background: $e");
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}