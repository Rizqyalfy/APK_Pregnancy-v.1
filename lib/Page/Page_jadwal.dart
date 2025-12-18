import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  final NotificationService _notificationService = NotificationService();
  late List<Map<String, String>> jadwalOtomatis = [];
  late List<Map<String, dynamic>> riwayat = [];
  DateTime _lastUpdatedRiwayat = DateTime.now();
  Timer? _countdownTimer;
  List<Map<String, dynamic>> _scheduledReminders = [];
  bool _hasPreparedBanner = false;
  Map<String, dynamic>? _nearestUpcomingSchedule;

  @override
  void initState() {
    super.initState();
    _initNotif();
    _loadDataAndPrepareBanner();
    _startCountdownTimer();
    _loadScheduledReminders();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          // Cek dan trigger notifikasi untuk reminders yang waktunya sudah tiba
          _scheduledReminders.removeWhere((reminder) {
            final scheduledTime = DateTime.parse(reminder['scheduledTime']);
            final diff = scheduledTime.difference(now);
            
            // Jika waktu tiba (dalam 1 detik), trigger notifikasi manual
            if (diff.inSeconds <= 0 && diff.inSeconds > -2) {
              _triggerManualNotification(reminder['text']);
              return true; // Hapus dari list
            }
            
            return scheduledTime.isBefore(now.subtract(const Duration(seconds: 2)));
          });
        });
        
        // Cek jadwal akan datang
        if (_nearestUpcomingSchedule != null) {
          final dateTime = _nearestUpcomingSchedule!['dateTime'] as DateTime;
          final diff = dateTime.difference(now);
          
          // Trigger notifikasi jika waktu tiba
          if (diff.inSeconds <= 0 && diff.inSeconds > -2) {
            final jadwal = _nearestUpcomingSchedule!['jadwal'] as Map<String, String>;
            _triggerManualNotification('🚨 WAKTUNYA! ANC - ${jadwal['judul']}');
          }
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _triggerManualNotification(String message) async {
    try {
      final now = DateTime.now();
      final id = now.microsecondsSinceEpoch % 100000;
      
      print('🔔 MANUAL TRIGGER: $message');
      
      await _notificationService.showNotification(
        id: id,
        title: '🚨 WAKTUNYA!',
        body: message,
        isUrgent: true,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 $message'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Error triggering manual notification: $e');
    }
  }

  Future<void> _loadScheduledReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList('scheduled_reminders') ?? [];
      setState(() {
        _scheduledReminders = remindersJson
            .map((json) {
              final parts = json.split('|');
              if (parts.length >= 2) {
                return {'text': parts[0], 'scheduledTime': parts[1]};
              }
              return <String, dynamic>{};
            })
            .where((item) => item.isNotEmpty)
            .toList();
      });
      _scheduledReminders.removeWhere((reminder) {
        final scheduledTime = DateTime.parse(reminder['scheduledTime']);
        return scheduledTime.isBefore(DateTime.now());
      });
      await _saveScheduledReminders();
    } catch (e) {
      debugPrint('Error loading scheduled reminders: $e');
    }
  }

  Future<void> _saveScheduledReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = _scheduledReminders.map((reminder) {
        return '${reminder['text']}|${reminder['scheduledTime']}';
      }).toList();
      await prefs.setStringList('scheduled_reminders', remindersJson);
    } catch (e) {
      debugPrint('Error saving scheduled reminders: $e');
    }
  }

  Future<void> _loadDataAndPrepareBanner() async {
    await _loadDataSync();
    await _scheduleUpcomingANCNotifications();
    if (!_hasPreparedBanner) {
      _prepareUpcomingBanner();
      _hasPreparedBanner = true;
    }
  }

  void _loadData() {
    () async {
      try {
        final j = await ApiService.getJadwalANC();
        final r = await ApiService.getRiwayatKunjungan();
        final List<Map<String, String>> jadwalList = [];
        for (var item in j) {
          jadwalList.add({
            'id': item['id']?.toString() ?? '',
            'minggu': item['minggu']?.toString() ?? '',
            'judul': item['judul']?.toString() ?? '',
            'tanggal': item['tanggal']?.toString() ?? '',
            'jam': item['jam']?.toString() ?? '',
            'catatan': item['catatan']?.toString() ?? '',
          });
        }
        final List<Map<String, dynamic>> riwayatList = [];
        for (var item in r) {
          riwayatList.add(Map<String, dynamic>.from(item));
        }
        if (mounted) {
          setState(() {
            jadwalOtomatis = jadwalList;
            riwayat = riwayatList;
            _lastUpdatedRiwayat = DateTime.now();
          });
        }
      } catch (e) {
        debugPrint('Error load data CatatanPage: $e');
      }
    }();
  }

  Future<void> _loadDataSync() async {
    try {
      final j = await ApiService.getJadwalANC();
      final r = await ApiService.getRiwayatKunjungan();
      final List<Map<String, String>> jadwalList = [];
      for (var item in j) {
        jadwalList.add({
          'id': item['id']?.toString() ?? '',
          'minggu': item['minggu']?.toString() ?? '',
          'judul': item['judul']?.toString() ?? '',
          'tanggal': item['tanggal']?.toString() ?? '',
          'jam': item['jam']?.toString() ?? '',
          'catatan': item['catatan']?.toString() ?? '',
        });
      }
      final List<Map<String, dynamic>> riwayatList = [];
      for (var item in r) {
        riwayatList.add(Map<String, dynamic>.from(item));
      }
      if (mounted) {
        setState(() {
          jadwalOtomatis = jadwalList;
          riwayat = riwayatList;
          _lastUpdatedRiwayat = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error load data sync CatatanPage: $e');
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('scheduled_anc_')).toList();
    for (var key in keys) {
      await prefs.remove(key);
    }
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data berhasil diperbarui'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _refreshRiwayatData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final r = await ApiService.getRiwayatKunjungan();
      final List<Map<String, dynamic>> riwayatList = [];
      for (var item in r) {
        riwayatList.add(Map<String, dynamic>.from(item));
      }
      if (mounted)
        setState(() {
          riwayat = riwayatList;
          _lastUpdatedRiwayat = DateTime.now();
        });
    } catch (e) {
      debugPrint('Error refresh riwayat: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data riwayat berhasil diperbarui'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAllRiwayatDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[700]!,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Semua Riwayat Kunjungan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${riwayat.length} Kunjungan Tercatat',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: riwayat.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRiwayatItem(riwayat[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initNotif() async {
    try {
      await _notificationService.init();
    } catch (e) {
      debugPrint('Notif init error: $e');
    }
  }

  // ✅ Hanya jadwalkan notifikasi TEPAT WAKTU
  Future<void> _scheduleUpcomingANCNotifications() async {
    if (jadwalOtomatis.isEmpty) return;
    final now = DateTime.now();
    final upcomingSchedules = <Map<String, dynamic>>[];
    for (var jadwal in jadwalOtomatis) {
      final scheduledDate = DateTime.tryParse(jadwal['tanggal']!);
      if (scheduledDate == null) continue;
      final jamStr = jadwal['jam'] ?? '09:00';
      final jamParts = jamStr.split(':');
      final hour = int.tryParse(jamParts[0]) ?? 9;
      final minute = jamParts.length > 1 ? int.tryParse(jamParts[1]) ?? 0 : 0;
      final scheduledDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        hour,
        minute,
      );
      if (scheduledDateTime.isAfter(now) && scheduledDateTime.difference(now).inDays <= 7) {
        upcomingSchedules.add({
          'jadwal': jadwal,
          'dateTime': scheduledDateTime,
        });
      }
    }
    upcomingSchedules.sort((a, b) => a['dateTime'].compareTo(b['dateTime']));
    final prefs = await SharedPreferences.getInstance();
    for (var item in upcomingSchedules) {
      final jadwal = item['jadwal'] as Map<String, String>;
      final dateTime = item['dateTime'] as DateTime;
      final key = 'scheduled_anc_${jadwal['id']}';
      if (prefs.getBool(key) == true) continue;
      try {
        // HANYA NOTIFIKASI TEPAT WAKTU
        await _notificationService.scheduleNotification(
          id: int.parse(jadwal['minggu']!) + 2000,
          title: '🚨 WAKTUNYA! ANC',
          body: 'Segera hadiri kunjungan ANC Anda: ${jadwal['judul']}',
          scheduledDate: dateTime,
          isUrgent: true,
        );
        await prefs.setBool(key, true);
        debugPrint('✅ Jadwal ANC dijadwalkan: ${jadwal['judul']} (ID: ${jadwal['id']})');
      } catch (e) {
        debugPrint('❌ Gagal jadwalkan notifikasi ANC: $e');
      }
    }
  }

  void _prepareUpcomingBanner() {
    if (jadwalOtomatis.isEmpty) return;
    final now = DateTime.now();
    final upcomingSchedules = <Map<String, dynamic>>[];
    for (var jadwal in jadwalOtomatis) {
      final scheduledDate = DateTime.tryParse(jadwal['tanggal']!);
      if (scheduledDate == null) continue;
      final jamStr = jadwal['jam'] ?? '09:00';
      final jamParts = jamStr.split(':');
      final hour = int.tryParse(jamParts[0]) ?? 9;
      final minute = jamParts.length > 1 ? int.tryParse(jamParts[1]) ?? 0 : 0;
      final scheduledDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        hour,
        minute,
      );
      final difference = scheduledDateTime.difference(now);
      if (difference.inSeconds > 0 && difference.inDays <= 7) {
        upcomingSchedules.add({
          'jadwal': jadwal,
          'dateTime': scheduledDateTime,
          'difference': difference,
        });
      }
    }
    if (upcomingSchedules.isEmpty) return;
    upcomingSchedules.sort((a, b) => (a['difference'] as Duration).compareTo(b['difference'] as Duration));
    setState(() {
      _nearestUpcomingSchedule = upcomingSchedules.first;
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  String _formatLastUpdated() {
    if (_isToday(_lastUpdatedRiwayat)) {
      return '${_lastUpdatedRiwayat.hour.toString().padLeft(2, '0')}:${_lastUpdatedRiwayat.minute.toString().padLeft(2, '0')}';
    } else if (_isYesterday(_lastUpdatedRiwayat)) {
      return 'Kemarin ${_lastUpdatedRiwayat.hour.toString().padLeft(2, '0')}:${_lastUpdatedRiwayat.minute.toString().padLeft(2, '0')}';
    } else {
      return '${_lastUpdatedRiwayat.day}/${_lastUpdatedRiwayat.month}/${_lastUpdatedRiwayat.year} ${_lastUpdatedRiwayat.hour.toString().padLeft(2, '0')}:${_lastUpdatedRiwayat.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getLastUpdatedTextRealtime() {
    final now = DateTime.now();
    final difference = now.difference(_lastUpdatedRiwayat);
    if (difference.inSeconds < 60) {
      return 'Baru saja diperbarui';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return _formatLastUpdated();
    }
  }

  void _showRiwayatDetail(Map<String, dynamic> riwayat) {
    final hasImage =
        (riwayat['gambar'] != null && riwayat['gambar'].toString().isNotEmpty && riwayat['gambar'].toString() != 'null') ||
        (riwayat['foto_usg'] != null && riwayat['foto_usg'].toString().isNotEmpty && riwayat['foto_usg'].toString() != 'null');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.visibility, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Detail Kunjungan',
              style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Tanggal Kunjungan', riwayat['tanggal'] ?? ''),
              _buildDetailItem('Hasil Pemeriksaan', riwayat['hasil'] ?? ''),
              if (riwayat['detail'] != null) ..._buildDetailFromData(riwayat['detail']),
              if (riwayat['catatan'] != null && riwayat['catatan'].isNotEmpty)
                _buildDetailItem('Catatan Tambahan', riwayat['catatan']),
              const SizedBox(height: 16),
              if (hasImage)
                _buildImageSection(riwayat)
              else
                _buildNoImagePlaceholder(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
          const Divider(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildDetailFromData(Map<String, dynamic> detail) {
    List<Widget> widgets = [];
    if (detail['tekanan_darah'] != null && detail['tekanan_darah'].isNotEmpty) {
      widgets.add(_buildDetailItem('Tekanan Darah', '${detail['tekanan_darah']} mmHg'));
    }
    if (detail['berat_badan'] != null && detail['berat_badan'].isNotEmpty) {
      widgets.add(_buildDetailItem('Berat Badan', '${detail['berat_badan']} kg'));
    }
    if (detail['trimester'] != null && detail['trimester'].isNotEmpty) {
      widgets.add(_buildDetailItem('Trimester', detail['trimester']));
    }
    if (detail['jenis_kunjungan'] != null && detail['jenis_kunjungan'].isNotEmpty) {
      widgets.add(_buildDetailItem('Jenis Kunjungan', detail['jenis_kunjungan']));
    }
    if (detail['keluhan'] != null && detail['keluhan'].isNotEmpty) {
      widgets.add(_buildDetailItem('Keluhan', detail['keluhan']));
    }
    if (detail['pergerakan_janin'] != null && detail['pergerakan_janin'].isNotEmpty) {
      widgets.add(_buildDetailItem('Pergerakan Janin', detail['pergerakan_janin']));
    }
    if (detail['hasil_lab'] != null && detail['hasil_lab'].isNotEmpty) {
      widgets.add(_buildDetailItem('Hasil Lab', detail['hasil_lab']));
    }
    if (detail['hasil_usg'] != null && detail['hasil_usg'].isNotEmpty) {
      widgets.add(_buildDetailItem('Hasil USG', detail['hasil_usg']));
    }
    if (detail['imunisasi_tt'] != null && detail['imunisasi_tt'].isNotEmpty) {
      widgets.add(_buildDetailItem('Imunisasi TT', detail['imunisasi_tt']));
    }
    return widgets;
  }

  Widget _buildImageSection(Map<String, dynamic> riwayat) {
    final imagePath = (riwayat['gambar'] ?? riwayat['foto_usg'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dokumentasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFullImage(imagePath),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: _buildImageWidget(imagePath, riwayat),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap gambar untuk melihat versi lengkap',
          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String imagePath, Map<String, dynamic> riwayat) {
    if (imagePath.isEmpty || imagePath == 'null') {
      return _buildImageErrorState();
    }
    String fullImageUrl = imagePath;
    if (!imagePath.startsWith('http') && !imagePath.startsWith('assets/')) {
      fullImageUrl = '${ApiService.baseUrl}/uploads/$imagePath';
    }
    if (fullImageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          fullImageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImageErrorState(),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: Image.network(
            fullImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('📸 Error loading image: $error');
              return _buildImageErrorState();
            },
          ),
        ),
      );
    }
  }

  Widget _buildImageErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 40),
          const SizedBox(height: 8),
          Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.photo, color: Colors.grey[400]),
          const SizedBox(width: 8),
          const Text('Tidak ada dokumentasi gambar', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showFullImage(String imagePath) {
    String fullImageUrl = imagePath;
    if (!imagePath.startsWith('http') && !imagePath.startsWith('assets/')) {
      fullImageUrl = '${ApiService.baseUrl}/uploads/$imagePath';
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black87),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(child: _buildFullScreenImage(fullImageUrl)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Pinch untuk zoom • Drag untuk geser', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Tap di luar gambar untuk menutup', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenImage(String fullImageUrl) {
    if (fullImageUrl.isEmpty || fullImageUrl == 'null') {
      return _buildFullScreenError();
    }
    if (fullImageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          fullImageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFullScreenError(),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          fullImageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null, color: Colors.white),
                  const SizedBox(height: 16),
                  Text('Memuat gambar...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildFullScreenError(),
        ),
      );
    }
  }

  Widget _buildFullScreenError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 50, color: Colors.white54),
        const SizedBox(height: 16),
        Text('Gagal memuat gambar', style: TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  Widget _buildUpcomingBanner() {
    if (_nearestUpcomingSchedule == null) return const SizedBox.shrink();

    final jadwal = _nearestUpcomingSchedule!['jadwal'] as Map<String, String>;
    final dateTime = _nearestUpcomingSchedule!['dateTime'] as DateTime;
    final now = DateTime.now();
    final diff = dateTime.difference(now);

    // Auto-hide jika waktu sudah habis
    if (diff.inSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _nearestUpcomingSchedule = null;
        });
      });
      return const SizedBox.shrink();
    }

    String timingInfo;
    if (diff.inHours < 1) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      timingInfo = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (diff.inHours < 24) {
      timingInfo = '${diff.inHours} jam lagi';
    } else if (diff.inDays == 1) {
      timingInfo = 'Besok';
    } else {
      timingInfo = '${diff.inDays} hari lagi';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF90CAF9), width: 2),
        boxShadow: [BoxShadow(color: const Color(0x332196F3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.event, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔔 Jadwal Akan Datang', style: TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
                    Text(jadwal['judul']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFF9800), borderRadius: BorderRadius.circular(12)),
                child: Text(timingInfo, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${dateTime.day}/${dateTime.month}/${dateTime.year} pukul ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFFD32F2F)),
                  onPressed: () {
                    setState(() {
                      _nearestUpcomingSchedule = null;
                    });
                  },
                  tooltip: 'Tutup',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledRemindersCard() {
    if (_scheduledReminders.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final upcomingReminders = _scheduledReminders.where((reminder) {
      final scheduledTime = DateTime.parse(reminder['scheduledTime']);
      final diff = scheduledTime.difference(now);
      return diff.inSeconds > 0 && diff.inMinutes < 60;
    }).toList();
    if (upcomingReminders.isEmpty) return const SizedBox.shrink();
    upcomingReminders.sort((a, b) {
      final timeA = DateTime.parse(a['scheduledTime']);
      final timeB = DateTime.parse(b['scheduledTime']);
      return timeA.compareTo(timeB);
    });
    final reminder = upcomingReminders.first;
    final scheduledTime = DateTime.parse(reminder['scheduledTime']);
    final diff = scheduledTime.difference(now);
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    String timeRemaining = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF90CAF9), width: 2),
        boxShadow: [BoxShadow(color: const Color(0x332196F3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔔 Pengingat Jadwal', style: TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
                    Text(reminder['text'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(12)),
                child: Text(timeRemaining, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year} pukul ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFFD32F2F)),
                  onPressed: () {
                    setState(() {
                      _scheduledReminders.remove(reminder);
                    });
                    _saveScheduledReminders();
                  },
                  tooltip: 'Hapus Pengingat',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.blue,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildUpcomingBanner(), // ✅ Banner pertama
              _buildScheduledRemindersCard(),
              _buildSectionTitle("Kalender Kehamilan Otomatis"),
              _buildJadwalList(),
              const SizedBox(height: 20),
              _buildSectionTitle("Pengingat Jadwal"),
              _buildNotifikasiSection(),
              const SizedBox(height: 24),
              _buildSectionTitle("Riwayat Kunjungan Terbaru"),
              _buildInfoCard(
                title: "Riwayat Pemeriksaan",
                icon: Icons.history,
                color: Colors.orange[800]!,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt, color: Colors.blue[700], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${riwayat.length} Kunjungan Tercatat',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isToday(_lastUpdatedRiwayat) ? Colors.green : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: _refreshRiwayatData,
                              icon: Icon(Icons.refresh, color: Colors.blue[600], size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Refresh Riwayat',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ...riwayat.take(3).map(_buildRiwayatItem),
                  if (riwayat.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _showAllRiwayatDialog,
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: Text(
                            'Lihat Semua Data (${riwayat.length} Kunjungan)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            backgroundColor: Colors.blue[50],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  if (riwayat.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.update,
                            size: 14,
                            color: _isToday(_lastUpdatedRiwayat) ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLastUpdatedTextRealtime(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: _isYesterday(_lastUpdatedRiwayat) ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.event_note, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          'Jadwal Kunjungan ANC',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[700]),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
    );
  }

  Widget _buildJadwalList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 2, 109, 202)),
        boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: jadwalOtomatis.map((jadwal) {
          final scheduledDate = DateTime.tryParse(jadwal['tanggal']!);
          final jamStr = jadwal['jam'] ?? '';
          final jamParts = jamStr.split(':');
          final hour = int.tryParse(jamParts[0]) ?? 9;
          final minute = jamParts.length > 1 ? int.tryParse(jamParts[1]) ?? 0 : 0;
          DateTime? scheduledDateTime;
          if (scheduledDate != null) {
            scheduledDateTime = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, hour, minute);
          }
          final isExpired = scheduledDateTime != null && scheduledDateTime.isBefore(DateTime.now());
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: isExpired ? Colors.grey[100] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isExpired ? BorderSide(color: Colors.grey[400]!, width: 1) : BorderSide.none,
            ),
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: isExpired ? Colors.grey : Colors.blue),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      jadwal['judul']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isExpired ? Colors.grey[600] : Colors.black,
                        decoration: isExpired ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
                      child: const Text('Lewat', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minggu ke-${jadwal['minggu']}', style: TextStyle(color: isExpired ? Colors.grey : null)),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: isExpired ? Colors.grey : Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(jadwal['tanggal']!, style: TextStyle(color: isExpired ? Colors.grey : null)),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: isExpired ? Colors.grey : Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(jadwal['jam'] ?? '', style: TextStyle(color: isExpired ? Colors.grey : Colors.orange[700], fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text(jadwal['catatan']!, style: TextStyle(color: isExpired ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.notifications, color: isExpired ? Colors.grey : Colors.green),
                onPressed: isExpired ? null : () => _showScheduleCustomDialog(jadwal['judul']!, 0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[800])),
            ],
          ),
          const Divider(thickness: 1, color: Color(0xFFB0BEC5)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRiwayatItem(Map<String, dynamic> riwayat) {
    final hasImage = riwayat['gambar'] != null &&
        riwayat['gambar'].toString().isNotEmpty &&
        riwayat['gambar'].toString() != 'null';
    return GestureDetector(
      onTap: () => _showRiwayatDetail(riwayat),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 16),
                if (hasImage)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.photo, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(riwayat['tanggal']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(riwayat['hasil']?.toString() ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (hasImage)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.photo, size: 12, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text('Ada dokumentasi gambar', style: TextStyle(fontSize: 10, color: Colors.blue[600], fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifikasiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(children: [_buildNotifikasiTambahanList()]),
    );
  }

  Widget _buildNotifikasiTambahanList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Pengingat Tambahan:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue[800])),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Atur pengingat untuk membantu menjaga kesehatan kehamilan Anda', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 16),
        _buildReminderRow(Icons.healing, 'Imunisasi TT (ingatkan sesuai jadwal)'),
        _buildReminderRow(Icons.local_pharmacy, 'Konsumsi tablet Fe'),
        _buildReminderRow(Icons.science, 'Pemeriksaan lab (cek hasil)'),
        _buildReminderRow(Icons.medication, 'Reminder minum vitamin (harian)'),
        _buildReminderRow(Icons.bedtime, 'Reminder istirahat cukup'),
        _buildReminderRow(Icons.local_hospital, 'Reminder kontrol ke fasilitas kesehatan'),
      ],
    );
  }

  Widget _buildReminderRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF2E5C9A)))),
          ElevatedButton(
            onPressed: () => _showScheduleCustomDialog(text, 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              minimumSize: const Size(90, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Aktifkan', style: TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showScheduleCustomDialog(String reminderText, int reminderMinutesBefore) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Atur Jadwal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminderText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.alarm, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Pengingat: TEPAT WAKTU',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Color(0xFF4A90E2)),
                      title: const Text('Tanggal Jadwal'),
                      subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: Color(0xFF4A90E2)),
                      title: const Text('Waktu Jadwal'),
                      subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: selectedTime);
                        if (picked != null) {
                          setState(() => selectedTime = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _scheduleCustomNotification(reminderText, selectedDate, selectedTime, 0);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), foregroundColor: Colors.white),
                  child: const Text('Jadwalkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleCustomNotification(String text, DateTime date, TimeOfDay time, int reminderMinutesBefore) async {
    final scheduledDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tanggal sudah lewat!'), backgroundColor: Colors.red));
      }
      return;
    }

    try {
      final baseId = DateTime.now().microsecondsSinceEpoch % 100000;

      // HANYA NOTIFIKASI TEPAT WAKTU
      await _notificationService.scheduleNotification(
        id: baseId + 1,
        title: '🚨 WAKTUNYA!',
        body: '$text\nSekarang: ${_formatTime(scheduledDate)}',
        scheduledDate: scheduledDate,
        isUrgent: true,
      );

      setState(() {
        _scheduledReminders.add({'text': text, 'scheduledTime': scheduledDate.toIso8601String()});
      });
      await _saveScheduledReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Pengingat dijadwalkan: $text'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}