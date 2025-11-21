import 'package:flutter/material.dart';
import 'Page/Page_pemantauan.dart';
import 'Page/Page_jadwal.dart';
import 'Page/Page_edukasi.dart';
// import 'Page/Page_profil_jurnal.dart';

void main() {
  runApp(const MyPregnancyCareApp());
}

class MyPregnancyCareApp extends StatelessWidget {
  const MyPregnancyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPregnancyCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEAF3FA),
        primaryColor: const Color(0xFF4A90E2),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF4A90E2),
          secondary: const Color(0xFFB3E5FC),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF2E5C9A)),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(), // Ganti DashboardPage() dengan PemantauanPage()
    const CatatanPage(),
    const EdukasiPage(),
    // const ProfilJurnalPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: const Color(0xFFA0A0A0),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pregnant_woman),
            label: 'Pemantauan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Jadwal ANC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Edukasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profil & Jurnal',
          ),
        ],
      ),
    );
  }
}
