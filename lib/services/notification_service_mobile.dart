// lib/services/notification_service_mobile.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';

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

      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
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

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;
      print('Mobile Notification Service Initialized Successfully');
    } catch (e) {
      print('Error initializing Notification Service: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        // ANC Channel
        const AndroidNotificationChannel ancChannel =
            AndroidNotificationChannel(
              'anc_channel',
              'Jadwal ANC',
              description: 'Pengingat jadwal pemeriksaan ANC',
              importance: Importance.high,
            );

        // Daily Reminder Channel
        const AndroidNotificationChannel dailyChannel =
            AndroidNotificationChannel(
              'daily_reminder_channel',
              'Pengingat Harian',
              description: 'Pengingat harian untuk ibu hamil',
              importance: Importance.defaultImportance,
            );

        // Weekly Reminder Channel
        const AndroidNotificationChannel weeklyChannel =
            AndroidNotificationChannel(
              'weekly_reminder_channel',
              'Pengingat Mingguan',
              description: 'Pengingat mingguan untuk perkembangan kehamilan',
              importance: Importance.defaultImportance,
            );

        await androidImplementation.createNotificationChannel(ancChannel);
        await androidImplementation.createNotificationChannel(dailyChannel);
        await androidImplementation.createNotificationChannel(weeklyChannel);

        print('Notification channels created successfully');
      }
    } catch (e) {
      print('Error creating notification channels: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!_isInitialized) await init();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'anc_channel',
            'Jadwal ANC',
            channelDescription: 'Pengingat jadwal pemeriksaan ANC',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
        badgeNumber: 1,
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details);

      print('Mobile: Notification shown - $title');
    } catch (e) {
      print('Error showing notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (!_isInitialized) await init();

      // Convert to TZDateTime
      final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      // Check if scheduled date is in the future
      if (scheduledTZ.isBefore(tz.TZDateTime.now(tz.local))) {
        throw Exception('Scheduled date is in the past');
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'anc_channel',
            'Jadwal ANC',
            channelDescription: 'Pengingat jadwal pemeriksaan ANC',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
        badgeNumber: 1,
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Try exact scheduling first, fallback to approximate if permission denied
      await _scheduleWithFallback(
        id: id,
        title: title,
        body: body,
        scheduledTZ: scheduledTZ,
        details: details,
      );

      print('Mobile: Notification scheduled - $title at $scheduledDate');
    } catch (e) {
      print('Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTZ,
    required NotificationDetails details,
  }) async {
    try {
      // First try with exact scheduling
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        print('Exact alarm not permitted, using approximate scheduling');
        // Fallback to approximate scheduling without allowWhileIdle
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledTZ,
          details,
          androidAllowWhileIdle: false, // Disable for approximate
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      if (!_isInitialized) await init();

      // Schedule for today at the specified time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'daily_reminder_channel',
            'Pengingat Harian',
            channelDescription: 'Pengingat harian untuk ibu hamil',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _scheduleWithFallback(
        id: id,
        title: title,
        body: body,
        scheduledTZ: scheduledDate,
        details: details,
      );

      print('Mobile: Daily notification scheduled - $title at $hour:$minute');
    } catch (e) {
      print('Error scheduling daily notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      if (!_isInitialized) await init();

      // Schedule for next week same day and time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Add 7 days for weekly
      scheduledDate = scheduledDate.add(const Duration(days: 7));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'weekly_reminder_channel',
            'Pengingat Mingguan',
            channelDescription:
                'Pengingat mingguan untuk perkembangan kehamilan',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _scheduleWithFallback(
        id: id,
        title: title,
        body: body,
        scheduledTZ: scheduledDate,
        details: details,
      );

      print('Mobile: Weekly notification scheduled - $title at $hour:$minute');
    } catch (e) {
      print('Error scheduling weekly notification: $e');
      rethrow;
    }
  }

  // Method untuk testing tanpa scheduling (immediate notification)
  Future<void> testNotificationNow({
    required String title,
    required String body,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await showNotification(id: id, title: title, body: body);
      print('Test notification sent successfully');
    } catch (e) {
      print('Error sending test notification: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('Mobile: Notification $id cancelled');
    } catch (e) {
      print('Error cancelling notification $id: $e');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Mobile: All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
      rethrow;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      // For iOS
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        final result = await iosPlugin.requestPermissions();
        return result ?? false;
      }

      // For Android, assume true since permissions are granted at app level
      return true;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  // Method untuk mendapatkan scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
}
