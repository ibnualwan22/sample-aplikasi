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
        return HomeScreen(onOpenSiakad: () {
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
        return const Center(
            child:
                Text('Pengaturan', style: TextStyle(color: Color(0xFFD4AF37))));
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
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book_outlined),
                    activeIcon: Icon(Icons.menu_book),
                    label: "Al-Qur'an"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.school_outlined, size: 30),
                    activeIcon: Icon(Icons.school, size: 30),
                    label: 'SIAKAD',
                    tooltip: 'SIAKAD Markaz Arabiyah'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today),
                    label: 'Kalender'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: 'Setting'),
              ],
            ),
    );
  }
}
