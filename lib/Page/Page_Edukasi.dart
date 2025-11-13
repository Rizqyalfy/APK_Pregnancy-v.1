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
      "color": "0xFFD6EAF8", // biru muda
    },
    {
      "trimester": "Trimester II (13–28 minggu)",
      "fokus": "Pertumbuhan janin & kesejahteraan ibu",
      "materi":
          "- Senam hamil\n- Tanda bahaya kehamilan\n- Kesehatan gigi & mulut",
      "color": "0xFFB3E5FC", // biru langit lembut
    },
    {
      "trimester": "Trimester III (29–40 minggu)",
      "fokus": "Persiapan persalinan & menyusui",
      "materi":
          "- Tanda persalinan\n- Perawatan payudara\n- Persiapan mental ibu",
      "color": "0xFFFFF8E1", // krem lembut
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Judul
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: Colors.blue[600],
                  size: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  "Edukasi Berdasarkan Trimester",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Dropdown Pilihan Trimester
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade200, width: 2),
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
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedTrimester = newValue!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Box Tabel Edukasi
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(int.parse(selectedData["color"]!)),
                borderRadius: BorderRadius.circular(16),
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
                  color: Colors.blueGrey.shade200,
                  width: 1.2,
                  borderRadius: BorderRadius.circular(8),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(3),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue[100]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            "Trimester",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            "Fokus Edukasi",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            "Contoh Materi",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Isi
                  TableRow(
                    decoration: const BoxDecoration(color: Colors.white),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          selectedData["trimester"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E5C9A),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          selectedData["fokus"]!,
                          style: const TextStyle(
                            color: Color(0xFF2E5C9A),
                            height: 1.4,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          selectedData["materi"]!,
                          style: const TextStyle(
                            color: Color(0xFF2E5C9A),
                            height: 1.4,
                          ),
                        ),
                      ),
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
}
