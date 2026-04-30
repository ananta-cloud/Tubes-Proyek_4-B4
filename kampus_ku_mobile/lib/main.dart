import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kampus_ku_mobile/core/network/mongo_database.dart';
import 'package:kampus_ku_mobile/data/models/task_model.dart';
import '../../../data/models/user_model.dart';

// Import Auth & Pages
import 'package:kampus_ku_mobile/features/auth/login_page.dart';

// Import Penjadwalan
import 'package:kampus_ku_mobile/controller/schedule_request_controller.dart';
import 'package:kampus_ku_mobile/data/services/schedule_request_service.dart';

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

  await dotenv.load(fileName: ".env");
  print("MONGO_URL: ${dotenv.env['MONGO_URL']}");
  await Hive.initFlutter();

  Hive.registerAdapter(ScheduleLocalModelAdapter());
  Hive.registerAdapter(AnnouncementModelAdapter());

  await Hive.openBox<ScheduleLocalModel>('schedules');
  await Hive.openBox<AnnouncementModel>('announcements');
  await Hive.openBox<TaskModel>('tasks');
  await MongoDatabase.connect();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ScheduleController(ScheduleService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AnnouncementController(AnnouncementService()),
        ),
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
      title: 'SIGMA',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
