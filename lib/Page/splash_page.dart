import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart'; // pastikan HomePage ada di sini
import 'login_page.dart';
// facade yang export mobile/web

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    // ✅ Minta izin hanya: notifikasi & galeri
    await _requestEssentialPermissions();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _requestEssentialPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionRequested = prefs.getBool('essential_permissions_requested') ?? false;

      if (!permissionRequested) {
        final shouldRequest = await _showPermissionDialog();
        if (shouldRequest == true && mounted) {
          await _requestEssentialPermissionsWithHandler();
          await prefs.setBool('essential_permissions_requested', true);
          await _showPermissionResultDialog();
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _requestEssentialPermissionsWithHandler() async {
    try {
      // ✅ Hanya minta izin yang benar-benar digunakan
      Map<Permission, PermissionStatus> statuses = await [
        Permission.notification,
        Permission.photos,
        Permission.storage, // fallback untuk Android <13
      ].request();

      debugPrint('Permission results:');
      statuses.forEach((permission, status) {
        debugPrint('$permission: $status');
      });

      // ❌ TIDAK ADA: _notificationService.requestPermissions();
    } catch (e) {
      debugPrint('Error in permission handler: $e');
    }
  }

  Future<void> _showPermissionResultDialog() async {
    final notificationGranted = await Permission.notification.isGranted;
    final photosGranted = await Permission.photos.isGranted || await Permission.storage.isGranted;
    final allGranted = notificationGranted && photosGranted;

    if (!allGranted && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Icon(
              allGranted ? Icons.check_circle : Icons.info_outline,
              color: allGranted ? Colors.green : Colors.orange,
              size: 48,
            ),
            title: Text(
              allGranted ? 'Semua Izin Aktif' : 'Periksa Izin',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPermissionStatus('Notifikasi', notificationGranted),
                const SizedBox(height: 8),
                _buildPermissionStatus('Galeri Foto', photosGranted),
                const SizedBox(height: 12),
                if (!allGranted) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Beberapa izin perlu diaktifkan manual di:\nSettings > Aplikasi > MyPregnancyCare > Permissions',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  allGranted ? 'Lanjutkan' : 'Mengerti',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildPermissionStatus(String label, bool granted) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: granted ? Colors.black87 : Colors.grey,
              decoration: granted ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
        Text(
          granted ? 'Aktif' : 'Tidak Aktif',
          style: TextStyle(
            fontSize: 11,
            color: granted ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<bool?> _showPermissionDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.security, color: Color(0xFF4A90E2), size: 48),
          title: const Text(
            'Izin Aplikasi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'MyPregnancyCare memerlukan izin berikut:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Divider(height: 1),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFF4A90E2), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notifikasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Menampilkan pengingat jadwal ANC', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.photo_library, color: Color(0xFF4A90E2), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Galeri Foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Menyimpan foto profil ibu hamil', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(height: 1),
                SizedBox(height: 8),
                Text(
                  '🔒 Data Anda aman dan hanya digunakan untuk fitur aplikasi',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Izinkan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.pregnant_woman, size: 72, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'MyPregnancyCare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Memulai untuk Ibu dan Si Kecil',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}