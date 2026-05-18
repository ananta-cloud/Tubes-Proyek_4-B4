import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Fungsi WAJIB di level teratas (Top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Pesan masuk di latar belakang: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<void> onNewNotification = StreamController<void>.broadcast();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'pengumuman_kampus_channel',
    'Pengumuman Kampus',
    description: 'Saluran untuk pengumuman kampus',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initNotification() async {
    // 1. Minta Izin
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin Notifikasi Diberikan!');
    } else {
      print('Izin Notifikasi Ditolak.');
    }

    // 2. Setup Local Notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _localNotificationsPlugin.initialize(settings: initSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // 3. Berlangganan Topik
    await _firebaseMessaging.unsubscribeFromTopic('pengumuman_kampus');
    print("Membersihkan sisa langganan topik lama...");

    // 4. Tangkap Notifikasi saat aplikasi TERBUKA (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Pesan masuk saat aplikasi dibuka (Foreground)!");
      onNewNotification.add(null);
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5. Tangkap di Latar Belakang (Background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

// Fungsi untuk mengatur langganan topik berdasarkan Role
  static Future<void> subscribeToRole(String role) async {
    final fcm = FirebaseMessaging.instance;
    final userRole = role.trim().toUpperCase();

    // 1. SEMUA ORANG CABUT LANGGANAN DULU (Pembersihan Total)
    // Ini mencegah penumpukan topik jika user berganti akun di HP yang sama
    final allPossibleTopics = [
      'pengumuman_semua',
      'pengumuman_mahasiswa',
      'pengumuman_dosen',
      'task_mahasiswa',
      'jadwal_mahasiswa',
      'jadwal_dosen',
      'jadwal_tim_penjadwalan',
      'jadwal_admin_tu',
    ];
    for (String topic in allPossibleTopics) {
      await fcm.unsubscribeFromTopic(topic);
    }

    // 2. SEMUA ROLE BERLANGGANAN TOPIK GLOBAL PENGUMUMAN
    await fcm.subscribeToTopic('pengumuman_semua');

    // 3. BERLANGGANAN BERDASARKAN ROLE
    if (userRole == 'MAHASISWA') {
      await fcm.subscribeToTopic('pengumuman_mahasiswa');
      await fcm.subscribeToTopic('task_mahasiswa');
      await fcm.subscribeToTopic('jadwal_mahasiswa');
      print("Langganan Notif: MAHASISWA Aktif");

    } else if (userRole == 'DOSEN') {
      await fcm.subscribeToTopic('pengumuman_dosen');
      await fcm.subscribeToTopic('jadwal_dosen');
      print("Langganan Notif: DOSEN Aktif");

    } else if (userRole == 'TIM_PENJADWALAN') {
      await fcm.subscribeToTopic('jadwal_tim_penjadwalan');
      print("Langganan Notif: TIM PENJADWALAN Aktif");

    } else if (userRole == 'ADMIN_TU') {
      await fcm.subscribeToTopic('jadwal_admin_tu');
      print("Langganan Notif: ADMIN TU Aktif");
    }
  }
}
