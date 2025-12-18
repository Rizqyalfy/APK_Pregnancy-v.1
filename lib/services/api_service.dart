import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = "http://192.168.1.7/my_pregnancy_api";
  static bool debug = true; // set false di production

  static void _log(String tag, Uri url, http.BaseResponse response, {Object? payload}) {
    if (!debug) return;
    final status = response.statusCode;
    final body = (response is http.Response) ? response.body : '<streamed>';
    
    // Tampilkan error detail untuk status >= 400
    if (status >= 400) {
      print('[API][ERROR][$tag] ${url.toString()}');
      print('  Status: $status');
      print('  Payload: ${payload ?? '-'}');
      print('  Response Body: ${body.isEmpty ? '<empty>' : body}');
      if (response.headers.isNotEmpty) {
        print('  Content-Type: ${response.headers['content-type'] ?? 'not set'}');
      }
    } else {
      print('[API][$tag] ${url.toString()} | status=$status | payload=${payload ?? '-'} | body=$body');
    }
  }

  static void _logError(String tag, Uri url, Object error, {Object? payload}) {
    if (!debug) return;
    print('[API][ERROR][$tag] ${url.toString()} | error=$error | payload=${payload ?? '-'}');
  }

  // ========================================
  // PROFIL & JURNAL
  // ========================================

  static Future<Map<String, dynamic>> getProfilIbu() async {
    final url = Uri.parse("$baseUrl/profil/profil.php");
    try {
      final res = await http.get(url);
      _log('GET profil', url, res);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) return data;
      }
      return {};
    } catch (e) {
      _logError('GET profil', url, e);
      return {};
    }
  }

  static Future<Map<String, dynamic>> saveProfilIbu({required String nama, required String usiaIbu, String? usiaKehamilan}) async {
    final url = Uri.parse("$baseUrl/profil/profil.php");
    final payload = {
      'nama': nama,
      'usia_ibu': usiaIbu,
      if (usiaKehamilan != null) 'usia_kehamilan': usiaKehamilan,
    };
    try {
      final res = await http.post(url, body: payload);
      _log('POST profil', url, res, payload: payload);
      if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
      return {'status': 'error', 'message': 'HTTP ${res.statusCode}'};
    } catch (e) {
      _logError('POST profil', url, e, payload: payload);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getJurnalIbu() async {
    final url = Uri.parse("$baseUrl/profil/jurnal.php");
    try {
      final res = await http.get(url);
      _log('GET jurnal', url, res);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      _logError('GET jurnal', url, e);
      return [];
    }
  }

  static Future<Map<String, dynamic>> addJurnalIbu({required String judul, required String tanggal, String? catatan}) async {
    final url = Uri.parse("$baseUrl/profil/jurnal.php");
    final payload = {
      'judul': judul,
      'tanggal': tanggal,
      if (catatan != null) 'catatan': catatan,
    };
    try {
      final res = await http.post(url, body: payload);
      _log('POST jurnal', url, res, payload: payload);
      if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
      return {'status': 'error', 'message': 'HTTP ${res.statusCode}'};
    } catch (e) {
      _logError('POST jurnal', url, e, payload: payload);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteJurnalIbu(int id) async {
    final url = Uri.parse("$baseUrl/profil/jurnal.php?id=$id");
    try {
      final res = await http.delete(url);
      _log('DELETE jurnal', url, res);
      if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
      return {'status': 'error', 'message': 'HTTP ${res.statusCode}'};
    } catch (e) {
      _logError('DELETE jurnal', url, e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// POST data ibu ke server (sesuai form InputDataIbuPage)
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
    // Opsional: tambahkan jika ada
    String? tinggiFundus,
    String? kadarHb,
    String? fotoUSGPath, // Path file foto USG
  }) async {
    try {
      var url = Uri.parse("$baseUrl/ibu/insert_data.php");

      // Jika ada foto, gunakan multipart request
      if (fotoUSGPath != null && fotoUSGPath.isNotEmpty) {
        var request = http.MultipartRequest('POST', url);
        
        // Tambahkan fields
        request.fields['tekanan_darah'] = tekananDarah;
        request.fields['berat_badan'] = beratBadan;
        request.fields['keluhan'] = keluhan;
        request.fields['pergerakan_janin'] = pergerakanJanin;
        request.fields['tanggal_pemeriksaan'] = tanggalPemeriksaan;
        request.fields['jenis_kunjungan'] = jenisKunjungan;
        request.fields['trimester'] = trimester;
        request.fields['hasil_lab'] = hasilLab;
        request.fields['hasil_usg'] = hasilUSG;
        request.fields['imunisasi_tt'] = imunisasiTT;
        request.fields['catatan_anc'] = catatanANC;
        
        if (tinggiFundus != null && tinggiFundus.isNotEmpty) {
          request.fields['tinggi_fundus'] = tinggiFundus;
        }
        if (kadarHb != null && kadarHb.isNotEmpty) {
          request.fields['kadar_hb'] = kadarHb;
        }

        // Tambahkan file foto
        var file = await http.MultipartFile.fromPath('foto_usg', fotoUSGPath);
        request.files.add(file);

        if (debug) {
          print('[API][POST insert_data (multipart)] ${url.toString()}');
          print('[API] Fields: ${request.fields}');
          print('[API] File: foto_usg = ${file.filename} (${file.length} bytes)');
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (debug) {
          print('[API][POST insert_data (multipart)] status=${response.statusCode}');
          print('[API] Response body: ${response.body}');
        }

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
        }
      } else {
        // Jika tidak ada foto, gunakan POST biasa
        final Map<String, String> payload = {
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
        };

        if (tinggiFundus != null && tinggiFundus.isNotEmpty) {
          payload["tinggi_fundus"] = tinggiFundus;
        }
        if (kadarHb != null && kadarHb.isNotEmpty) {
          payload["kadar_hb"] = kadarHb;
        }

        var response = await http.post(url, body: payload);

        _log('POST insert_data', url, response, payload: payload);

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
        }
      }
    } catch (e) {
      _logError('POST insert_data', Uri.parse("$baseUrl/ibu/insert_data.php"), e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// GET data ibu terbaru (untuk Dashboard)
  static Future<Map<String, dynamic>?> getDataIbuTerbaru() async {
    try {
      var url = Uri.parse("$baseUrl/ibu/get_data.php?limit=1");
      var response = await http.get(url);

      _log('GET data_terbaru', url, response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0];
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      _logError('GET data_terbaru', Uri.parse("$baseUrl/ibu/get_data.php?limit=1"), e);
      return null;
    }
  }

  /// GET semua riwayat kunjungan
  static Future<List<dynamic>> getRiwayatKunjungan() async {
    try {
      var url = Uri.parse("$baseUrl/ibu/get_data.php");
      var response = await http.get(url);

      _log('GET riwayat', url, response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        return [];
      }
    } catch (e) {
      _logError('GET riwayat', Uri.parse("$baseUrl/ibu/get_data.php"), e);
      return [];
    }
  }

  /// GET data untuk grafik (harus kembalikan array: [{berat_badan, tanggal}, ...])
  static Future<List<dynamic>> getGrafikData() async {
    try {
      var url = Uri.parse("$baseUrl/ibu/grafik_data.php");
      var response = await http.get(url);

      _log('GET grafik', url, response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        return [];
      }
    } catch (e) {
      _logError('GET grafik', Uri.parse("$baseUrl/ibu/grafik_data.php"), e);
      return [];
    }
  }

  /// GET jadwal ANC (harus kembalikan list dengan field: minggu, judul, tanggal, catatan)
  static Future<List<dynamic>> getJadwalANC() async {
    try {
      var url = Uri.parse("$baseUrl/anc/jadwal.php");
      var response = await http.get(url);

      _log('GET jadwal', url, response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        return [];
      }
    } catch (e) {
      _logError('GET jadwal', Uri.parse("$baseUrl/anc/jadwal.php"), e);
      return [];
    }
  }

  /// POST jadwal ANC baru — SESUAIKAN DENGAN FRONTEND
  static Future<Map<String, dynamic>> insertJadwalANC({
    required String minggu,      // e.g. "12"
    required String judul,       // e.g. "ANC Trimester I"
    required String tanggal,     // e.g. "2025-04-10"
    String jam = "09:00",        // e.g. "09:00"
    required String catatan,     // e.g. "Pemeriksaan awal"
  }) async {
    try {
      var url = Uri.parse("$baseUrl/anc/jadwal.php");

      var response = await http.post(
        url,
        body: {
          "minggu": minggu,
          "judul": judul,
          "tanggal": tanggal,
          "jam": jam,
          "catatan": catatan,
        },
      );

      _log('POST jadwal', url, response, payload: {
        "minggu": minggu,
        "judul": judul,
        "tanggal": tanggal,
        "jam": jam,
        "catatan": catatan,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      _logError('POST jadwal', Uri.parse("$baseUrl/anc/jadwal.php"), e, payload: {
        "minggu": minggu,
        "judul": judul,
        "tanggal": tanggal,
        "catatan": catatan,
      });
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// DELETE jadwal ANC (opsional, tapi direkomendasikan)
  static Future<bool> deleteJadwalANC(int id) async {
    try {
      var url = Uri.parse("$baseUrl/anc/jadwal.php?id=$id");
      var response = await http.delete(url);
      _log('DELETE jadwal', url, response);
      return response.statusCode == 200;
    } catch (e) {
      _logError('DELETE jadwal', Uri.parse("$baseUrl/anc/jadwal.php?id=$id"), e);
      return false;
    }
  }

  /// UPDATE jadwal ANC
  static Future<Map<String, dynamic>> updateJadwalANC({
    required int id,
    required String minggu,
    required String judul,
    required String tanggal,
    String jam = "09:00",
    required String catatan,
  }) async {
    try {
      var url = Uri.parse("$baseUrl/anc/jadwal.php?id=$id");

      var response = await http.put(
        url,
        body: {
          "minggu": minggu,
          "judul": judul,
          "tanggal": tanggal,
          "jam": jam,
          "catatan": catatan,
        },
      );

      _log('PUT jadwal', url, response, payload: {
        "minggu": minggu,
        "judul": judul,
        "tanggal": tanggal,
        "jam": jam,
        "catatan": catatan,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      _logError('PUT jadwal', Uri.parse("$baseUrl/anc/jadwal.php?id=$id"), e, payload: {
        "minggu": minggu,
        "judul": judul,
        "tanggal": tanggal,
        "catatan": catatan,
      });
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ========================================
  // REMINDER (opsional — sesuaikan jika dipakai)
  // ========================================

  static Future<List<dynamic>> getReminder() async {
    try {
      var url = Uri.parse("$baseUrl/anc/reminder.php");
      var response = await http.get(url);
      _log('GET reminder', url, response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      _logError('GET reminder', Uri.parse("$baseUrl/anc/reminder.php"), e);
      return [];
    }
  }

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
      _log('POST reminder', url, response, payload: {"vitamin": vitamin, "tt": tt, "istirahat": istirahat});
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      _logError('POST reminder', Uri.parse("$baseUrl/anc/reminder.php"), e, payload: {"vitamin": vitamin, "tt": tt, "istirahat": istirahat});
      return {'status': 'error', 'message': e.toString()};
    }
  }
}