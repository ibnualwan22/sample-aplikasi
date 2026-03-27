// ignore_for_file: avoid_print
/// Script generator untuk quran_index.json
/// Jalankan: dart run tools/generate_quran_index.dart
/// Menghasilkan: assets/quran_index.json (~1.5MB raw, ~400KB gzip di APK)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Strip harakat (tanda baca) dari teks Arab
String stripHarakat(String s) {
  return s
      .replaceAll(RegExp(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u0670\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Future<void> main() async {
  print('=== Quran Index Generator ===');
  print('Fetching 114 surahs from equran.id...\n');

  final allAyat = <Map<String, dynamic>>[];
  int totalAyat = 0;

  for (int surahNum = 1; surahNum <= 114; surahNum++) {
    final url = 'https://equran.id/api/v2/surat/$surahNum';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        print('[$surahNum] ERROR: status ${res.statusCode}');
        continue;
      }
      final json = jsonDecode(res.body);
      if (json['code'] != 200 || json['data'] == null) {
        print('[$surahNum] ERROR: invalid response');
        continue;
      }
      final data = json['data'];
      final surahLatin = data['namaLatin'] as String;
      final surahArab  = data['nama'] as String;
      final ayatList   = data['ayat'] as List;

      for (final a in ayatList) {
        final arabRaw    = (a['teksArab'] ?? '') as String;
        final transRaw   = (a['teksIndonesia'] ?? '') as String;
        final arabStripped = stripHarakat(arabRaw);

        // Ambil max 80 karakter terjemahan sebagai snippet
        final transSnip = transRaw.length > 80
            ? '${transRaw.substring(0, 80)}...'
            : transRaw;

        allAyat.add({
          's': surahNum,
          'a': a['nomorAyat'],
          'l': surahLatin,
          'n': surahArab,
          'q': arabStripped,
          't': transSnip,
        });
        totalAyat++;
      }
      print('[$surahNum/114] $surahLatin — ${ayatList.length} ayat ✓');

      // Jeda kecil agar tidak rate-limit
      await Future.delayed(const Duration(milliseconds: 80));
    } catch (e) {
      print('[$surahNum] EXCEPTION: $e');
    }
  }

  print('\nTotal ayat terkumpul: $totalAyat');

  // Tulis ke assets/quran_index.json
  final outFile = File('assets/quran_index.json');
  await outFile.create(recursive: true);
  await outFile.writeAsString(jsonEncode(allAyat));

  final sizeKb = (await outFile.length()) / 1024;
  print('Output: ${outFile.path} (${sizeKb.toStringAsFixed(1)} KB)');
  print('\nDone! Tambahkan assets/quran_index.json ke pubspec.yaml dan jalankan flutter pub get.');
}
