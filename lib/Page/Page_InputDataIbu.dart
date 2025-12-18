import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class InputDataIbuPage extends StatefulWidget {
  const InputDataIbuPage({super.key});

  @override
  State<InputDataIbuPage> createState() => _InputDataIbuPageState();
}

class _InputDataIbuPageState extends State<InputDataIbuPage> {
  final _formKey = GlobalKey<FormState>();
  // Local cache for jadwal ANC fetched from server
  List<Map<String, String>> _jadwalANC = [];

  final tekananDarahController = TextEditingController();
  final beratBadanController = TextEditingController();
  final tinggiFundusController = TextEditingController();
  final keluhanController = TextEditingController();
  final pergerakanJaninController = TextEditingController();
  final hasilLabController = TextEditingController();
  final hasilUSGController = TextEditingController();
  final catatanANCController = TextEditingController();

  // Controller untuk edit jadwal
  final mingguController = TextEditingController();
  final judulJadwalController = TextEditingController();
  final tanggalJadwalController = TextEditingController();
  final jamJadwalController = TextEditingController();
  final catatanJadwalController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedJadwalTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedKunjungan = 'Kunjungan Rutin';
  String _selectedImunisasiTT = 'Belum';
  String _selectedTrimester = 'Trimester I';

  // Variabel untuk gambar (support web dan mobile)
  File? _fotoUSG;
  Uint8List? _webFotoUSG;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  // Variabel untuk mode edit jadwal
  int? _editingJadwalIndex;
  bool _isEditingJadwal = false;

  @override
  void initState() {
    super.initState();
    _loadJadwalFromServer();
  }

