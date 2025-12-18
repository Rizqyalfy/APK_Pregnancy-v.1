import 'package:flutter/material.dart';

class EdukasiPage extends StatefulWidget {
  const EdukasiPage({super.key});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage> {
  String selectedTrimester = "Trimester I (0–12 minggu)";

  final List<Map<String, String>> dataEdukasi = [
    {
      "trimester": "Trimester I (0–12 minggu)",
      "fokus": "Adaptasi tubuh & nutrisi awal",
      "materi":
          "- Mual muntah, kelelahan\n- Pola makan sehat\n- Pentingnya asam folat",
      "color": "0xFFD6EAF8",
    },
    {
      "trimester": "Trimester II (13–28 minggu)",
      "fokus": "Pertumbuhan janin & kesejahteraan ibu",
      "materi":
          "- Senam hamil\n- Tanda bahaya kehamilan\n- Kesehatan gigi & mulut",
      "color": "0xFFB3E5FC",
    },
    {
      "trimester": "Trimester III (29–40 minggu)",
      "fokus": "Persiapan persalinan & menyusui",
      "materi":
          "- Tanda persalinan\n- Perawatan payudara\n- Persiapan mental ibu",
      "color": "0xFFFFF8E1",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedData = dataEdukasi.firstWhere(
      (e) => e["trimester"] == selectedTrimester,
      orElse: () => dataEdukasi[0],
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ============================
            // JUDUL
            // ============================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: Colors.blue[600],
                  size: 26,
                ),
                const SizedBox(width: 6),
                Text(
                  "Edukasi Berdasarkan Trimester",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ============================
            // Dropdown Trimester
            // ============================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedTrimester,
                  dropdownColor: Colors.blue[50],
                  isExpanded: true,
                  items: dataEdukasi.map((e) {
                    return DropdownMenuItem<String>(
                      value: e["trimester"],
                      child: Text(
                        e["trimester"]!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedTrimester = value!);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ============================
            // TABEL EDUKASI
            // ============================
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(int.parse(selectedData["color"]!)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade700, // BORDER TEBAL
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Table(
                border: TableBorder.all(
                  color: Colors.blueGrey.shade300,
                  width: 1.3,
                  borderRadius: BorderRadius.circular(6),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(3),
                },
                children: [
                  // HEADER TABEL
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue[100]),
                    children: [
                      _tableHeader("Trimester"),
                      _tableHeader("Fokus Edukasi"),
                      _tableHeader("Contoh Materi"),
                    ],
                  ),

                  // ISI TABEL
                  TableRow(
                    decoration: const BoxDecoration(color: Colors.white),
                    children: [
                      _tableCell(selectedData["trimester"]!),
                      _tableCell(selectedData["fokus"]!),
                      _tableCell(selectedData["materi"]!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // WIDGET HEADER TABLE
  // ============================
  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  // ============================
  // WIDGET CELL TABLE
  // ============================
  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2E5C9A),
          height: 1.4,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
