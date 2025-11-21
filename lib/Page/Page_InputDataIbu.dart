import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
// HAPUS: import 'package:image_picker_web/image_picker_web.dart'; // Untuk web
import '../services/data_repository.dart';

class InputDataIbuPage extends StatefulWidget {
  const InputDataIbuPage({super.key});

  @override
  State<InputDataIbuPage> createState() => _InputDataIbuPageState();
}

class _InputDataIbuPageState extends State<InputDataIbuPage> {
  final _formKey = GlobalKey<FormState>();
  final DataRepository _dataRepository = DataRepository();

  final tekananDarahController = TextEditingController();
  final beratBadanController = TextEditingController();
  final keluhanController = TextEditingController();
  final pergerakanJaninController = TextEditingController();
  final hasilLabController = TextEditingController();
  final hasilUSGController = TextEditingController();
  final catatanANCController = TextEditingController();

  // Controller untuk edit jadwal
  final mingguController = TextEditingController();
  final judulJadwalController = TextEditingController();
  final tanggalJadwalController = TextEditingController();
  final catatanJadwalController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedKunjungan = 'Kunjungan Rutin';
  String _selectedImunisasiTT = 'Belum';
  String _selectedTrimester = 'Trimester I';

  // Variabel untuk gambar (support web dan mobile)
  File? _fotoUSG;
  Uint8List? _webFotoUSG;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Variabel untuk mode edit jadwal
  int? _editingJadwalIndex;
  bool _isEditingJadwal = false;

