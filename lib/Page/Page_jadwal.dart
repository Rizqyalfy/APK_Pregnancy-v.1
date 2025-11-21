import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/data_repository.dart';

class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  final DataRepository _dataRepository = DataRepository();
  final NotificationService _notificationService = NotificationService();

  late List<Map<String, String>> jadwalOtomatis;
  late List<Map<String, dynamic>> riwayat;

  bool pengingatAktif = true;
  DateTime _lastUpdatedRiwayat = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initNotif();
  }

  void _loadData() {
    setState(() {
      jadwalOtomatis = _dataRepository.jadwalANC;
      riwayat = _dataRepository.riwayatKunjungan;
      _lastUpdatedRiwayat = DateTime.now();
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
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

    setState(() {
      riwayat = _dataRepository.riwayatKunjungan;
      _lastUpdatedRiwayat = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data riwayat berhasil diperbarui'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _initNotif() async {
    try {
      await _notificationService.init();
    } catch (e) {
      debugPrint('Notif init error: $e');
    }
  }

  Future<void> _testNotificationNow() async {
    await _notificationService.showNotification(
      id: 100,
      title: 'Tes Pengingat',
      body: 'Ini notifikasi percobaan dari MyPregnancyCare.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifikasi tes berhasil dikirim!')),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
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

  String _getLastUpdatedText() {
    return 'Terakhir diperbarui ${_formatLastUpdated()}';
  }

  // FUNGSI BARU: Tampilkan dialog detail riwayat
  void _showRiwayatDetail(Map<String, dynamic> riwayat) {
    final hasImage =
        riwayat['gambar'] != null &&
        riwayat['gambar'].toString().isNotEmpty &&
        riwayat['gambar'].toString() != 'null';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.visibility, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Detail Kunjungan',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tanggal
              _buildDetailItem('Tanggal Kunjungan', riwayat['tanggal'] ?? ''),

              // Hasil Pemeriksaan
              _buildDetailItem('Hasil Pemeriksaan', riwayat['hasil'] ?? ''),

              // Data detail dari API
              if (riwayat['detail'] != null)
                ..._buildDetailFromData(riwayat['detail']),

              if (riwayat['catatan'] != null && riwayat['catatan'].isNotEmpty)
                _buildDetailItem('Catatan Tambahan', riwayat['catatan']),

              const SizedBox(height: 16),

              // Gambar
              if (hasImage)
                _buildImageSection(riwayat)
              else
                _buildNoImagePlaceholder(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // WIDGET: Item detail
  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // FUNGSI: Build detail dari data
  List<Widget> _buildDetailFromData(Map<String, dynamic> detail) {
    List<Widget> widgets = [];

    if (detail['tekanan_darah'] != null && detail['tekanan_darah'].isNotEmpty) {
      widgets.add(
        _buildDetailItem('Tekanan Darah', '${detail['tekanan_darah']} mmHg'),
      );
    }

    if (detail['berat_badan'] != null && detail['berat_badan'].isNotEmpty) {
      widgets.add(
        _buildDetailItem('Berat Badan', '${detail['berat_badan']} kg'),
      );
    }

    if (detail['trimester'] != null && detail['trimester'].isNotEmpty) {
      widgets.add(_buildDetailItem('Trimester', detail['trimester']));
    }

    if (detail['jenis_kunjungan'] != null &&
        detail['jenis_kunjungan'].isNotEmpty) {
      widgets.add(
        _buildDetailItem('Jenis Kunjungan', detail['jenis_kunjungan']),
      );
    }

    if (detail['keluhan'] != null && detail['keluhan'].isNotEmpty) {
      widgets.add(_buildDetailItem('Keluhan', detail['keluhan']));
    }

    if (detail['pergerakan_janin'] != null &&
        detail['pergerakan_janin'].isNotEmpty) {
      widgets.add(
        _buildDetailItem('Pergerakan Janin', detail['pergerakan_janin']),
      );
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

  // WIDGET: Section gambar
  Widget _buildImageSection(Map<String, dynamic> riwayat) {
    final imagePath = riwayat['gambar'].toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dokumentasi:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
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
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // WIDGET: Widget gambar
  Widget _buildImageWidget(String imagePath, Map<String, dynamic> riwayat) {
    if (imagePath.startsWith('assets/')) {
      // Gambar dari assets
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorState();
          },
        ),
      );
    } else if (imagePath.startsWith('http')) {
      // Gambar dari URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imagePath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorState();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    } else {
      // Gambar placeholder jika format tidak dikenali
      return _buildImagePlaceholder(riwayat['tanggal'] ?? 'Dokumentasi');
    }
  }

  // WIDGET: Placeholder gambar
  Widget _buildImagePlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 50, color: Colors.blue[300]),
          const SizedBox(height: 8),
          Text(
            'Gambar $title',
            style: TextStyle(
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap untuk memperbesar',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }

  // WIDGET: Error state gambar
  Widget _buildImageErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 40),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat gambar',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // WIDGET: Placeholder ketika tidak ada gambar
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
          const Text(
            'Tidak ada dokumentasi gambar',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // FUNGSI: Tampilkan gambar full screen
  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black87,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: _buildFullScreenImage(imagePath),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tap di luar gambar untuk menutup',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: Gambar full screen
  Widget _buildFullScreenImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFullScreenError();
        },
      );
    } else if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFullScreenError();
        },
      );
    } else {
      return _buildFullScreenPlaceholder();
    }
  }

  // WIDGET: Placeholder full screen
  Widget _buildFullScreenPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_library, size: 80, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          'Gambar Dokumentasi',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'USG / Pemeriksaan',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  // WIDGET: Error state full screen
  Widget _buildFullScreenError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 50, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          'Gagal memuat gambar',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
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

              // Kalender Kehamilan Otomatis
              _buildSectionTitle("Kalender Kehamilan Otomatis"),
              _buildJadwalList(),

              const SizedBox(height: 20),

              // GABUNGAN: Notifikasi Tambahan + Pengingat Otomatis + Tes Notifikasi
              _buildSectionTitle("Pengaturan Notifikasi"),
              _buildNotifikasiSection(),

              const SizedBox(height: 24),

              // RIWAYAT KUNJUNGAN TERBARU
              _buildSectionTitle("Riwayat Kunjungan Terbaru"),
              _buildInfoCard(
                title: "Riwayat Pemeriksaan",
                icon: Icons.history,
                color: Colors.orange,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.list_alt,
                              color: Colors.blue[700],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${riwayat.length} Kunjungan Tercatat',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _refreshRiwayatData,
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Refresh Riwayat',
                        ),
                      ],
                    ),
                  ),

                  ...riwayat.take(3).map(_buildRiwayatItem),
                  if (riwayat.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.update,
                            size: 14,
                            color: _isToday(_lastUpdatedRiwayat)
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLastUpdatedText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: _isYesterday(_lastUpdatedRiwayat)
                                  ? FontStyle.italic
                                  : FontStyle.normal,
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: jadwalOtomatis.map((jadwal) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text(
                jadwal['judul']!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minggu ke-${jadwal['minggu']}'),
                  Text('Tanggal: ${jadwal['tanggal']}'),
                  Text(
                    jadwal['catatan']!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.notifications, color: Colors.green),
                onPressed: () => _scheduleSingleANCNotification(jadwal),
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
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, color: Color(0xFFB0BEC5)),
          ...children,
        ],
      ),
    );
  }

  // WIDGET: Item riwayat yang bisa di-tap untuk lihat detail
  Widget _buildRiwayatItem(Map<String, dynamic> riwayat) {
    final hasImage =
        riwayat['gambar'] != null &&
        riwayat['gambar'].toString().isNotEmpty &&
        riwayat['gambar'].toString() != 'null';

    return GestureDetector(
      onTap: () => _showRiwayatDetail(riwayat), // TAMBAH ON TAP
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Icon dengan indicator gambar
            Stack(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 16),
                if (hasImage)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    riwayat['tanggal']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    riwayat['hasil']?.toString() ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (hasImage)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.photo, size: 12, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Ada dokumentasi gambar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  // ... method lainnya (_buildNotifikasiSection, _buildReminderToggle, dll) tetap sama
  // GABUNGAN: Widget untuk section notifikasi yang menyatu
  Widget _buildNotifikasiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Switch Aktifkan Pengingat Otomatis
          _buildReminderToggle(),

          const SizedBox(height: 16),

          // Tombol Tes Notifikasi
          _buildMainButton(
            _testNotificationNow,
            Icons.notifications_active,
            'Tes Notifikasi Sekarang',
            color: Colors.blue,
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Daftar Notifikasi Tambahan
          _buildNotifikasiTambahanList(),
        ],
      ),
    );
  }

  Widget _buildReminderToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktifkan Pengingat Otomatis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Notifikasi akan diaktifkan untuk semua jadwal ANC',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: pengingatAktif,
              activeColor: Colors.green,
              onChanged: (val) {
                setState(() => pengingatAktif = val);
                if (val) {
                  _scheduleAllANCNotifications();
                } else {
                  _notificationService.cancelAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi dinonaktifkan'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifikasiTambahanList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifikasi Tambahan:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildReminderRow(
          Icons.healing,
          'Imunisasi TT (ingatkan sesuai jadwal)',
        ),
        _buildReminderRow(Icons.local_pharmacy, 'Konsumsi tablet Fe'),
        _buildReminderRow(Icons.science, 'Pemeriksaan lab (cek hasil)'),
        _buildReminderRow(Icons.medication, 'Reminder minum vitamin (harian)'),
        _buildReminderRow(Icons.bedtime, 'Reminder istirahat cukup'),
        _buildReminderRow(
          Icons.local_hospital,
          'Reminder kontrol ke fasilitas kesehatan',
        ),
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
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF2E5C9A))),
          ),
          ElevatedButton(
            onPressed: () async {
              final dt = DateTime.now().add(const Duration(seconds: 10));
              await _notificationService.scheduleNotification(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                title: 'Pengingat: ${text.split(' ')[0]}',
                body: text,
                scheduledDate: dt,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Pengingat singkat dijadwalkan (10 detik lagi).',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              minimumSize: const Size(90, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Aktifkan',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(
    VoidCallback onPressed,
    IconData icon,
    String text, {
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 3,
      ),
    );
  }

  Future<void> _scheduleSingleANCNotification(
    Map<String, String> jadwal,
  ) async {
    final scheduledDate = DateTime.tryParse(jadwal['tanggal']!);
    if (scheduledDate != null) {
      final reminderDate = scheduledDate.subtract(const Duration(days: 1));

      await _notificationService.scheduleNotification(
        id: int.parse(jadwal['minggu']!),
        title: jadwal['judul']!,
        body: '${jadwal['catatan']!} - Jangan lupa pemeriksaan ANC besok!',
        scheduledDate: reminderDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifikasi untuk ${jadwal['judul']} dijadwalkan!'),
        ),
      );
    }
  }

  Future<void> _scheduleAllANCNotifications() async {
    for (var jadwal in jadwalOtomatis) {
      final scheduledDate = DateTime.tryParse(jadwal['tanggal']!);
      if (scheduledDate != null) {
        final reminderDate = scheduledDate.subtract(const Duration(days: 1));

        await _notificationService.scheduleNotification(
          id: int.parse(jadwal['minggu']!),
          title: jadwal['judul']!,
          body: '${jadwal['catatan']!} - Pemeriksaan ANC besok!',
          scheduledDate: reminderDate,
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ANC berhasil dijadwalkan!'),
      ),
    );
  }
}
