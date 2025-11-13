// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

class NotificationService {
  // Singleton agar mudah diakses di seluruh aplikasi
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  /// 🔔 Inisialisasi notifikasi — minta izin jika belum diberikan
  Future<void> init() async {
    if (html.Notification.supported &&
        html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }
  }

  /// 🔔 Menampilkan notifikasi langsung
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Cek dukungan notifikasi
    if (!html.Notification.supported) {
      html.window.alert('$title\n\n$body');
      return;
    }

    // Minta izin jika belum granted
    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }

    // Jika sudah diizinkan
    if (html.Notification.permission == 'granted') {
      // Coba gunakan service worker (jika ada)
      final reg = await html.window.navigator.serviceWorker?.getRegistration();

      if (reg != null) {
        // ✅ Gunakan js_util agar kompatibel dengan Web API
        js_util.callMethod(reg, 'showNotification', [
          title,
          js_util.jsify({'body': body}),
        ]);
      } else {
        // ✅ Gunakan constructor Notification terbaru
        html.Notification(title, body: body);
      }
    }
  }

  /// ⏰ Menjadwalkan notifikasi (hanya aktif selama tab terbuka)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    final diff = scheduledDate.difference(now);

    if (diff.isNegative) {
      await showNotification(id: id, title: title, body: body);
      return;
    }

    Timer(diff, () {
      showNotification(id: id, title: title, body: body);
    });
  }

  /// ❌ Membatalkan notifikasi — tidak didukung di versi web sederhana ini
  Future<void> cancel(int id) async {}

  /// ❌ Membatalkan semua notifikasi — tidak didukung di versi web sederhana ini
  Future<void> cancelAll() async {}
}
