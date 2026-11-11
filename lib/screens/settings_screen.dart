import 'package:flutter/material.dart';

import '../theme/markaz_theme.dart';
import 'about_screen.dart';
import 'references_screen.dart';

/// Halaman Setelan: menu Referensi dan Tentang Aplikasi.
///
/// Pengaturan akun santri tetap berada di menu Akun dalam SIAKAD,
/// sesuai catatan pada placeholder sebelumnya.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Setelan')),
      body: ListView(
        children: [
          _menuTile(
            icon: Icons.menu_book_rounded,
            title: 'Referensi',
            subtitle:
                "Sumber data waktu salat, Al-Qur'an, tafsir, dan arah kiblat",
            onTap: () => open(const ReferencesScreen()),
          ),
          _menuTile(
            icon: Icons.info_rounded,
            title: 'Tentang Aplikasi',
            subtitle: 'Pengembang aplikasi dan versi',
            onTap: () => open(const AboutScreen()),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Pengaturan akun santri tersedia di menu Akun dalam SIAKAD.',
              style: TextStyle(color: MarkazColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MarkazColors.tint,
          child: Icon(icon, color: MarkazColors.ink),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
