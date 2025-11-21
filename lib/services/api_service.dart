import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // BENAR - sesuaikan dengan web server
  static String baseUrl = "http://192.168.1.5/my_pregnancy_api";

  /// POST data ibu ke server
  static Future<Map<String, dynamic>> insertDataIbu({
    required String tekananDarah,
    required String beratBadan,
    required String keluhan,
    required String pergerakanJanin,
    required String tanggalPemeriksaan,
    required String jenisKunjungan,
    required String trimester,
    required String hasilLab,
    required String hasilUSG,
    required String imunisasiTT,
    required String catatanANC,
  }) async {
    try {
      var url = Uri.parse("$baseUrl/ibu/insert_data.php");

      var response = await http.post(
        url,
        body: {
          "tekanan_darah": tekananDarah,
          "berat_badan": beratBadan,
          "keluhan": keluhan,
          "pergerakan_janin": pergerakanJanin,
          "tanggal_pemeriksaan": tanggalPemeriksaan,
          "jenis_kunjungan": jenisKunjungan,
          "trimester": trimester,
          "hasil_lab": hasilLab,
          "hasil_usg": hasilUSG,
          "imunisasi_tt": imunisasiTT,
          "catatan_anc": catatanANC,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// GET data ibu
  static Future<List<dynamic>> getDataIbu() async {
    try {
      var url = Uri.parse("$baseUrl/ibu/get_data.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Error get data ibu: $e');
      return [];
    }
  }

  /// GET data grafik ibu
  static Future<List<dynamic>> getGrafik() async {
    try {
      var url = Uri.parse("$baseUrl/ibu/grafik_data.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Error get grafik: $e');
      return [];
    }
  }

  /// GET jadwal ANC
  static Future<List<dynamic>> getJadwalANC() async {
    try {
      var url = Uri.parse("$baseUrl/anc/jadwal.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Error get jadwal ANC: $e');
      return [];
    }
  }

  /// POST jadwal ANC baru
  static Future<Map<String, dynamic>> insertJadwalANC({
    required String title,
    required String type,
    required String note,
    required String tanggal,
    required String week,
  }) async {
    try {
      var url = Uri.parse("$baseUrl/anc/jadwal.php");

      var response = await http.post(
        url,
        body: {
          "title": title,
          "type": type,
          "note": note,
          "tanggal": tanggal,
          "week": week,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// GET reminder vitamin / notif
  static Future<List<dynamic>> getReminder() async {
    try {
      var url = Uri.parse("$baseUrl/anc/reminder.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Error get reminder: $e');
      return [];
    }
  }

  /// POST update reminder
  static Future<Map<String, dynamic>> updateReminder({
    required String vitamin,
    required String tt,
    required String istirahat,
  }) async {
    try {
      var url = Uri.parse("$baseUrl/anc/reminder.php");

      var response = await http.post(
        url,
        body: {"vitamin": vitamin, "tt": tt, "istirahat": istirahat},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
