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
    await _firebaseMessaging.subscribeToTopic('pengumuman_kampus');
    print("Berhasil berlangganan radio pengumuman_kampus!");

    // 4. Tangkap Notifikasi saat aplikasi TERBUKA (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Pesan masuk saat aplikasi dibuka (Foreground)!");
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
}
