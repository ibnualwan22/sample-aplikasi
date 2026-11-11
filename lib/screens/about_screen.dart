import 'package:flutter/material.dart';

import '../theme/markaz_theme.dart';

/// Nomor versi aplikasi. Selaraskan dengan `version` di pubspec.yaml
/// setiap kali merilis versi baru.
const _appVersion = '1.0.7+10';

/// Anggota Aksara X KSU Batch 10, sesuai urutan yang diberikan.
/// Nama disalin apa adanya, termasuk gelar.
const _teamMembers = [
  "Evita Desi Safitri, S.F.U., S.H.",
  "Lidya Eka Saputri, S.Pd",
  "Arimbi Hayuning Putri Hariyadi",
  "Muh. Zubair Arafat S.Ag",
  "Syti Qoirunisa' Nurdiniyah, S.Pd",
  "Khoirul Soleh Harahap, L.C, S.S.I",
  "Ratu Adilah Ahadiyah",
  "Aisyah Nursalamah",
  "Najihul ulum Al Qur'an",
  "Qudsiyyatuz zahro",
  "Muhamad Fatih Akbar, S.Pd.",
  "Nisa Ulfatu Sholiha, S.Pd.",
  "Salsabila Dzawil Najwa, S.Ag.",
  "muhammad arshavin zakumi",
  "Muhammad Ikhsan, S.Pd.",
  "Adiyat Al Mufid",
  "Herbi Fatah Nurohmat",
  "Ahmad Ibnu Alwan, S.Ag.",
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/aksara-ksu-batch10.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Markaz Arabiyah Tech',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Versi $_appVersion',
                style: TextStyle(color: MarkazColors.muted)),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi ini dikembangkan oleh Aksara X KSU Batch 10.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Anggota',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (int i = 0; i < _teamMembers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: MarkazColors.gold,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            color: MarkazColors.surface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(_teamMembers[i],
                            style: const TextStyle(fontSize: 15)),
                      ),
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
