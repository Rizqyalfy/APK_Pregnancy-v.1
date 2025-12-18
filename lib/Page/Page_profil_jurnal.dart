import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class ProfilJurnalPage extends StatefulWidget {
  const ProfilJurnalPage({super.key});

  @override
  State<ProfilJurnalPage> createState() => _ProfilJurnalPageState();
}

class _ProfilJurnalPageState extends State<ProfilJurnalPage> {
  Map<String, dynamic> _profil = {
    'nama': '-',
    'usia_ibu': '-',
    'usia_kehamilan': '-',
  };

  List<dynamic> _jurnal = [];
  bool _loadingProfil = false;
  bool _loadingJurnal = false;
  bool _savingJurnal = false;
  String? _errorProfil;
  String? _errorJurnal;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FA),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: const Text('Profil & Jurnal'),
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF2E5C9A),
              pinned: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF2E5C9A)),
                  tooltip: 'Kembali ke login',
                  onPressed: _goToLogin,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionTitle('Profil Ibu'),
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Jurnal Kehamilan'),
                  _buildJurnalList(),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: _savingJurnal ? null : _onAddJurnal,
                      icon: const Icon(Icons.add),
                      label: Text(_savingJurnal ? 'Menyimpan...' : 'Tambah Jurnal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E5C9A),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_loadingProfil) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorProfil != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gagal memuat profil', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorProfil!, style: const TextStyle(color: Colors.red)),
            TextButton.icon(
              onPressed: _fetchProfilFromApi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF4A90E2).withOpacity(0.15),
                child: const Icon(Icons.person, color: Color(0xFF2E5C9A)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_profil['nama'] ?? '-').toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E5C9A),
                    ),
                  ),
                  Text(
                    'Usia kehamilan: ${_profil['usia_kehamilan'] ?? '-'}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  Text(
                    'Usia ibu: ${_profil['usia_ibu'] ?? '-'} tahun',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJurnalList() {
    if (_loadingJurnal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorJurnal != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(_errorJurnal!, style: const TextStyle(color: Colors.red)),
            TextButton.icon(
              onPressed: _fetchJurnalFromApi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (_jurnal.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: const [
            Icon(Icons.book_outlined, color: Colors.grey, size: 32),
            SizedBox(height: 8),
            Text('Belum ada jurnal', style: TextStyle(color: Colors.black54)),
            SizedBox(height: 4),
            Text(
              'Catat perkembangan dan hasil kunjungan di sini.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _jurnal.map((item) => _buildJurnalCard(item)).toList(),
    );
  }

  Widget _buildJurnalCard(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (item['judul'] ?? '-').toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E5C9A),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    (item['tanggal'] ?? '-').toString(),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteJurnal(item),
                    tooltip: 'Hapus jurnal',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 8),
          Text(
            (item['catatan'] ?? '-').toString(),
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddJurnal() async {
    final judulController = TextEditingController();
    final tanggalController = TextEditingController();
    final catatanController = TextEditingController();

    DateTime? selectedDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Jurnal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: judulController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: tanggalController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 1),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        tanggalController.text = picked.toIso8601String().split('T').first;
                      }
                    },
                  ),
                ),
              ),
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(labelText: 'Catatan'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingJurnal
                      ? null
                      : () async {
                          final judul = judulController.text.trim();
                          final tanggal = tanggalController.text.trim();
                          final catatan = catatanController.text.trim();

                          if (judul.isEmpty || tanggal.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Judul dan tanggal wajib diisi.')),
                            );
                            return;
                          }

                          Navigator.of(ctx).pop();
                          await _submitAddJurnal(judul: judul, tanggal: tanggal, catatan: catatan);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_savingJurnal ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _goToLogin() async {
    // Hapus status login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }



  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchProfilFromApi(),
      _fetchJurnalFromApi(),
    ]);
  }

  Future<void> _fetchProfilFromApi() async {
    setState(() {
      _loadingProfil = true;
      _errorProfil = null;
    });

    final data = await ApiService.getProfilIbu();
    if (!mounted) return;

    setState(() {
      _loadingProfil = false;
      if (data.isEmpty) {
        _errorProfil = 'Profil kosong atau server tidak mengembalikan data.';
        return;
      }
      _profil = {
        'nama': data['nama'] ?? _profil['nama'] ?? '-',
        'usia_ibu': data['usia_ibu'] ?? data['usia'] ?? _profil['usia_ibu'] ?? '-',
        'usia_kehamilan': data['usia_kehamilan'] ?? _profil['usia_kehamilan'] ?? '-',
      };
    });
  }

  Future<void> _fetchJurnalFromApi() async {
    setState(() {
      _loadingJurnal = true;
      _errorJurnal = null;
    });

    final data = await ApiService.getJurnalIbu();
    if (!mounted) return;

    setState(() {
      _loadingJurnal = false;
      _jurnal = data;
      if (data.isEmpty) {
        _errorJurnal = null; // kosong bukan error
      }
    });
  }

  Future<void> _submitAddJurnal({required String judul, required String tanggal, String? catatan}) async {
    setState(() {
      _savingJurnal = true;
    });

    final res = await ApiService.addJurnalIbu(
      judul: judul,
      tanggal: tanggal,
      catatan: catatan,
    );

    if (!mounted) return;

    setState(() {
      _savingJurnal = false;
    });

    final status = res['status']?.toString().toLowerCase();
    if (status == 'success' || res.containsKey('id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal berhasil ditambahkan.')),
      );
      await _fetchJurnalFromApi();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambah jurnal: ${res['message'] ?? 'unknown error'}')),
      );
    }
  }

  Future<void> _confirmDeleteJurnal(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID jurnal tidak valid.')),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus jurnal?'),
          content: const Text('Data jurnal akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final res = await ApiService.deleteJurnalIbu(id);
    final status = res['status']?.toString().toLowerCase();

    if (status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal dihapus.')),
      );
      await _fetchJurnalFromApi();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus jurnal: ${res['message'] ?? 'unknown error'}')),
      );
    }
  }
}
