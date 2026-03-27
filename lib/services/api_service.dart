import 'dart:convert';
import 'package:http/http.dart' as http;
import 'quran_cache_service.dart';
import '../config/app_config.dart';

// ── Tafsir sources dari quran.com ─────────────────────────────────
const kTafsirArab = [
  {'id': 14,  'name': 'Ibn Kathir'},
  {'id': 15,  'name': 'Al-Thabari'},
  {'id': 16,  'name': 'Muyassar'},
  {'id': 90,  'name': 'Al-Qurthubi'},
  {'id': 91,  'name': "Al-Sa'di"},
  {'id': 93,  'name': 'Al-Wasith'},
  {'id': 94,  'name': 'Al-Baghawi'},
];

class ApiService {
  static String get _quranBase  => AppConfig.quranApiBaseUrl;
  static String get _equranBase => AppConfig.equranApiBaseUrl;
  static String get _sigmaBase  => AppConfig.sigmaApiBaseUrl;

  // Mencari ID Kota berdasarkan keyword (misal 'sleman' atau 'jepara')
  static Future<String?> getCityId(String keyword) async {
    try {
      final response = await http.get(
          Uri.parse('$_quranBase/sholat/kabkota/cari/$keyword'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null && json['data'].isNotEmpty) {
          // Ambil ID kota pertama yang cocok
          return json['data'][0]['id'];
        }
      }
    } catch (e) {
      print('Error getCityId: \$e');
    }
    return null;
  }

  // Mengambil jadwal sholat hari ini berdasarkan ID Kota
  static Future<Map<String, dynamic>?> getTodaySchedule(String cityId) async {
    try {
      final response = await http.get(
          Uri.parse('$_quranBase/sholat/jadwal/$cityId/today'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          return {
            'lokasi': json['data']['kabko'],
            'jadwal': json['data']['jadwal'],
          };
        }
      }
    } catch (e) {
      print('Error getTodaySchedule: \$e');
    }
    return null;
  }

  // Mengambil daftar Surah Al-Quran (cache-first)
  static Future<List<dynamic>?> getSurahList() async {
    // 1. Cek cache lokal dulu
    final cached = await QuranCacheService.getSurahList();
    if (cached != null) return cached;

    // 2. Tidak ada di cache → fetch dari API
    try {
      final response = await http.get(Uri.parse('$_quranBase/quran'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          final list = json['data'] as List<dynamic>;
          // 3. Simpan ke cache untuk next time
          await QuranCacheService.saveSurahList(list);
          return list;
        }
      }
    } catch (e) {
      print('Error getSurahList: $e');
    }
    return null;
  }

  // Mengambil detail Surah beserta ayat-ayatnya (cache-first)
  static Future<Map<String, dynamic>?> getSurahDetail(int surahNumber) async {
    // 1. Cek cache lokal dulu
    final cached = await QuranCacheService.getSurahDetail(surahNumber);
    if (cached != null) return cached;

    // 2. Tidak ada di cache → fetch dari API
    try {
      final response = await http.get(
          Uri.parse('$_equranBase/surat/$surahNumber'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 200 && json['data'] != null) {
          final data = json['data'];
          final result = {
            'number_of_ayahs': data['jumlahAyat'],
            'name': data['nama'],
            'revelation': data['tempatTurun'],
            'ayahs': (data['ayat'] as List).map((a) => {
              'ayah_number': a['nomorAyat'],
              'arab': a['teksArab'],
              'transliteration': a['teksLatin'] ?? '',
              'translation': a['teksIndonesia'],
            }).toList(),
          };
          // 3. Simpan ke cache untuk next time
          await QuranCacheService.saveSurahDetail(surahNumber, result);
          return result;
        }
      }
    } catch (e) {
      print('Error getSurahDetail: $e');
    }
    return null;
  }

  // Mengambil Laporan Santri dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getLaporanSigma(String nama) async {
    try {
      final response = await http.get(
          Uri.parse('$_sigmaBase/mobile/laporan-santri?nama=$nama'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getLaporanSigma: $e');
    }
    return null;
  }

  // Mengambil Hasil Tes dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getHasilTes() async {
    try {
      final response = await http.get(
          Uri.parse('$_sigmaBase/mobile/hasil-tes'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getHasilTes: $e');
    }
    return null;
  }

  // Mengambil daftar postingan Instagram dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getInstagramPosts() async {
    try {
      final response = await http.get(
          Uri.parse('$_sigmaBase/instagram/feed'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getInstagramPosts: $e');
    }
    return null;
  }

  // Mengambil agenda rutinan dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getAgenda({int? month, int? year}) async {
    try {
      String url = '$_sigmaBase/mobile/agenda';
      List<String> queryParams = [];
      if (month != null) queryParams.add('month=$month');
      if (year != null) queryParams.add('year=$year');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      final response = await http.get(Uri.parse(url));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getAgenda: $e');
    }
    return null;
  }

  // ── Tafsir dari quran.com API ────────────────────────────────────

  /// Ambil terjemahan Kemenag Indonesia per ayat — dari equran.id
  /// Fetch surah lalu cari ayat yang sesuai (equran.id cache otomatis jika sudah pernah dibuka)
  static Future<String?> getTafsirIndo(int surahNum, int ayatNum) async {
    try {
      final url = '$_equranBase/surat/$surahNum';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final jsonBody = jsonDecode(res.body);
        final ayatList = jsonBody['data']?['ayat'] as List?;
        if (ayatList != null) {
          for (final a in ayatList) {
            if (a['nomorAyat'] == ayatNum) {
              final teks = a['teksIndonesia'] as String?;
              return teks?.trim();
            }
          }
        }
      }
    } catch (e) {
      print('Error getTafsirIndo: \$e');
    }
    return null;
  }

  /// Ambil tafsir Arab berdasarkan ID kitab dari quran.com.
  /// [tafsirId]: gunakan konstanta dari kTafsirArab
  static Future<String?> getTafsirArab(int tafsirId, int surahNum, int ayatNum) async {
    return _fetchTafsir(tafsirId, surahNum, ayatNum);
  }

  /// Fetch helper — quran.com v4 tafsir by ayah
  static Future<String?> _fetchTafsir(int tafsirId, int surahNum, int ayatNum) async {
    try {
      final url = 'https://api.quran.com/api/v4/tafsirs/$tafsirId/by_ayah/$surahNum:$ayatNum';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final text = json['tafsir']?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          // Strip HTML tags
          return text
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll(RegExp(r'\n{3,}'), '\n\n')
              .trim();
        }
      }
    } catch (e) {
      print('Error getTafsir: \$e');
    }
    return null;
  }

  /// Ekstraktor (Scraper Otomatis) untuk mencari Original Image dari URL post Instagram
  /// agar admin tidak perlu upload URL Thumbnail secara manual.
  static Future<String?> extractInstagramThumbnail(String url) async {
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        },
      );
      if (res.statusCode == 200) {
        // Cari tag meta property="og:image" content="..."
        final match = RegExp(r'<meta property="og:image" content="([^"]+)"')
            .firstMatch(res.body);
        if (match != null && match.groupCount >= 1) {
          final ogImageUrl = match.group(1)!;
          // Decode URL HTML specifiers if any
          return ogImageUrl.replaceAll('&amp;', '&');
        }
      }
    } catch (e) {
      print('Error extractInstagramThumbnail: $e');
    }
    return null;
  }
}
