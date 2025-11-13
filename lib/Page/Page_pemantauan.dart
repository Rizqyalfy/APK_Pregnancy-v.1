import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const SizedBox(width: 6),
                Text(
                  "MyPregnancyCare",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
              "Usia kehamilan Anda: 24 minggu",
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
            const SizedBox(height: 25),

            // Card Pemantauan
            _buildInfoCard(
              title: "Pemantauan Kondisi Kehamilan",
              icon: Icons.favorite,
              color: const Color(0xFF4A90E2),
              children: [
                _buildRow("Tekanan Darah", "110/80 mmHg"),
                _buildRow("Berat Badan", "62 kg"),
                _buildRow("Kadar Hb", "12 g/dL"),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoCard(
              title: "Perkembangan Janin",
              icon: Icons.child_care,
              color: const Color(0xFF81C784),
              children: [
                _buildRow("Berat Janin", "720 gram"),
                _buildRow("Kondisi", "Normal - Paru-paru mulai berkembang"),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoCard(
              title: "Indikator Risiko",
              icon: Icons.health_and_safety_rounded,
              color: const Color(0xFFFFB74D),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _ColorIndicator(color: Colors.green, label: "Normal"),
                    _ColorIndicator(color: Colors.yellow, label: "Waspada"),
                    _ColorIndicator(color: Colors.red, label: "Risiko"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E5C9A),
            ),
          ),
        ],
      ),
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
        CircleAvatar(radius: 10, backgroundColor: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