  @override
  void dispose() {
    // nothing to remove
    tekananDarahController.dispose();
    beratBadanController.dispose();
    tinggiFundusController.dispose();
    keluhanController.dispose();
    pergerakanJaninController.dispose();
    hasilLabController.dispose();
    hasilUSGController.dispose();
    catatanANCController.dispose();
    mingguController.dispose();
    judulJadwalController.dispose();
    tanggalJadwalController.dispose();
    jamJadwalController.dispose();
    catatanJadwalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jadwalANC = _jadwalANC; // gunakan data dari server

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Input Data Ibu Hamil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.grey[50],
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD INFORMASI
                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  // CARD KELOLA JADWAL ANC
                  _buildKelolaJadwalSection(jadwalANC),
                  const SizedBox(height: 20),

                  // CARD TANGGAL PEMERIKSAAN
                  _buildSectionCard(
                    title: 'Tanggal Pemeriksaan',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    children: [_buildDatePickerField()],
                  ),
                  const SizedBox(height: 20),

                  // CARD DATA HARIAN
                  _buildDataHarianSection(),
                  const SizedBox(height: 20),

                  // CARD PEMERIKSAAN ANC
                  _buildANCSection(),
                  const SizedBox(height: 20),

                  // CARD FOTO USG
                  _buildUSGSection(),
                  const SizedBox(height: 30),

                  // TOMBOL AKSI
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            'BATAL',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
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
                                  'SIMPAN DATA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =======================================================
  // WIDGET BUILDING METHODS
  // =======================================================

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Informasi Input Data',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lengkapi data kesehatan Anda dan kelola jadwal ANC. Data yang disimpan akan digunakan untuk memantau perkembangan kehamilan.',
            style: TextStyle(color: Colors.blue[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildKelolaJadwalSection(List<Map<String, String>> jadwalANC) {
    return _buildSectionCard(
      title: 'Kelola Jadwal ANC',
      icon: Icons.calendar_today,
      color: Colors.purple,
      children: [
        // FORM TAMBAH/EDIT JADWAL
        _buildJadwalForm(),
        const SizedBox(height: 16),

        // LIST JADWAL YANG SUDAH ADA
        _buildJadwalList(jadwalANC),
      ],
    );
  }

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
              color: Colors.purple,
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
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedJadwalTime,
                helpText: 'Pilih Jam Jadwal',
                cancelText: 'Batal',
                confirmText: 'OK',
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedJadwalTime = picked;
                  jamJadwalController.text =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.purple[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      jamJadwalController.text.isEmpty
                          ? 'Jam'
                          : jamJadwalController.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: jamJadwalController.text.isEmpty
                            ? Colors.grey[600]
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildJadwalList(List<Map<String, String>> jadwalANC) {
    if (jadwalANC.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              "Belum ada jadwal ANC",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Tambahkan jadwal ANC pertama Anda",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Jadwal ANC Saat Ini:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              "Total: ${jadwalANC.length} jadwal",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...jadwalANC.asMap().entries.map((entry) {
          final index = entry.key;
          final jadwal = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 1,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    jadwal['minggu']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
              title: Text(
                jadwal['judul']!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minggu ke-${jadwal['minggu']}'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(jadwal['tanggal']!),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            jadwal['jam'] ?? '',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (jadwal['catatan']!.isNotEmpty)
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

  Widget _buildDatePickerField() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Tanggal Pemeriksaan',
        hintText: 'Pilih tanggal',
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onTap: _selectDate,
      controller: TextEditingController(
        text:
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      ),
    );
  }

  Widget _buildDataHarianSection() {
    return _buildSectionCard(
      title: 'Data Harian/Mingguan',
      icon: Icons.monitor_heart,
      color: Colors.green,
      children: [
        _buildTextField(
          controller: tekananDarahController,
          label: 'Tekanan Darah (mmHg)',
          hint: 'Contoh: 120/80',
          icon: Icons.favorite,
          isRequired: true,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: beratBadanController,
          label: 'Berat Badan (kg)',
          hint: 'Contoh: 55.5',
          icon: Icons.monitor_weight,
          keyboardType: TextInputType.number,
          isRequired: true,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: tinggiFundusController,
          label: 'Tinggi Fundus (cm)',
          hint: 'Contoh: 25',
          icon: Icons.straighten,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: keluhanController,
          label: 'Keluhan',
          hint: 'Tuliskan keluhan yang dirasakan',
          icon: Icons.health_and_safety,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: pergerakanJaninController,
          label: 'Pergerakan Janin',
          hint: 'Deskripsi pergerakan janin',
          icon: Icons.child_care,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildANCSection() {
    return _buildSectionCard(
      title: 'Catatan Pemeriksaan ANC',
      icon: Icons.medical_services,
      color: Colors.orange,
      children: [
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
        _buildTextField(
          controller: hasilLabController,
          label: 'Hasil Lab',
          hint: 'Hasil pemeriksaan laboratorium',
          icon: Icons.science,
          maxLines: 2,
        ),
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
        _buildTextField(
          controller: catatanANCController,
          label: 'Catatan Tambahan ANC',
          hint: 'Catatan lain dari dokter/bidan',
          icon: Icons.note_add,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildUSGSection() {
    bool hasImage = kIsWeb ? _webFotoUSG != null : _fotoUSG != null;

    return _buildSectionCard(
      title: 'Hasil USG',
      icon: Icons.photo_camera,
      color: Colors.red,
      children: [
        _buildTextField(
          controller: hasilUSGController,
          label: 'Deskripsi Hasil USG',
          hint: 'Deskripsi hasil USG',
          icon: Icons.description,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const Text(
          "Foto USG",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // Progress Bar untuk Upload Gambar
        if (_isUploadingImage) ...[
          Column(
            children: [
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                'Mengupload gambar... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],

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
                      onPressed: _isUploadingImage ? null : _uploadFoto,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Upload Foto USG"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
                          onPressed: _isUploadingImage
                              ? null
                              : () => setState(() {
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
              onPressed: _isUploadingImage ? null : _uploadFoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Ganti Foto"),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label harus diisi';
            }
            return null;
          },
        ),
      ],
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: ListTile(
            leading: Icon(icon, color: Colors.blue),
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

  // =======================================================
  // METHODS UNTUK JADWAL ANC
  // =======================================================

  Future<void> _loadJadwalFromServer() async {
    try {
      setState(() => _isLoading = true);
      final resp = await ApiService.getJadwalANC();
      // Ensure we have List<Map<String, String>>
      final List<Map<String, String>> list = [];
      for (var item in resp) {
        try {
          list.add({
            'id': item['id']?.toString() ?? '',
            'minggu': item['minggu']?.toString() ?? '',
            'judul': item['judul']?.toString() ?? '',
            'tanggal': item['tanggal']?.toString() ?? '',
            'jam': item['jam']?.toString() ?? '',
            'catatan': item['catatan']?.toString() ?? '',
          });
        } catch (_) {
          // skip invalid
        }
      }
      if (mounted)
        setState(() {
          _jadwalANC = list;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('Error load jadwal: $e');
    }
  }

  void _editJadwal(int index, Map<String, String> jadwal) {
    setState(() {
      _editingJadwalIndex = index;
      _isEditingJadwal = true;
      mingguController.text = jadwal['minggu'] ?? '';
      judulJadwalController.text = jadwal['judul'] ?? '';
      tanggalJadwalController.text = jadwal['tanggal'] ?? '';

      // Set jam
      final jamStr = jadwal['jam'] ?? '';
      jamJadwalController.text = jamStr;
      final jamParts = jamStr.split(':');
      if (jamParts.length == 2) {
        final hour = int.tryParse(jamParts[0]) ?? 9;
        final minute = int.tryParse(jamParts[1]) ?? 0;
        _selectedJadwalTime = TimeOfDay(hour: hour, minute: minute);
      }

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
            onPressed: () async {
              Navigator.pop(context);
              try {
                final jadwal = _jadwalANC[index];
                final idStr = jadwal['id'] ?? '';
                if (idStr.isNotEmpty) {
                  final id = int.tryParse(idStr) ?? 0;
                  final success = await ApiService.deleteJadwalANC(id);
                  if (!success) throw Exception('Gagal menghapus di server');
                }
                // remove locally
                if (mounted) {
                  setState(() => _jadwalANC.removeAt(index));
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jadwal berhasil dihapus!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveJadwal() async {
    if (mingguController.text.isEmpty || judulJadwalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minggu dan judul wajib diisi!')),
      );
      return;
    }
    final jadwalBaru = {
      'minggu': mingguController.text,
      'judul': judulJadwalController.text,
      'tanggal': tanggalJadwalController.text,
      'jam': jamJadwalController.text.isEmpty
          ? '09:00'
          : jamJadwalController.text,
      'catatan': catatanJadwalController.text,
    };

    try {
      setState(() => _isLoading = true);

      if (_isEditingJadwal && _editingJadwalIndex != null) {
        final existing = _jadwalANC[_editingJadwalIndex!];
        final idStr = existing['id'] ?? '';
        if (idStr.isNotEmpty) {
          final id = int.tryParse(idStr) ?? 0;
          final resp = await ApiService.updateJadwalANC(
            id: id,
            minggu: jadwalBaru['minggu'] ?? '',
            judul: jadwalBaru['judul'] ?? '',
            tanggal: jadwalBaru['tanggal'] ?? '',
            jam: jadwalBaru['jam'] ?? '09:00',
            catatan: jadwalBaru['catatan'] ?? '',
          );
          if ((resp['status']?.toString().toLowerCase() ?? '') != 'success' &&
              resp['status'] != true) {
            throw Exception(resp['message'] ?? 'Gagal update jadwal');
          }
        } else {
          await ApiService.insertJadwalANC(
            minggu: jadwalBaru['minggu'] ?? '',
            judul: jadwalBaru['judul'] ?? '',
            tanggal: jadwalBaru['tanggal'] ?? '',
            jam: jadwalBaru['jam'] ?? '09:00',
            catatan: jadwalBaru['catatan'] ?? '',
          );
        }
        await _loadJadwalFromServer();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil diupdate!')),
          );
      } else {
        final resp = await ApiService.insertJadwalANC(
          minggu: jadwalBaru['minggu'] ?? '',
          judul: jadwalBaru['judul'] ?? '',
          jam: jadwalBaru['jam'] ?? '09:00',
          tanggal: jadwalBaru['tanggal'] ?? '',
          catatan: jadwalBaru['catatan'] ?? '',
        );
        if ((resp['status']?.toString().toLowerCase() ?? '') == 'success' ||
            resp['status'] == true) {
          await _loadJadwalFromServer();
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Jadwal berhasil ditambahkan!')),
            );
        } else {
          throw Exception(resp['message'] ?? 'Gagal menambah jadwal');
        }
      }

      _resetJadwalForm();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      jamJadwalController.clear();
      catatanJadwalController.clear();
      _selectedJadwalTime = const TimeOfDay(hour: 9, minute: 0);
    });
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    tekananDarahController.clear();
    beratBadanController.clear();
    tinggiFundusController.clear();
    keluhanController.clear();
    pergerakanJaninController.clear();
    hasilLabController.clear();
    hasilUSGController.clear();
    catatanANCController.clear();
    _selectedDate = DateTime.now();
    _selectedKunjungan = 'Kunjungan Rutin';
    _selectedImunisasiTT = 'Belum';
    _selectedTrimester = 'Trimester I';
    if (kIsWeb) {
      _webFotoUSG = null;
    } else {
      _fotoUSG = null;
    }
    _resetJadwalForm();
  }

  Future<void> _uploadFoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur upload gambar untuk web sedang tidak tersedia'),
        ),
      );
    } else {
      // Request storage/photos permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        // Android 13+ uses different permission
        if (await _isAndroid13OrHigher()) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } else {
        // iOS
        status = await Permission.photos.request();
      }

      if (status.isDenied || status.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Izin akses galeri diperlukan untuk upload foto',
            ),
            action: SnackBarAction(
              label: 'Pengaturan',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin akses galeri ditolak')),
        );
        return;
      }

      setState(() {
        _isUploadingImage = true;
        _uploadProgress = 0.0;
      });

      // Simulasi proses upload dengan progress
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _uploadProgress = i / 10;
        });
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 0.0;
      });

      if (image != null) {
        setState(() => _fotoUSG = File(image.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto USG berhasil diupload!')),
        );
      }
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      // Check Android version (API 33 = Android 13)
      return true; // Simplified check, use actual version check in production
    }
    return false;
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
    // Format date as YYYY-MM-DD for API
    final tanggalPemeriksaan =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final tekanan = tekananDarahController.text.trim();
    final berat = beratBadanController.text.trim();
    final tinggiFundus = tinggiFundusController.text.trim();
    final keluhan = keluhanController.text.trim();
    final pergerakan = pergerakanJaninController.text.trim();
    final hasilLab = hasilLabController.text.trim();
    final hasilUSG = hasilUSGController.text.trim();
    final catatan = catatanANCController.text.trim();

    // Ambil path foto USG jika ada
    String? fotoPath;
    if (!kIsWeb && _fotoUSG != null) {
      fotoPath = _fotoUSG!.path;
    }

    final resp = await ApiService.insertDataIbu(
      tekananDarah: tekanan,
      beratBadan: berat,
      keluhan: keluhan,
      pergerakanJanin: pergerakan,
      tanggalPemeriksaan: tanggalPemeriksaan,
      jenisKunjungan: _selectedKunjungan,
      trimester: _selectedTrimester,
      hasilLab: hasilLab,
      hasilUSG: hasilUSG,
      imunisasiTT: _selectedImunisasiTT,
      catatanANC: catatan,
      // optional fields
      tinggiFundus: tinggiFundus.isNotEmpty ? tinggiFundus : null,
      kadarHb: null,
      fotoUSGPath: fotoPath, // Kirim path foto USG
    );

    if ((resp['status']?.toString().toLowerCase() ?? '') != 'success' &&
        resp['status'] != true) {
      throw Exception(resp['message'] ?? 'Gagal menyimpan data ke server');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil'),
          ],
        ),
        content: const Text('Data kunjungan berhasil disimpan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
