import 'package:flutter/material.dart';

import '../theme/markaz_theme.dart';

/// Sumber data fitur-fitur utama aplikasi, sesuai pustaka dan API yang
/// dipakai kode aplikasi.
class ReferencesScreen extends StatelessWidget {
  const ReferencesScreen({super.key});

  static const _items = [
    (
      title: 'Waktu Salat',
      body:
          'Jadwal salat harian berdasarkan kota. Kota dicari berdasarkan nama; lokasi bawaan Tulungrejo, Pare.',
      source: 'MyQuran API · api.myquran.com',
    ),
    (
      title: "Al-Qur'an",
      body:
          'Teks ayat dan terjemahan Indonesia per surah. Indeks pencarian ayat dibundel di dalam aplikasi (assets/quran_index.json).',
      source: 'EQuran.id · equran.id',
    ),
    (
      title: 'Tafsir',
      body:
          'Tafsir Kemenag berbahasa Indonesia (via EQuran.id) dan tujuh kitab tafsir berbahasa Arab: Ibn Kathir, Al-Thabari, Muyassar, Al-Qurthubi, Al-Sa\u2019di, Al-Wasith, dan Al-Baghawi.',
      source: 'EQuran.id · Quran.com API · api.quran.com',
    ),
    (
      title: 'Arah Kiblat',
      body:
          "Arah dihitung dari posisi GPS perangkat menuju Ka'bah di Makkah dan ditampilkan lewat kompas perangkat.",
      source: 'Plugin flutter_qiblah',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referensi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in _items) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(item.body),
                    const SizedBox(height: 8),
                    Text(item.source,
                        style: const TextStyle(
                            color: MarkazColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
