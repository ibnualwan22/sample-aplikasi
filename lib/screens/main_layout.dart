import '../widgets/markaz_components.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quran_screen.dart';
import 'siakad_portal_screen.dart';
import 'calendar_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _authenticated = false;
  int _hasil = 0;
  int _selectedIndex = 0;
  final Set<int> _visited = {0};
  void _onItemTapped(int index) {
    setState(() {
      _visited.add(index);
      _selectedIndex = index;
    });
  }

  Widget _page(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
            santriLoggedIn: _authenticated,
            onOpenSiakad: () => _onItemTapped(2),
            onOpenCalendar: () => _onItemTapped(3),
            onOpenQuran: () => _onItemTapped(1),
            onOpenResults: () {
              _hasil++;
              _onItemTapped(2);
            });
      case 1:
        return const QuranScreen();
      case 2:
        return SiakadPortalScreen(
            resultRequest: _hasil,
            onAuth: (ok) {
              if (mounted) setState(() => _authenticated = ok);
            },
            isActive: _selectedIndex == 2,
            onExit: () => _onItemTapped(0));
      case 3:
        return const CalendarScreen();
      default:
        return Scaffold(
            appBar: AppBar(title: const Text('Setelan')),
            body: ListView(children: const [
              MarkazState(
                  title: 'Setelan sedang disiapkan',
                  message:
                      'Tema putih–emas mengikuti tampilan aplikasi. Pengaturan akun santri tersedia di menu Akun dalam SIAKAD.',
                  pose: MascotPose.unavailable),
            ]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        // Public launch must not initialize the portal or its login.
        children: List.generate(5,
            (i) => _visited.contains(i) ? _page(i) : const SizedBox.shrink()),
      ),
      bottomNavigationBar: _selectedIndex == 2 && _authenticated
          ? null
          : MarkazNavigation(
              index: _selectedIndex,
              onSelect: _onItemTapped,
              items: const [
                  (Icons.home_rounded, 'Beranda'),
                  (Icons.menu_book_rounded, 'Al-Qur’an'),
                  (Icons.school_rounded, 'SIAKAD'),
                  (Icons.calendar_month_rounded, 'Kalender'),
                  (Icons.settings_rounded, 'Setelan'),
                ]),
    );
  }
}
