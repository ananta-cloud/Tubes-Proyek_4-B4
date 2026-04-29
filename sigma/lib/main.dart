import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import Database
import 'core/network/mongo_database.dart';

// Import UI
import 'features/auth/views/login_page.dart';

// Import Models
import 'data/models/schedule_local_model.dart';
import 'data/models/announcement_model.dart';
import 'data/models/task_model.dart';

// Import Services
import 'data/services/schedule_service.dart';
import 'data/services/announcement_service.dart';

// Import Controllers / ViewModels
import 'features/dosen/schedules/viewmodels/schedule_controller.dart';
import 'features/mahasiswa/tasks/tasks/viewmodels/task_viewmodel.dart';
import 'features/announcements/view_models/announcement_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load Env
  await dotenv.load(fileName: ".env");
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
        ChangeNotifierProvider(
          create: (_) => ScheduleController(ScheduleService()),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskController(),
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
      title: 'Sigma',
      debugShowCheckedModeBanner: false,
      home: LoginPage(), 
    );
  }
}