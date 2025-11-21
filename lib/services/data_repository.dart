import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DataRepository with ChangeNotifier {
  // Singleton instance
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal() {
    _initializeData();
  }

  static const String _dataIbuKey = 'data_ibu';
  static const String _riwayatKunjunganKey = 'riwayat_kunjungan';
  static const String _jadwalANCKey = 'jadwal_anc';

  // Data Ibu - Data fresh tanpa dummy
  Map<String, dynamic> dataIbu = {
    'usiaKehamilan': '',
    'tekananDarah': '',
    'beratBadan': '',
    'kadarHb': '',
    'perkembanganJanin': '',
    'tinggiFundus': '',
  };

  // Jadwal ANC - KOSONG tanpa data dummy
  List<Map<String, String>> _jadwalANC = [];

  // Riwayat Kunjungan - KOSONG tanpa data dummy
  List<Map<String, dynamic>> riwayatKunjungan = [];

  // =======================================================
  // INITIALIZATION & PERSISTENCE
  // =======================================================

  Future<void> _initializeData() async {
    print('🎯 DataRepository diinisialisasi');
    await _loadFromStorage();

    // Jika data ibu masih kosong, set nilai default kosong
    if (dataIbu['usiaKehamilan']?.isEmpty ?? true) {
      dataIbu = {
        'usiaKehamilan': 'Silakan input data kehamilan',
        'tekananDarah': 'Belum diukur',
        'beratBadan': 'Belum diukur',
        'kadarHb': 'Belum diukur',
        'perkembanganJanin': 'Silakan input perkembangan',
        'tinggiFundus': 'Belum diukur',
      };
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load data ibu
      final dataIbuJson = prefs.getString(_dataIbuKey);
      if (dataIbuJson != null) {
        final loadedData = Map<String, dynamic>.from(json.decode(dataIbuJson));
        dataIbu.addAll(loadedData);
        print('📥 Data ibu dimuat dari storage: $loadedData');
      }

      // Load riwayat kunjungan
      final riwayatJson = prefs.getString(_riwayatKunjunganKey);
      if (riwayatJson != null) {
        final loadedList = List<dynamic>.from(json.decode(riwayatJson));
        riwayatKunjungan = loadedList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        print('📥 Riwayat kunjungan dimuat: ${riwayatKunjungan.length} data');
      }

      // Load jadwal ANC
      final jadwalJson = prefs.getString(_jadwalANCKey);
      if (jadwalJson != null) {
        final loadedList = List<dynamic>.from(json.decode(jadwalJson));
        _jadwalANC = loadedList
            .map((item) => Map<String, String>.from(item))
            .toList();
        print('📥 Jadwal ANC dimuat: ${_jadwalANC.length} data');
      }
    } catch (e) {
      print('❌ Error loading from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save data ibu
      await prefs.setString(_dataIbuKey, json.encode(dataIbu));

      // Save riwayat kunjungan
      await prefs.setString(
        _riwayatKunjunganKey,
        json.encode(riwayatKunjungan),
      );

      // Save jadwal ANC
      await prefs.setString(_jadwalANCKey, json.encode(_jadwalANC));

      print('💾 Data disimpan ke storage');
    } catch (e) {
      print('❌ Error saving to storage: $e');
    }
  }

  // =======================================================
  // METHOD UNTUK DATA IBU
  // =======================================================

  /// Update data ibu dengan data baru
  Future<void> updateDataIbu(Map<String, dynamic> newData) async {
    dataIbu.addAll(newData);
    await _saveToStorage();
    notifyListeners();
    print('✅ Data ibu diperbarui: $newData');
  }

  /// Inisialisasi data ibu pertama kali
  Future<void> initDataIbu({
    required String usiaKehamilan,
    required String tekananDarah,
    required String beratBadan,
    required String kadarHb,
    required String perkembanganJanin,
    String tinggiFundus = '',
  }) async {
    dataIbu = {
      'usiaKehamilan': usiaKehamilan,
      'tekananDarah': tekananDarah,
      'beratBadan': beratBadan,
      'kadarHb': kadarHb,
      'perkembanganJanin': perkembanganJanin,
      'tinggiFundus': tinggiFundus,
    };
    await _saveToStorage();
    notifyListeners();
    print('✅ Data ibu diinisialisasi: $dataIbu');
  }

  /// Get data ibu
  Map<String, dynamic> getDataIbu() {
    return Map.from(dataIbu);
  }

  /// Update specific field data ibu
  Future<void> updateFieldDataIbu(String key, dynamic value) async {
    dataIbu[key] = value;
    await _saveToStorage();
    notifyListeners();
    print('✏️ Field $key diperbarui: $value');
  }

  // =======================================================
  // METHOD UNTUK RIWAYAT KUNJUNGAN
  // =======================================================

  /// Tambah riwayat kunjungan baru
  Future<void> tambahRiwayatKunjunganBaru({
    required String tanggal,
    required String hasil,
    required Map<String, dynamic> detail,
    String? gambarPath,
    String? catatan,
  }) async {
    final newRiwayat = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'tanggal': tanggal,
      'hasil': hasil,
      'gambar': gambarPath,
      'catatan': catatan ?? '',
      'detail': detail,
    };

    print('💾 Menyimpan riwayat baru:');
    print('   - Tanggal: $tanggal');
    print('   - Berat Badan: ${detail['berat_badan']}');
    print('   - Tekanan Darah: ${detail['tekanan_darah']}');
    print('   - Tinggi Fundus: ${detail['tinggi_fundus']}');
    print('   - Trimester: ${detail['trimester']}');

    riwayatKunjungan.insert(0, newRiwayat);

    // Update data ibu dengan data terbaru
    await _updateDataIbu(detail);

    await _saveToStorage();
    notifyListeners();

    print('✅ Riwayat berhasil disimpan. Total: ${riwayatKunjungan.length}');
  }

  /// Method lama untuk kompatibilitas
  Future<void> tambahRiwayatKunjungan(Map<String, dynamic> riwayatBaru) async {
    final newRiwayat = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'tanggal': riwayatBaru['tanggal'] ?? DateTime.now().toString(),
      'hasil': riwayatBaru['hasil'] ?? '',
      'gambar': riwayatBaru['gambarPath'] ?? riwayatBaru['gambar'],
      'catatan': riwayatBaru['catatan'] ?? riwayatBaru['catatanANC'] ?? '',
      'detail': riwayatBaru['detail'] ?? riwayatBaru,
    };

    riwayatKunjungan.insert(0, newRiwayat);

    await _saveToStorage();
    notifyListeners();

    print(
      '✅ Riwayat disimpan dengan method lama. Total: ${riwayatKunjungan.length}',
    );
  }

  Future<void> _updateDataIbu(Map<String, dynamic> detail) async {
    // Update data ibu dengan data terbaru dari riwayat
    if (detail['berat_badan'] != null &&
        detail['berat_badan'].toString().isNotEmpty) {
      dataIbu['beratBadan'] = '${detail['berat_badan']} kg';
    }
    if (detail['tekanan_darah'] != null &&
        detail['tekanan_darah'].toString().isNotEmpty) {
      String diastolik = '80';
      if (detail['tekanan_darah'].toString().contains('/')) {
        List<String> parts = detail['tekanan_darah'].toString().split('/');
        if (parts.length > 1) diastolik = parts[1];
      }
      dataIbu['tekananDarah'] = '${detail['tekanan_darah']}/$diastolik mmHg';
    }
    if (detail['trimester'] != null &&
        detail['trimester'].toString().isNotEmpty) {
      dataIbu['usiaKehamilan'] = '${detail['trimester']}';
    }
    if (detail['tinggi_fundus'] != null &&
        detail['tinggi_fundus'].toString().isNotEmpty) {
      dataIbu['tinggiFundus'] = '${detail['tinggi_fundus']} cm';
    }

    await _saveToStorage();
  }

  /// Get semua riwayat kunjungan
  List<Map<String, dynamic>> getRiwayatKunjungan() {
    return List.from(riwayatKunjungan);
  }

  /// Get riwayat kunjungan terbatas
  List<Map<String, dynamic>> getRiwayatTerbatas(int limit) {
    if (riwayatKunjungan.length <= limit) {
      return List.from(riwayatKunjungan);
    }
    return List.from(riwayatKunjungan.take(limit));
  }

  /// Hapus riwayat kunjungan
  Future<void> hapusRiwayatKunjungan(int index) async {
    if (index >= 0 && index < riwayatKunjungan.length) {
      riwayatKunjungan.removeAt(index);
      await _saveToStorage();
      notifyListeners();
      print('🗑️ Riwayat kunjungan dihapus: index $index');
    }
  }

  /// Clear semua riwayat kunjungan
  Future<void> clearRiwayatKunjungan() async {
    riwayatKunjungan.clear();
    await _saveToStorage();
    notifyListeners();
    print('🗑️ Semua riwayat kunjungan dihapus');
  }

  // =======================================================
  // METHOD UNTUK JADWAL ANC - TANPA DATA STANDAR
  // =======================================================

  /// Get semua jadwal ANC - TIDAK ADA GENERATE OTOMATIS
  List<Map<String, String>> get jadwalANC {
    return List.from(_jadwalANC);
  }

  /// Tambah jadwal ANC baru
  Future<void> tambahJadwalANC(Map<String, String> jadwalBaru) async {
    _jadwalANC.add(jadwalBaru);

    // Sort jadwal berdasarkan minggu
    _jadwalANC.sort((a, b) {
      int mingguA = int.tryParse(a['minggu'] ?? '0') ?? 0;
      int mingguB = int.tryParse(b['minggu'] ?? '0') ?? 0;
      return mingguA.compareTo(mingguB);
    });

    await _saveToStorage();
    notifyListeners();
    print('✅ Jadwal ANC ditambahkan: $jadwalBaru');
  }

  /// Tambah jadwal ANC dengan parameter terpisah
  Future<void> tambahJadwalANCBaru({
    required String minggu,
    required String judul,
    required String tanggal,
    required String catatan,
  }) async {
    final jadwalBaru = {
      'minggu': minggu,
      'judul': judul,
      'tanggal': tanggal,
      'catatan': catatan,
    };

    _jadwalANC.add(jadwalBaru);

    // Sort jadwal berdasarkan minggu
    _jadwalANC.sort((a, b) {
      int mingguA = int.tryParse(a['minggu'] ?? '0') ?? 0;
      int mingguB = int.tryParse(b['minggu'] ?? '0') ?? 0;
      return mingguA.compareTo(mingguB);
    });

    await _saveToStorage();
    notifyListeners();
    print('✅ Jadwal ANC ditambahkan: $jadwalBaru');
  }

  /// Edit jadwal ANC
  Future<void> editJadwalANC(int index, Map<String, String> jadwalBaru) async {
    if (index >= 0 && index < _jadwalANC.length) {
      _jadwalANC[index] = jadwalBaru;

      // Sort jadwal setelah edit
      _jadwalANC.sort((a, b) {
        int mingguA = int.tryParse(a['minggu'] ?? '0') ?? 0;
        int mingguB = int.tryParse(b['minggu'] ?? '0') ?? 0;
        return mingguA.compareTo(mingguB);
      });

      await _saveToStorage();
      notifyListeners();
      print('✏️ Jadwal ANC diedit: index $index');
    }
  }

  /// Hapus jadwal ANC
  Future<void> hapusJadwalANC(int index) async {
    if (index >= 0 && index < _jadwalANC.length) {
      _jadwalANC.removeAt(index);
      await _saveToStorage();
      notifyListeners();
      print('🗑️ Jadwal ANC dihapus: index $index');
    }
  }

  /// Clear semua jadwal ANC
  Future<void> clearJadwalANC() async {
    _jadwalANC.clear();
    await _saveToStorage();
    notifyListeners();
    print('🗑️ Semua jadwal ANC dihapus');
  }

  /// Get jadwal ANC by index
  Map<String, String>? getJadwalByIndex(int index) {
    if (index >= 0 && index < _jadwalANC.length) {
      return Map.from(_jadwalANC[index]);
    }
    return null;
  }

  /// Get jadwal ANC by minggu
  Map<String, String>? getJadwalByMinggu(String minggu) {
    try {
      return _jadwalANC.firstWhere((jadwal) => jadwal['minggu'] == minggu);
    } catch (e) {
      return null;
    }
  }

  /// Get jadwal ANC yang akan datang
  List<Map<String, String>> getJadwalMendatang() {
    final now = DateTime.now();
    return _jadwalANC.where((jadwal) {
      final tanggal = DateTime.tryParse(jadwal['tanggal'] ?? '');
      return tanggal != null && tanggal.isAfter(now);
    }).toList();
  }

  /// Get jadwal ANC yang sudah lewat
  List<Map<String, String>> getJadwalTerlewat() {
    final now = DateTime.now();
    return _jadwalANC.where((jadwal) {
      final tanggal = DateTime.tryParse(jadwal['tanggal'] ?? '');
      return tanggal != null && tanggal.isBefore(now);
    }).toList();
  }

  // =======================================================
  // METHOD UNTUK ANALISIS DATA
  // =======================================================

  List<double> getPerkembanganBeratBadan() {
    List<double> data = [];
    print(
      '📊 Mengambil data berat badan dari ${riwayatKunjungan.length} riwayat',
    );

    for (var riwayat in riwayatKunjungan) {
      final detail = riwayat['detail'] ?? {};
      final beratBadanStr = detail['berat_badan']?.toString() ?? '';

      print('   - Riwayat: $beratBadanStr');

      if (beratBadanStr.isNotEmpty) {
        // Bersihkan string dan extract angka
        final cleaned = beratBadanStr
            .replaceAll(' kg', '')
            .replaceAll('kg', '')
            .replaceAll(' ', '')
            .trim();

        final beratBadan = double.tryParse(cleaned);

        if (beratBadan != null && beratBadan > 30 && beratBadan < 150) {
          data.add(beratBadan);
          print('     ✅ Berat badan valid: $beratBadan kg');
        } else {
          print('     ❌ Berat badan tidak valid: $cleaned');
        }
      }
    }

    print('📈 Data berat badan akhir: $data');
    return data;
  }

  List<double> getPerkembanganTekananDarah() {
    List<double> data = [];
    print(
      '📊 Mengambil data tekanan darah dari ${riwayatKunjungan.length} riwayat',
    );

    for (var riwayat in riwayatKunjungan) {
      final detail = riwayat['detail'] ?? {};
      final tekananDarahStr = detail['tekanan_darah']?.toString() ?? '';

      print('   - Riwayat: $tekananDarahStr');

      if (tekananDarahStr.isNotEmpty) {
        // Extract angka pertama (sistolik)
        final regex = RegExp(r'(\d+)[/\-]');
        final match = regex.firstMatch(tekananDarahStr);

        if (match != null) {
          final tekananDarah = double.tryParse(match.group(1)!);

          if (tekananDarah != null && tekananDarah > 80 && tekananDarah < 200) {
            data.add(tekananDarah);
            print('     ✅ Tekanan darah valid: $tekananDarah mmHg');
          } else {
            print('     ❌ Tekanan darah tidak valid: ${match.group(1)}');
          }
        } else {
          print('     ❌ Format tekanan darah tidak dikenali: $tekananDarahStr');
        }
      }
    }

    print('📈 Data tekanan darah akhir: $data');
    return data;
  }

  List<double> getPerkembanganTinggiFundus() {
    List<double> data = [];
    print(
      '📊 Mengambil data tinggi fundus dari ${riwayatKunjungan.length} riwayat',
    );

    for (var riwayat in riwayatKunjungan) {
      final detail = riwayat['detail'] ?? {};
      final tinggiFundusStr = detail['tinggi_fundus']?.toString() ?? '';

      print('   - Riwayat: $tinggiFundusStr');

      if (tinggiFundusStr.isNotEmpty) {
        // Bersihkan string dan extract angka
        final cleaned = tinggiFundusStr
            .replaceAll(' cm', '')
            .replaceAll('cm', '')
            .replaceAll(' ', '')
            .trim();

        final tinggiFundus = double.tryParse(cleaned);

        if (tinggiFundus != null && tinggiFundus > 10 && tinggiFundus < 50) {
          data.add(tinggiFundus);
          print('     ✅ Tinggi fundus valid: $tinggiFundus cm');
        } else {
          print('     ❌ Tinggi fundus tidak valid: $cleaned');
        }
      }
    }

    print('📈 Data tinggi fundus akhir: $data');
    return data;
  }

  // =======================================================
  // METHOD UTILITY
  // =======================================================

  Map<String, dynamic> getDataTerbaru() {
    return Map.from(dataIbu);
  }

  /// Refresh data
  Future<void> refreshData() async {
    await _loadFromStorage();
    notifyListeners();
    print('🔄 Data diperbarui dari storage');
  }

  /// Get total jumlah kunjungan
  int getTotalKunjungan() {
    return riwayatKunjungan.length;
  }

  /// Get jumlah jadwal ANC
  int getTotalJadwalANC() {
    return _jadwalANC.length;
  }

  /// Cek apakah ada data
  bool hasData() {
    return riwayatKunjungan.isNotEmpty || _jadwalANC.isNotEmpty;
  }

  /// Cek apakah ada jadwal ANC
  bool hasJadwalANC() {
    return _jadwalANC.isNotEmpty;
  }

  /// Get statistik real dari data
  Map<String, dynamic> getStatistikKehamilan() {
    final beratBadanData = getPerkembanganBeratBadan();
    final tekananDarahData = getPerkembanganTekananDarah();
    final tinggiFundusData = getPerkembanganTinggiFundus();

    return {
      'totalKunjungan': riwayatKunjungan.length,
      'totalJadwal': _jadwalANC.length,
      'rataRataBeratBadan': beratBadanData.isEmpty
          ? 0
          : beratBadanData.reduce((a, b) => a + b) / beratBadanData.length,
      'rataRataTekananDarah': tekananDarahData.isEmpty
          ? 0
          : tekananDarahData.reduce((a, b) => a + b) / tekananDarahData.length,
      'rataRataTinggiFundus': tinggiFundusData.isEmpty
          ? 0
          : tinggiFundusData.reduce((a, b) => a + b) / tinggiFundusData.length,
      'beratBadanTerakhir': beratBadanData.isEmpty ? 0 : beratBadanData.last,
      'tekananDarahTerakhir': tekananDarahData.isEmpty
          ? 0
          : tekananDarahData.last,
      'tinggiFundusTerakhir': tinggiFundusData.isEmpty
          ? 0
          : tinggiFundusData.last,
    };
  }

  /// Cek apakah data sudah diinisialisasi
  bool isDataInitialized() {
    return dataIbu['usiaKehamilan']?.isNotEmpty == true &&
        dataIbu['usiaKehamilan'] != 'Silakan input data kehamilan';
  }

  /// Reset semua data
  Future<void> resetAllData() async {
    dataIbu = {
      'usiaKehamilan': 'Silakan input data kehamilan',
      'tekananDarah': 'Belum diukur',
      'beratBadan': 'Belum diukur',
      'kadarHb': 'Belum diukur',
      'perkembanganJanin': 'Silakan input perkembangan',
      'tinggiFundus': 'Belum diukur',
    };
    riwayatKunjungan.clear();
    _jadwalANC.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
    print('🔄 Semua data direset');
  }

  // =======================================================
  // METHOD TAMBAHAN UNTUK DEBUG
  // =======================================================

  /// Debug semua data
  void debugAllData() {
    print('\n=== DEBUG COMPLETE DATA ===');
    print('DATA IBU: $dataIbu');
    print('USIA KEHAMILAN: ${dataIbu['usiaKehamilan']}');
    print('RIWAYAT COUNT: ${riwayatKunjungan.length}');

    for (int i = 0; i < riwayatKunjungan.length; i++) {
      final riwayat = riwayatKunjungan[i];
      final detail = riwayat['detail'] ?? {};
      print('RIWAYAT $i:');
      print('  - Tanggal: ${riwayat['tanggal']}');
      print('  - Berat Badan: ${detail['berat_badan']}');
      print('  - Tekanan Darah: ${detail['tekanan_darah']}');
      print('  - Tinggi Fundus: ${detail['tinggi_fundus']}');
      print('  - Trimester: ${detail['trimester']}');
    }

    print('JADWAL ANC COUNT: ${_jadwalANC.length}');
    for (var jadwal in _jadwalANC) {
      print('JADWAL: ${jadwal['minggu']} minggu - ${jadwal['judul']}');
    }

    print('GRAFIK DATA:');
    print('  - Berat Badan: ${getPerkembanganBeratBadan()}');
    print('  - Tekanan Darah: ${getPerkembanganTekananDarah()}');
    print('  - Tinggi Fundus: ${getPerkembanganTinggiFundus()}');
    print('============================\n');
  }

  /// Print debug info
  void printDebugInfo() {
    print('=== DEBUG DATA REPOSITORY ===');
    print('Data Ibu: $dataIbu');
    print('Jumlah Riwayat: ${riwayatKunjungan.length}');
    print('Jumlah Jadwal ANC: ${_jadwalANC.length}');
    print('Berat Badan Data: ${getPerkembanganBeratBadan()}');
    print('Tekanan Darah Data: ${getPerkembanganTekananDarah()}');
    print('Tinggi Fundus Data: ${getPerkembanganTinggiFundus()}');
    print('=============================');
  }
}
