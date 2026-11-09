import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';

/// Endpoint daftar artikel (WP REST API, data live). Carousel Beranda
/// hanya butuh sedikit (perPage 10) agar muat sebelum batas waktu di
/// koneksi lambat; daftar lengkap tetap memakai 100.
String articlesApiUrl({int perPage = 100}) =>
    'https://markazarabiyah.com/wp-json/wp/v2/posts?per_page=$perPage&_embed';

/// Slug duplikat lama SMA Al-Falah (28 Agu 2026) — disaring, yang dipakai
/// yang terbaru (14 Sep 2026).
const String kDuplicateAlFalahSlug =
    'kerjasama-markaz-arabiyah-sma-al-falah-surabaya-dalam-expo-campus-timur-tengah';

/// True bila [text] mengandung huruf Arab (untuk arah tulis RTL).
bool isArabicText(String text) =>
    RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(text);

/// Ubah potongan HTML (judul / kutipan WP) menjadi teks polos.
String plainText(String html) {
  final doc = html_parser.parse(html);
  return (doc.documentElement?.text ?? '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// URL gambar utama artikel (dari `_embedded`), null bila tidak ada.
String? articleImage(Map<String, dynamic> a) {
  try {
    final media = a['_embedded']?['wp:featuredmedia'] as List?;
    if (media != null && media.isNotEmpty) {
      return media[0]['source_url'] as String?;
    }
  } catch (_) {}
  return null;
}

/// Tanggal terbit artikel, mis. "16 Okt 2026".
String articleDate(Map<String, dynamic> a) {
  try {
    final dt = DateTime.parse(a['date'] as String);
    return DateFormat('d MMM yyyy', 'id_ID').format(dt);
  } catch (_) {
    return '';
  }
}
