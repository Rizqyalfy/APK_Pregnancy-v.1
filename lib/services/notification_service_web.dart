// lib/services/notification_service_web.dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    print('Web Notification Service Initialized');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print('Web: Would show notification - $title: $body');
    // Untuk web, Anda bisa implementasi notifikasi browser jika needed
    _showBrowserNotification(title, body);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    print('Web: Would schedule notification - $title at $scheduledDate');
    // Web doesn't support background notifications, show immediately instead
    await showNotification(id: id, title: title, body: body);
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    print('Web: Would schedule daily notification - $title at $hour:$minute');
    // Show immediately for web
    await showNotification(id: id, title: title, body: body);
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    print('Web: Would schedule weekly notification - $title at $hour:$minute');
    // Show immediately for web
    await showNotification(id: id, title: title, body: body);
  }

  Future<void> cancelNotification(int id) async {
    print('Web: Would cancel notification $id');
    // Tidak ada yang perlu dibatalkan di web
  }

  Future<void> cancelAllNotifications() async {
    print('Web: Would cancel all notifications');
    // Tidak ada yang perlu dibatalkan di web
  }

  Future<bool> areNotificationsEnabled() async {
    // Check if browser supports notifications
    return await _checkBrowserNotificationSupport();
  }

  // Helper method untuk notifikasi browser (optional)
  void _showBrowserNotification(String title, String body) {
    // Hanya jalankan jika di environment web
    try {
      if (_isWebEnvironment()) {
        print('Browser Notification: $title - $body');
        // Anda bisa implementasi Notification API browser di sini
        // if (Notification.supported) {
        //   Notification.requestPermission().then((permission) {
        //     if (permission == 'granted') {
        //       Notification(title, body: body);
        //     }
        //   });
        // }
      }
    } catch (e) {
      print('Error showing browser notification: $e');
    }
  }

  // Check if browser notifications are supported
  Future<bool> _checkBrowserNotificationSupport() async {
    try {
      return _isWebEnvironment();
    } catch (e) {
      return false;
    }
  }

  // Check if running in web environment
  bool _isWebEnvironment() {
    return identical(0, 0.0); // Simple check for web environment
  }
}
