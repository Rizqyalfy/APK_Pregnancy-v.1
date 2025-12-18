// lib/services/notification_service_mobile.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:ui'; // ✅ Untuk Color(...)
import 'package:flutter/services.dart'; // ✅ Untuk PlatformException

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _notifications = FlutterLocalNotificationsPlugin();

      // Initialize timezone with Jakarta
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);
      
      // Request notification permission untuk Android 13+
      await _requestPermissions();
      
      await _createNotificationChannels();

      _isInitialized = true;
      print('✅ Mobile Notification Service Initialized with Exact Alarm Support');
    } catch (e) {
      print('❌ Error initializing Notification Service: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Request notification permission (Android 13+)
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      print('🔔 Notification Permission: ${granted == true ? "GRANTED" : "DENIED"}');
      
      // Request exact alarm permission (Android 12+)
      try {
        final bool? exactAlarmGranted = await androidImplementation
            .requestExactAlarmsPermission();
        print('⏰ Exact Alarm Permission: ${exactAlarmGranted == true ? "GRANTED" : "DENIED"}');
      } catch (e) {
        print('⚠️ Exact alarm permission request failed: $e');
      }
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      const AndroidNotificationChannel ancChannel = AndroidNotificationChannel(
        'anc_channel',
        'Jadwal ANC',
        description: 'Pengingat jadwal pemeriksaan ANC',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
        'urgent_alarm_channel',
        'Alarm Jadwal Urgent',
        description: 'Notifikasi penting untuk jadwal yang tiba',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
      );

      await androidImplementation.createNotificationChannel(ancChannel);
      await androidImplementation.createNotificationChannel(urgentChannel);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool isUrgent = false,
    String? subText,
  }) async {
    if (!_isInitialized) await init();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isUrgent ? 'urgent_alarm_channel' : 'anc_channel',
      isUrgent ? 'Alarm Jadwal Urgent' : 'Jadwal ANC',
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      timeoutAfter: 30000,
      channelShowBadge: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
      badgeNumber: 1,
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'immediate_$id',
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isUrgent = false,
    String? subText,
  }) async {
    if (!_isInitialized) await init();

    final now = DateTime.now();
    print('⏰ Schedule Request: $title');
    print('   Waktu sekarang: $now');
    print('   Waktu jadwal: $scheduledDate');
    print('   Selisih: ${scheduledDate.difference(now).inSeconds} detik');
    
    if (scheduledDate.isBefore(now)) {
      // Jika sudah lewat, langsung tampilkan
      print('⚡ Waktu sudah lewat, langsung tampilkan notifikasi!');
      await showNotification(id: id, title: title, body: body, isUrgent: isUrgent, subText: subText);
      return;
    }

    // Request exact alarm permission untuk Android 12+
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      try {
        final bool? granted = await androidImplementation
            .requestExactAlarmsPermission();
        if (granted != true) {
          print('⚠️ Exact alarm permission tidak diberikan, notifikasi mungkin tidak tepat waktu');
        }
      } catch (e) {
        print('⚠️ Error requesting exact alarm permission: $e');
      }
    }

    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isUrgent ? 'urgent_alarm_channel' : 'anc_channel',
      isUrgent ? 'Alarm Jadwal Urgent' : 'Jadwal ANC',
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      timeoutAfter: 30000,
      channelShowBadge: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
      badgeNumber: 1,
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'scheduled_$id',
    );

    // Verify scheduled notification
    final pending = await getPendingNotifications();
    final isScheduled = pending.any((n) => n.id == id);
    
    print('✅ Notifikasi dijadwalkan dengan exact alarm: $title pada $scheduledDate');
    print('   Verification: ${isScheduled ? "BERHASIL" : "GAGAL"} - Total pending: ${pending.length}');
    
    if (!isScheduled) {
      print('❌ PERINGATAN: Notifikasi ID $id tidak ditemukan di pending list!');
    }
  }

  // Utility
  Future<void> cancelNotification(int id) async => _notifications.cancel(id);
  Future<void> cancelAllNotifications() async => _notifications.cancelAll();
  Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
      _notifications.pendingNotificationRequests();
  Future<void> checkPendingNotifications() async {
    final list = await getPendingNotifications();
    print('📅 Pending: ${list.length} notifikasi');
  }
}