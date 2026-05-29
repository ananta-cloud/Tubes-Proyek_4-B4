import 'dart:async';
import 'dart:convert'; // Tambahkan ini untuk jsonEncode
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Fungsi WAJIB di level teratas (Top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Pesan masuk di latar belakang: ${message.messageId}");
  // Note: Di background, Android otomatis memutar suara berdasarkan setting channel.
  // Jadi kita biarkan saja.
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<void> onNewNotification =
      StreamController<void>.broadcast();

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

    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'channel_biasa_1',
          'Pengumuman Biasa',
          importance: Importance.defaultImportance,
          sound: RawResourceAndroidNotificationSound('biasa'),
          playSound: true,
        ),
      );
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'channel_penting_1',
          'Pengumuman Penting',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('penting'),
          playSound: true,
        ),
      );
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'channel_sangat_penting_1',
          'Pengumuman Sangat Penting',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('sangat_penting'),
          playSound: true,
          enableVibration: true,
        ),
      );
    }

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
        // Ambil tipe pengumuman dari data payload (jika ada)
        String tipe =
            message.data['tipe'] ?? message.data['tipe_pengumuman'] ?? 'BIASA';

        // 👉 PANGGIL FUNGSI SHOW NOTIFICATION KITA DI SINI
        showNotification(
          id: notification.hashCode,
          title: notification.title ?? 'KampusKu',
          body: notification.body ?? '',
          payload: jsonEncode(message.data),
          tipePengumuman: tipe,
        );
      }
    });

    // 5. Tangkap di Latar Belakang (Background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // =========================================================
  // 👉 FUNGSI BARU ANDA DENGAN CUSTOM SOUND DILETAKKAN DI SINI
  // =========================================================
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    String tipePengumuman = 'BIASA',
  }) async {
    String channelId =
        'channel_biasa_1'; // Ubah nama channel agar HP mau membaca sound baru
    String channelName = 'Pengumuman Biasa';
    String soundFile = 'biasa'; // Nama file di folder raw (biasa.wav)
    Importance importance = Importance.defaultImportance;
    Priority priority = Priority.defaultPriority;

    if (tipePengumuman == 'PENTING') {
      channelId = 'channel_penting_1';
      channelName = 'Pengumuman Penting';
      soundFile = 'penting'; // file penting.wav
      importance = Importance.high;
      priority = Priority.high;
    } else if (tipePengumuman == 'SANGAT PENTING' ||
        tipePengumuman == 'SANGAT_PENTING') {
      channelId = 'channel_sangat_penting_1';
      channelName = 'Pengumuman Sangat Penting';
      soundFile = 'sangat_penting'; // file sangat_penting.wav
      importance = Importance.max;
      priority = Priority.max;
    }

    // Siapkan konfigurasi Android dengan Custom Sound
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Notifikasi untuk $channelName',
          importance: importance,
          priority: priority,
          // PENTING: Memanggil file dari res/raw
          sound: RawResourceAndroidNotificationSound(soundFile),
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );

    // Konfigurasi iOS
    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          sound: '$soundFile.wav',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Tampilkan Notifikasi
    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  // =========================================================
  // Fungsi untuk mengatur langganan topik berdasarkan Role
  // =========================================================
  static Future<void> subscribeToRole(String role) async {
    final fcm = FirebaseMessaging.instance;
    final userRole = role.trim().toUpperCase();

    // 1. SEMUA ORANG CABUT LANGGANAN DULU
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

    // 2. BERLANGGANAN BERDASARKAN ROLE
    if (userRole == 'MAHASISWA') {
      await fcm.subscribeToTopic('pengumuman_semua');
      await fcm.subscribeToTopic('pengumuman_mahasiswa');
      await fcm.subscribeToTopic('task_mahasiswa');
      await fcm.subscribeToTopic('jadwal_mahasiswa');
      print("Langganan Notif: MAHASISWA Aktif");
    } else if (userRole == 'DOSEN') {
      await fcm.subscribeToTopic('pengumuman_semua');
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
