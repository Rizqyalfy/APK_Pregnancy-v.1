import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  final List<Map<String, String>> jadwalOtomatis = [
    {"minggu": "12", "tanggal": "2025-01-10"},
    {"minggu": "20", "tanggal": "2025-03-07"},
    {"minggu": "28", "tanggal": "2025-05-02"},
    {"minggu": "32", "tanggal": "2025-05-30"},
    {"minggu": "36", "tanggal": "2025-06-27"},
    {"minggu": "40", "tanggal": "2025-07-25"},
  ];

  final List<Map<String, String>> riwayat = [
    {"tanggal": "2024-10-10", "hasil": "BP: 110/80, BB: 62kg, HB: 12"},
    {"tanggal": "2024-09-25", "hasil": "BP: 115/85, BB: 60kg, HB: 11.8"},
  ];

  bool pengingatAktif = true;

  @override
  void initState() {
    super.initState();
    _initNotif();
  }

  Future<void> _initNotif() async {
    try {
      await NotificationService.instance.init();
    } catch (e) {
      debugPrint('Notif init error: $e');
    }
  }

  Future<void> _testNotificationNow() async {
    await NotificationService.instance.showNotification(
      id: 100,
      title: 'Tes Pengingat',
      body: 'Ini notifikasi percobaan dari MyPregnancyCare.',
    );
  }

  Future<void> _scheduleANCNotificationExample() async {
    final item = jadwalOtomatis.firstWhere(
      (e) => e['minggu'] == '28',
      orElse: () => {},
    );
    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada jadwal minggu ke-28.')),
      );
      return;
    }

    final scheduledDate = DateTime.tryParse(item['tanggal']!);
    if (scheduledDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tanggal tidak valid.')));
      return;
    }

    await NotificationService.instance.scheduleNotification(
      id: 200,
      title: 'Waktunya ANC (Minggu ke-28)',
      body:
          'Segera lakukan pemeriksaan ANC minggu ke-28 — cek jadwal dan persiapkan dokumen.',
      scheduledDate: scheduledDate,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifikasi jadwal minggu ke-28 dijadwalkan.'),
      ),
    );
  }

  Future<void> _scheduleDailyVitaminReminder() async {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, 8, 0);
    DateTime scheduled = next.isAfter(now)
        ? next
        : next.add(const Duration(days: 1));

    await NotificationService.instance.scheduleNotification(
      id: 300,
      title: 'Pengingat Vitamin',
      body: 'Waktunya minum vitamin dan istirahat cukup.',
      scheduledDate: scheduled,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reminder harian vitamin dijadwalkan (mulai besok jika lewat jam 08:00).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
            ),
            const SizedBox(height: 20),

            // Kalender Kehamilan Otomatis
            _buildSectionTitle("Kalender Kehamilan Otomatis"),
            _buildJadwalList(), // ✅ sudah diberi border biru

            const SizedBox(height: 20),

            // Notifikasi Tambahan
            _buildSectionTitle("Notifikasi Tambahan"),
            _buildNotifikasiTambahan(),

            const SizedBox(height: 20),

            // Switch pengingat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktifkan Pengingat Otomatis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: pengingatAktif,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => pengingatAktif = val),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tombol notifikasi
            _buildActionButtons(),

            const SizedBox(height: 24),

            // Riwayat Kunjungan
            _buildSectionTitle("Riwayat Kunjungan"),
            ...riwayat.map(_buildRiwayatCard),
          ],
        ),
      ),
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

  // ✅ BAGIAN INI DITAMBAH BORDER DAN BACKGROUND BIRU LEMBUT
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
        children: jadwalOtomatis.map((e) {
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text('Minggu ke-${e['minggu']}'),
              subtitle: Text('Tanggal: ${e['tanggal']}'),
              trailing: const Icon(Icons.notifications, color: Colors.green),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotifikasiTambahan() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 2, 109, 202)),
      ),
      child: Column(
        children: [
          _buildReminderRow(
            Icons.healing,
            'Imunisasi TT (ingatkan sesuai jadwal)',
          ),
          _buildReminderRow(Icons.local_pharmacy, 'Konsumsi tablet Fe'),
          _buildReminderRow(Icons.science, 'Pemeriksaan lab (cek hasil)'),
          _buildReminderRow(
            Icons.medication,
            'Reminder minum vitamin (harian)',
          ),
          _buildReminderRow(Icons.bedtime, 'Reminder istirahat cukup'),
          _buildReminderRow(
            Icons.local_hospital,
            'Reminder kontrol ke fasilitas kesehatan',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildMainButton(
          _testNotificationNow,
          Icons.notifications_active,
          'Tes Notifikasi Sekarang',
        ),
        const SizedBox(height: 10),
        _buildMainButton(
          _scheduleANCNotificationExample,
          Icons.schedule,
          'Jadwalkan Notif (Minggu ke-28)',
        ),
        const SizedBox(height: 10),
        _buildMainButton(
          _scheduleDailyVitaminReminder,
          Icons.medical_information,
          'Jadwalkan Reminder Vitamin',
        ),
      ],
    );
  }

  Widget _buildMainButton(VoidCallback onPressed, IconData icon, String text) {
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
        backgroundColor: const Color(0xFF4A90E2),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 3,
      ),
    );
  }

  Widget _buildReminderRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF2E5C9A))),
          ),
          ElevatedButton(
            onPressed: () async {
              final dt = DateTime.now().add(const Duration(seconds: 10));
              await NotificationService.instance.scheduleNotification(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                title: 'Pengingat: ${text.split(' ')[0]}',
                body: text,
                scheduledDate: dt,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengingat singkat dijadwalkan (10s).'),
                  ),
                );
              }
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

  Widget _buildRiwayatCard(Map<String, String> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.orange),
        title: Text('Tanggal: ${data['tanggal']}'),
        subtitle: Text(data['hasil']!),
      ),
    );
  }
}
