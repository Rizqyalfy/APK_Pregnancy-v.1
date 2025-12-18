import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usiaController = TextEditingController();
  final _usiaKehamilanController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _usiaController.dispose();
    _usiaKehamilanController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final inputNama = _namaController.text.trim();
      final inputUsia = _usiaController.text.trim();
      final inputUsiaKehamilan = _usiaKehamilanController.text.trim();
      
      // Validasi: cek data dari database terlebih dahulu
      try {
        final dbProfil = await ApiService.getProfilIbu();
        if (dbProfil.isNotEmpty && dbProfil['nama'] != null) {
          final dbNama = dbProfil['nama'].toString();
          final dbUsiaIbu = dbProfil['usia_ibu']?.toString();
          
          // Cek validasi secara terpisah untuk pesan error yang spesifik
          final namaSalah = dbNama.toLowerCase() != inputNama.toLowerCase();
          final usiaSalah = dbUsiaIbu != null && dbUsiaIbu != inputUsia;
          
          if (namaSalah || usiaSalah) {
            String errorMessage = '';
            
            if (namaSalah && usiaSalah) {
              errorMessage = 'Nama dan usia ibu salah. Gunakan "$dbNama" dan usia $dbUsiaIbu tahun.';
            } else if (namaSalah) {
              errorMessage = 'Nama salah. Gunakan nama "$dbNama" yang sudah terdaftar.';
            } else if (usiaSalah) {
              errorMessage = 'Usia ibu salah. Gunakan usia $dbUsiaIbu tahun yang sudah terdaftar.';
            }
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            setState(() => _loading = false);
            return;
          }
          // Nama dan usia ibu sama → Boleh login (usia kehamilan boleh berbeda)
          debugPrint('✅ Validasi berhasil: Nama dan usia ibu cocok, usia kehamilan akan diupdate');
        }
      } catch (e) {
        debugPrint('⚠️ Gagal cek database untuk validasi: $e');
        // Jika gagal koneksi atau database kosong, tetap lanjutkan login (first time user)
      }
      
      // Simpan data ke database melalui API
      final result = await ApiService.saveProfilIbu(
        nama: inputNama,
        usiaIbu: inputUsia,
        usiaKehamilan: inputUsiaKehamilan,
      );
      debugPrint('✅ Profil berhasil disimpan ke database: $result');
      
      // Simpan status login ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF4A90E2).withOpacity(0.15),
                    child: const Icon(Icons.pregnant_woman, color: Color(0xFF4A90E2)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'MyPregnancyCare',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E5C9A),
                        ),
                      ),
                      Text(
                        'Masuk untuk mulai memantau',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lock, color: Color(0xFF2E5C9A)),
                          SizedBox(width: 8),
                          Text(
                            'Login Ibu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E5C9A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Ibu',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usiaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Usia Ibu (tahun)',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Usia wajib diisi';
                          }
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0 || n > 60) {
                            return 'Masukkan usia yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usiaKehamilanController,
                        decoration: const InputDecoration(
                          labelText: 'Usia Kehamilan (Minggu)',
                          hintText: 'Contoh: 12 minggu',
                          prefixIcon: Icon(Icons.pregnant_woman),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Usia kehamilan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _onSubmit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login),
                          label: Text(_loading ? 'Memproses...' : 'Masuk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