  @override
  void initState() {
    super.initState();
    _dataRepository.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _dataRepository.removeListener(_onDataChanged);
    tekananDarahController.dispose();
    beratBadanController.dispose();
    keluhanController.dispose();
    pergerakanJaninController.dispose();
    hasilLabController.dispose();
    hasilUSGController.dispose();
    catatanANCController.dispose();
    mingguController.dispose();
    judulJadwalController.dispose();
    tanggalJadwalController.dispose();
    catatanJadwalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jadwalANC = _dataRepository.jadwalANC;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Data Ibu & Kelola Jadwal ANC"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),

              // SECTION KELOLA JADWAL ANC
              _buildKelolaJadwalSection(jadwalANC),
              const SizedBox(height: 20),

              _buildDateSection(),
              const SizedBox(height: 20),
              _buildDataHarianSection(),
              const SizedBox(height: 20),
              _buildANCSection(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveData,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Simpan Data Pemeriksaan",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION KELOLA JADWAL ANC
  Widget _buildKelolaJadwalSection(List<Map<String, String>> jadwalANC) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  "Kelola Jadwal ANC",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // FORM TAMBAH/EDIT JADWAL
            _buildJadwalForm(),
            const SizedBox(height: 16),

            // LIST JADWAL YANG SUDAH ADA
            _buildJadwalList(jadwalANC),
          ],
        ),
      ),
    );
  }

  // FORM UNTUK TAMBAH/EDIT JADWAL
  Widget _buildJadwalForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            _isEditingJadwal ? 'Edit Jadwal ANC' : 'Tambah Jadwal ANC Baru',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),

          _buildJadwalTextField(
            'Minggu Ke-',
            mingguController,
            Icons.numbers,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildJadwalTextField(
            'Judul Kunjungan',
            judulJadwalController,
            Icons.title,
          ),
          const SizedBox(height: 12),
          _buildJadwalTextField(
            'Tanggal (YYYY-MM-DD)',
            tanggalJadwalController,
            Icons.calendar_today,
            hintText: 'Contoh: 2024-12-31',
          ),
          const SizedBox(height: 12),
          _buildJadwalTextField(
            'Catatan',
            catatanJadwalController,
            Icons.note,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveJadwal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditingJadwal
                        ? Colors.orange
                        : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _isEditingJadwal ? 'Update Jadwal' : 'Tambah Jadwal',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              if (_isEditingJadwal) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _cancelEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String hintText = "",
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // LIST JADWAL ANC
  Widget _buildJadwalList(List<Map<String, String>> jadwalANC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Jadwal ANC Saat Ini:",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...jadwalANC.asMap().entries.map((entry) {
          final index = entry.key;
          final jadwal = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.blue),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.orange,
                      size: 20,
                    ),
                    onPressed: () => _editJadwal(index, jadwal),
                    tooltip: 'Edit Jadwal',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _hapusJadwal(index),
                    tooltip: 'Hapus Jadwal',
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _editJadwal(int index, Map<String, String> jadwal) {
    setState(() {
      _editingJadwalIndex = index;
      _isEditingJadwal = true;
      mingguController.text = jadwal['minggu'] ?? '';
      judulJadwalController.text = jadwal['judul'] ?? '';
      tanggalJadwalController.text = jadwal['tanggal'] ?? '';
      catatanJadwalController.text = jadwal['catatan'] ?? '';
    });
  }

  void _hapusJadwal(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _dataRepository.hapusJadwalANC(index);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jadwal berhasil dihapus!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveJadwal() {
    if (mingguController.text.isEmpty || judulJadwalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minggu dan judul wajib diisi!')),
      );
      return;
    }

    Map<String, String> jadwalBaru = {
      'minggu': mingguController.text,
      'judul': judulJadwalController.text,
      'tanggal': tanggalJadwalController.text,
      'catatan': catatanJadwalController.text,
    };

    if (_isEditingJadwal && _editingJadwalIndex != null) {
      _dataRepository.editJadwalANC(_editingJadwalIndex!, jadwalBaru);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil diupdate!')),
      );
    } else {
      _dataRepository.tambahJadwalANC(jadwalBaru);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil ditambahkan!')),
      );
    }

    _resetJadwalForm();
  }

  void _cancelEdit() {
    _resetJadwalForm();
  }

  void _resetJadwalForm() {
    setState(() {
      _isEditingJadwal = false;
      _editingJadwalIndex = null;
      mingguController.clear();
      judulJadwalController.clear();
      tanggalJadwalController.clear();
      catatanJadwalController.clear();
    });
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Lengkapi data kesehatan Anda dan kelola jadwal ANC',
            style: TextStyle(color: Colors.blueGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Pemeriksaan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildDataHarianSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  "Data Harian/Mingguan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _inputField(
              "Tekanan Darah (mmHg)",
              tekananDarahController,
              Icons.favorite,
              isRequired: true,
              hintText: "Contoh: 120/80",
            ),
            _inputField(
              "Berat Badan (kg)",
              beratBadanController,
              Icons.monitor_weight,
              isRequired: true,
              keyboardType: TextInputType.number,
            ),
            _inputField(
              "Keluhan",
              keluhanController,
              Icons.health_and_safety,
              maxLines: 3,
              hintText: "Tuliskan keluhan yang dirasakan",
            ),
            _inputField(
              "Pergerakan Janin",
              pergerakanJaninController,
              Icons.child_care,
              maxLines: 2,
              hintText: "Deskripsi pergerakan janin",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildANCSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  "Catatan Pemeriksaan ANC",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownField("Jenis Kunjungan", _selectedKunjungan, [
              'Kunjungan Rutin',
              'Kunjungan Darurat',
              'Kontrol Hasil Lab',
              'USG',
            ], Icons.assignment),
            const SizedBox(height: 12),
            _buildDropdownField("Trimester", _selectedTrimester, [
              'Trimester I',
              'Trimester II',
              'Trimester III',
            ], Icons.timeline),
            const SizedBox(height: 12),
            _inputField(
              "Hasil Lab",
              hasilLabController,
              Icons.science,
              maxLines: 2,
              hintText: "Hasil pemeriksaan laboratorium",
            ),
            const SizedBox(height: 12),
            _buildUSGSection(),
            const SizedBox(height: 12),
            _buildDropdownField("Imunisasi TT", _selectedImunisasiTT, [
              'Belum',
              'TT1',
              'TT2',
              'TT3',
              'TT4',
              'TT5',
              'Lengkap',
            ], Icons.vaccines),
            const SizedBox(height: 12),
            _inputField(
              "Catatan Tambahan ANC",
              catatanANCController,
              Icons.note_add,
              maxLines: 4,
              hintText: "Catatan lain dari dokter/bidan",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUSGSection() {
    bool hasImage = kIsWeb ? _webFotoUSG != null : _fotoUSG != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hasil USG",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: hasilUSGController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Deskripsi hasil USG",
            prefixIcon: const Icon(Icons.description, color: Colors.blueAccent),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Foto USG",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: !hasImage
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_camera,
                      size: 50,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb ? "Upload foto USG" : "Belum ada foto USG",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _uploadFoto,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Upload Foto USG"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.memory(
                              _webFotoUSG!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _fotoUSG!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 16,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() {
                            if (kIsWeb) {
                              _webFotoUSG = null;
                            } else {
                              _fotoUSG = null;
                            }
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploadFoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Ganti Foto"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // PERBAIKAN: Hapus penggunaan ImagePickerWeb
  Future<void> _uploadFoto() async {
    if (kIsWeb) {
      // Untuk web, gunakan image_picker biasa atau nonaktifkan fitur upload
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur upload gambar untuk web sedang tidak tersedia'),
        ),
      );
    } else {
      // Untuk mobile, gunakan image_picker biasa
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _fotoUSG = File(image.path));
      }
    }
  }

  Widget _inputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String hintText = "",
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isRequired)
                const Text(" *", style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, color: Colors.blueAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty))
                return '$label wajib diisi';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(icon, color: Colors.blueAccent),
            title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map(
                      (String item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      if (label == "Jenis Kunjungan")
                        _selectedKunjungan = newValue;
                      else if (label == "Imunisasi TT")
                        _selectedImunisasiTT = newValue;
                      else if (label == "Trimester")
                        _selectedTrimester = newValue;
                    }
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate)
      setState(() => _selectedDate = picked);
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _simpanDataKeRepository();
        setState(() => _isLoading = false);
        _showSuccessDialog();
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> _simpanDataKeRepository() async {
    String formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    _dataRepository.updateDataIbu({
      'tekananDarah': tekananDarahController.text.isNotEmpty
          ? tekananDarahController.text
          : '110/80 mmHg',
      'beratBadan': beratBadanController.text.isNotEmpty
          ? '${beratBadanController.text} kg'
          : '62 kg',
      'usiaKehamilan': _getUsiaKehamilanFromTrimester(),
      'kadarHb': '12 g/dL',
      'perkembanganJanin': _getPerkembanganJanin(),
    });

    String hasilPemeriksaan = _buildHasilPemeriksaan();

    _dataRepository.tambahRiwayatKunjungan({
      'tanggal': formattedDate,
      'hasil': hasilPemeriksaan,
    });

    await Future.delayed(const Duration(seconds: 1));
  }

  String _getUsiaKehamilanFromTrimester() {
    switch (_selectedTrimester) {
      case 'Trimester I':
        return '12 minggu (Trimester I)';
      case 'Trimester II':
        return '24 minggu (Trimester II)';
      case 'Trimester III':
        return '36 minggu (Trimester III)';
      default:
        return '24 minggu (Trimester II)';
    }
  }

  String _getPerkembanganJanin() {
    if (hasilUSGController.text.isNotEmpty) {
      return hasilUSGController.text;
    }

    switch (_selectedTrimester) {
      case 'Trimester I':
        return 'Normal • Organ mulai terbentuk';
      case 'Trimester II':
        return 'Normal • Paru-paru mulai berkembang';
      case 'Trimester III':
        return 'Normal • Janin sudah cukup bulan';
      default:
        return 'Normal • Perkembangan sesuai usia kehamilan';
    }
  }

  String _buildHasilPemeriksaan() {
    List<String> hasil = [];

    if (tekananDarahController.text.isNotEmpty) {
      hasil.add('TD: ${tekananDarahController.text}');
    }

    if (beratBadanController.text.isNotEmpty) {
      hasil.add('BB: ${beratBadanController.text} kg');
    }

    if (keluhanController.text.isNotEmpty) {
      hasil.add('Keluhan: ${keluhanController.text}');
    }

    if (pergerakanJaninController.text.isNotEmpty) {
      hasil.add('Pergerakan: ${pergerakanJaninController.text}');
    }

    if (hasilLabController.text.isNotEmpty) {
      hasil.add('Lab: ${hasilLabController.text}');
    }

    if (hasilUSGController.text.isNotEmpty) {
      hasil.add('USG: ${hasilUSGController.text}');
    }

    if (catatanANCController.text.isNotEmpty) {
      hasil.add('Catatan: ${catatanANCController.text}');
    }

    hasil.add('Imunisasi TT: $_selectedImunisasiTT');
    hasil.add('Trimester: $_selectedTrimester');
    hasil.add('Jenis: $_selectedKunjungan');

    return hasil.join(' • ');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Berhasil"),
        content: const Text(
          "Data berhasil disimpan dan sudah terupdate di dashboard.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
