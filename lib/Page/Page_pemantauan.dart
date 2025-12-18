import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async'; // ✅ TAMBAHKAN IMPORT INI
import 'Page_InputDataIbu.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> riwayatKunjungan = [];
  Timer? _refreshTimer;

  // Data untuk grafik
  List<double> _beratBadanData = [];
  List<double> _tekananDarahData = [];
  List<double> _tinggiFundusData = [];

  @override
  void initState() {
    super.initState();
    _loadDataFromServer();
    _printInitialDebugInfo();
  }

  void _printInitialDebugInfo() {
    print('🎯 DashboardPage diinisialisasi');
    print('📊 Menginisialisasi riwayat kunjungan...');
  }

  void _loadData() {
    _beratBadanData = riwayatKunjungan
        .map((e) {
          // Support both camelCase and snake_case
          final v = (e['beratBadan'] ?? e['berat_badan'])?.toString() ?? '';
          // Extract angka dari "65 kg" atau "65" → 65
          final numStr = v.replaceAll(RegExp(r'[^\d.]'), '');
          return double.tryParse(numStr);
        })
        .where((d) => d != null)
        .map((d) => d!)
        .toList();

    _tekananDarahData = riwayatKunjungan
        .map((e) {
          // Support both camelCase and snake_case
          final v = (e['tekananDarah'] ?? e['tekanan_darah'])?.toString() ?? '';
          // Extract sistolik dari "120/80" → 120
          final parts = v.split('/');
          if (parts.isNotEmpty) {
            final numStr = parts[0].replaceAll(RegExp(r'[^\d.]'), '');
            return double.tryParse(numStr);
          }
          return null;
        })
        .where((d) => d != null)
        .map((d) => d!)
        .toList();

    _tinggiFundusData = riwayatKunjungan
        .map((e) {
          // Support both camelCase and snake_case
          final v = (e['tinggiFundus'] ?? e['tinggi_fundus'])?.toString() ?? '';
          // Extract angka dari "25 cm" atau "25" → 25
          final numStr = v.replaceAll(RegExp(r'[^\d.]'), '');
          return double.tryParse(numStr);
        })
        .where((d) => d != null)
        .map((d) => d!)
        .toList();

    print('🔄 Data dimuat ulang dari server:');
    print('   - Riwayat: ${riwayatKunjungan.length} kunjungan');
    print('   - Berat Badan: $_beratBadanData');
    print('   - Tekanan Darah: $_tekananDarahData');
    print('   - Tinggi Fundus: $_tinggiFundusData');
  }

  // data change handling is now triggered by server reloads

  Future<void> _loadDataFromServer() async {
    print('🌐 Memuat data dari server...');
    try {
      final r = await ApiService.getRiwayatKunjungan();
      print('📦 Response dari server: ${r.length} items');

      if (r.isNotEmpty) {
        print('🔍 Sample data pertama: ${r[0]}');
      }

      final List<Map<String, dynamic>> list = [];
      for (var item in r) {
        list.add(Map<String, dynamic>.from(item));
      }

      print('✅ Total data ter-parse: ${list.length}');

      if (mounted) {
        setState(() {
          riwayatKunjungan = list;
          _loadData();
        });
        print(
          '✅ setState selesai, riwayatKunjungan.length = ${riwayatKunjungan.length}',
        );
      }
    } catch (e) {
      print('❌ Error loading riwayat from server: $e');
      debugPrint('Error loading riwayat from server: $e');
    }
  }

  Future<void> _openInputPage() async {
    print('📝 Membuka InputDataIbuPage...');
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InputDataIbuPage()),
    );
    print('📝 Kembali dari InputDataIbuPage');
    await _loadDataFromServer();
  }

  Map<String, String> _getDataTerbaru() {
    print(
      '📋 _getDataTerbaru dipanggil. Total riwayat: ${riwayatKunjungan.length}',
    );

    if (riwayatKunjungan.isNotEmpty) {
      final item = riwayatKunjungan[0];
      print('🔍 Data terakhir RAW: $item');

      // Support both snake_case (dari server lama) dan camelCase (dari server baru)
      final result = {
        'usiaKehamilan':
            item['usiaKehamilan']?.toString() ??
            item['usia_kehamilan']?.toString() ??
            '',
        'tekananDarah':
            item['tekananDarah']?.toString() ??
            item['tekanan_darah']?.toString() ??
            '',
        'beratBadan':
            item['beratBadan']?.toString() ??
            item['berat_badan']?.toString() ??
            '',
        'tinggiFundus':
            item['tinggiFundus']?.toString() ??
            item['tinggi_fundus']?.toString() ??
            '',
        'kadarHb':
            item['kadarHb']?.toString() ?? item['kadar_hb']?.toString() ?? '',
        'perkembanganJanin':
            item['perkembanganJanin']?.toString() ??
            item['pergerakan_janin']?.toString() ??
            '',
        'jenisKunjungan':
            item['jenisKunjungan']?.toString() ??
            item['jenis_kunjungan']?.toString() ??
            '',
        'trimester': item['trimester']?.toString() ?? '',
        'keluhan': item['keluhan']?.toString() ?? '',
        'pergerakanJanin':
            item['pergerakanJanin']?.toString() ??
            item['pergerakan_janin']?.toString() ??
            '',
        'hasilLab':
            item['hasilLab']?.toString() ?? item['hasil_lab']?.toString() ?? '',
        'hasilUSG':
            item['hasilUSG']?.toString() ?? item['hasil_usg']?.toString() ?? '',
        'catatanANC':
            item['catatanANC']?.toString() ??
            item['catatan_anc']?.toString() ??
            item['catatan']?.toString() ??
            '',
        'imunisasiTT':
            item['imunisasiTT']?.toString() ??
            item['imunisasi_tt']?.toString() ??
            '',
      };

      print('✅ Data terbaru ter-map: $result');
      return result;
    }

    print('⚠️ Tidak ada riwayat kunjungan, return empty data');
    return {
      'usiaKehamilan': '',
      'tekananDarah': '',
      'beratBadan': '',
      'tinggiFundus': '',
      'kadarHb': '',
      'perkembanganJanin': '',
      'jenisKunjungan': '',
      'trimester': '',
      'keluhan': '',
      'pergerakanJanin': '',
      'hasilLab': '',
      'hasilUSG': '',
      'catatanANC': '',
      'imunisasiTT': '',
    };
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // =======================================================
  // HELPER METHODS UNTUK DETEKSI DATA REAL
  // =======================================================

  bool _hasRealData(String? value) {
    if (value == null) return false;
    if (value.isEmpty) return false;
    if (value.contains('Silakan input')) return false;
    if (value.contains('Belum di')) return false;
    if (value.contains('input data')) return false;
    return true;
  }

  bool _hasAnyRealData(Map<String, dynamic> data) {
    return data.values.any((value) => _hasRealData(value?.toString()));
  }

  Widget _buildEmptyDataPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 32),
          const SizedBox(height: 8),
          Text(
            'Belum ada data kehamilan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik "Input Data Ibu" di bawah untuk mengisi data pertama',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.orange[600]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 180,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Input Data Sekarang',
                style: TextStyle(fontSize: 12),
              ),
              onPressed: _openInputPage,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                foregroundColor: Colors.orange[800],
                side: BorderSide(color: Colors.orange[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // WIDGET BUILD - HANYA DATA REAL
  // =======================================================

  @override
  Widget build(BuildContext context) {
    final dataTerbaru = _getDataTerbaru();
    final riwayatKunjungan = this.riwayatKunjungan;

    // GUNAKAN HANYA DATA AKTUAL, TIDAK ADA DATA DEFAULT
    final beratBadanData = _beratBadanData;
    final tekananDarahData = _tekananDarahData;
    final tinggiFundusData = _tinggiFundusData;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(riwayatKunjungan.length),
              const SizedBox(height: 25),

              // DASHBOARD KEHAMILAN - HANYA DATA REAL
              _buildSectionTitle("Dashboard Kehamilan"),
              _buildInfoCard(
                title: "Informasi Kehamilan",
                icon: Icons.pregnant_woman,
                color: const Color(0xFF4A90E2),
                children: [
                  // HANYA tampilkan jika ada data real
                  if (_hasRealData(dataTerbaru['jenisKunjungan']))
                    _buildRow(
                      "Jenis Kunjungan",
                      dataTerbaru['jenisKunjungan']!,
                    ),

                  if (_hasRealData(dataTerbaru['trimester']))
                    _buildRow("Trimester", dataTerbaru['trimester']!),

                  if (_hasRealData(dataTerbaru['usiaKehamilan']))
                    _buildRow("Usia Kehamilan", dataTerbaru['usiaKehamilan']!),

                  if (_hasRealData(dataTerbaru['tekananDarah']))
                    _buildRow("Tekanan Darah", dataTerbaru['tekananDarah']!),

                  if (_hasRealData(dataTerbaru['beratBadan']))
                    _buildRow("Berat Badan", dataTerbaru['beratBadan']!),

                  if (_hasRealData(dataTerbaru['tinggiFundus']))
                    _buildRow("Tinggi Fundus", dataTerbaru['tinggiFundus']!),

                  if (_hasRealData(dataTerbaru['kadarHb']))
                    _buildRow("Kadar Hb", dataTerbaru['kadarHb']!),

                  if (_hasRealData(dataTerbaru['imunisasiTT']))
                    _buildRow("Imunisasi TT", dataTerbaru['imunisasiTT']!),

                  if (_hasRealData(dataTerbaru['pergerakanJanin']))
                    _buildRow(
                      "Pergerakan Janin",
                      dataTerbaru['pergerakanJanin']!,
                    ),

                  if (_hasRealData(dataTerbaru['keluhan']))
                    _buildRow("Keluhan", dataTerbaru['keluhan']!),

                  if (_hasRealData(dataTerbaru['hasilLab']))
                    _buildRow("Hasil Lab", dataTerbaru['hasilLab']!),

                  if (_hasRealData(dataTerbaru['hasilUSG']))
                    _buildRow("Hasil USG", dataTerbaru['hasilUSG']!),

                  if (_hasRealData(dataTerbaru['catatanANC']))
                    _buildRow("Catatan ANC", dataTerbaru['catatanANC']!),

                  // JIKA SEMUA DATA KOSONG, tampilkan prompt
                  if (!_hasAnyRealData(dataTerbaru)) _buildEmptyDataPrompt(),

                  // INFO RIWAYAT KUNJUNGAN
                  if (riwayatKunjungan.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    _buildRow(
                      "Data Terakhir Diperbarui",
                      "Berdasarkan ${riwayatKunjungan.length} kunjungan",
                      isSecondary: true,
                    ),
                    _buildRow(
                      "Kunjungan Terakhir",
                      riwayatKunjungan[0]['tanggal']?.toString() ??
                          'Tanggal tidak tersedia',
                      isSecondary: true,
                    ),
                  ] else if (_hasAnyRealData(dataTerbaru)) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    _buildRow(
                      "Info",
                      "Belum ada data kunjungan. Input data pertama untuk mulai monitoring.",
                      isSecondary: true,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 25),

              // INPUT DATA IBU
              _buildSectionTitle("Input Data Harian / Mingguan"),
              InkWell(
                onTap: _openInputPage,
                child: _buildInfoCard(
                  title: "Input Data Ibu",
                  icon: Icons.edit_note,
                  color: Colors.green,
                  onIconTap: _openInputPage,
                  children: [
                    _buildRow("Tekanan Darah", "Input setiap kunjungan"),
                    _buildRow("Berat Badan", "Update mingguan"),
                    _buildRow("Tinggi Fundus", "Monitor perkembangan janin"),
                    _buildRow("Keluhan", "Catat jika muncul gejala"),
                    _buildRow("Pergerakan Janin", "Monitor harian"),
                    const Divider(height: 16),
                    _buildRow(
                      "Catatan ANC",
                      "Kunjungan • Hasil lab • USG • Imunisasi TT",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // GRAFIK PERKEMBANGAN - HANYA TAMPIL JIKA ADA DATA
              _buildSectionTitle("Grafik Perkembangan"),
              _buildInfoCard(
                title: "Grafik Kondisi Ibu & Janin",
                icon: Icons.show_chart,
                color: Colors.deepPurple,
                children: [
                  // Grafik Berat Badan - HANYA JIKA ADA DATA
                  if (beratBadanData.isNotEmpty) ...[
                    _buildGraph(
                      "Perkembangan Berat Badan Ibu (kg)",
                      beratBadanData,
                      minY: beratBadanData.reduce((a, b) => a < b ? a : b) - 2,
                      maxY: beratBadanData.reduce((a, b) => a > b ? a : b) + 2,
                      getColor: (value) {
                        if (value <= 55) return Colors.green;
                        if (value <= 70) return Colors.yellow;
                        return Colors.red;
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildEmptyGraph("Perkembangan Berat Badan Ibu (kg)"),
                    const SizedBox(height: 16),
                  ],

                  // Grafik Tinggi Fundus - HANYA JIKA ADA DATA
                  if (tinggiFundusData.isNotEmpty) ...[
                    _buildGraph(
                      "Tinggi Fundus / Pertumbuhan Janin (cm)",
                      tinggiFundusData,
                      minY:
                          tinggiFundusData.reduce((a, b) => a < b ? a : b) - 2,
                      maxY:
                          tinggiFundusData.reduce((a, b) => a > b ? a : b) + 2,
                      getColor: (value) {
                        if (value <= 20) return Colors.green;
                        if (value <= 30) return Colors.yellow;
                        return Colors.red;
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildEmptyGraph("Tinggi Fundus / Pertumbuhan Janin (cm)"),
                    const SizedBox(height: 16),
                  ],

                  // Grafik Tekanan Darah - HANYA JIKA ADA DATA
                  if (tekananDarahData.isNotEmpty) ...[
                    _buildGraph(
                      "Tekanan Darah Sistolik (mmHg)",
                      tekananDarahData,
                      minY:
                          tekananDarahData.reduce((a, b) => a < b ? a : b) - 5,
                      maxY:
                          tekananDarahData.reduce((a, b) => a > b ? a : b) + 5,
                      getColor: (value) {
                        if (value <= 120) return Colors.green;
                        if (value <= 139) return Colors.yellow;
                        return Colors.red;
                      },
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    _buildEmptyGraph("Tekanan Darah Sistolik (mmHg)"),
                    const SizedBox(height: 18),
                  ],

                  // Legenda - HANYA TAMPIL JIKA ADA SETIDAKNYA SATU GRAFIK
                  if (beratBadanData.isNotEmpty ||
                      tinggiFundusData.isNotEmpty ||
                      tekananDarahData.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _ColorIndicator(color: Colors.green, label: "Normal"),
                        _ColorIndicator(color: Colors.yellow, label: "Waspada"),
                        _ColorIndicator(color: Colors.red, label: "Risiko"),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Info data
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            riwayatKunjungan.isNotEmpty
                                ? 'Data grafik berdasarkan ${riwayatKunjungan.length} kunjungan terakhir'
                                : 'Input data kunjungan pertama untuk melihat grafik perkembangan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
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

  // =======================================================
  // WIDGET BUILDING METHODS
  // =======================================================

  Widget _buildHeader(int jumlahKunjungan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MyPregnancyCare",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Text(
                    "Hai, Ibu",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.waving_hand, color: Colors.amber, size: 26),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Lihat kondisi terbaru kesehatan Anda dan perkembangan janin.",
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                jumlahKunjungan.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Kunjungan",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    VoidCallback? onIconTap,
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
              GestureDetector(
                onTap: onIconTap,
                child: Icon(icon, color: color),
              ),
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

  Widget _buildRow(String label, String value, {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isSecondary ? Colors.grey : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSecondary ? Colors.grey : Color(0xFF2E5C9A),
                fontSize: isSecondary ? 12 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGraph(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text(
                  'Belum ada data',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Input data kunjungan untuk melihat grafik',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraph(
    String title,
    List<double> data, {
    required double minY,
    required double maxY,
    required Color Function(double) getColor,
  }) {
    List<BarChartGroupData> barGroups = List.generate(
      data.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data[i],
            color: getColor(data[i]),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade400, width: 1.2),
          ),
          padding: const EdgeInsets.all(12),
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.25),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade600, width: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: (maxY - minY) / 4,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "K${v.toInt() + 1}",
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      'K${group.x + 1}\n${rod.toY.toStringAsFixed(1)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorIndicator({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26, width: 1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
