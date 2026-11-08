import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan dan membaca cache data teks Al-Quran
/// menggunakan SharedPreferences.
///
/// Cache ini TIDAK hilang saat update aplikasi.
/// Cache HANYA hilang jika user uninstall app atau Clear Data.
class QuranCacheService {
  static const String _surahListKey   = 'quran_surah_list';
  static const String _surahDetailPfx = 'quran_surah_detail_';

  // ── Surah List (114 surah) ─────────────────────────────────────

  /// Simpan daftar surah ke cache lokal.
  static Future<void> saveSurahList(List<dynamic> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_surahListKey, jsonEncode(list));
  }

  /// Baca daftar surah dari cache. Null jika belum pernah disimpan.
  static Future<List<dynamic>?> getSurahList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_surahListKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Surah Detail (per surah, berisi ayat + terjemahan) ─────────

  /// Simpan detail surah [surahNumber] ke cache lokal.
  static Future<void> saveSurahDetail(
      int surahNumber, Map<String, dynamic> detail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_surahDetailPfx$surahNumber', jsonEncode(detail));
  }

  /// Baca detail surah [surahNumber] dari cache. Null jika belum ada.
  static Future<Map<String, dynamic>?> getSurahDetail(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_surahDetailPfx$surahNumber');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Cek apakah detail surah [surahNumber] sudah ada di cache.
  static Future<bool> hasSurahDetail(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_surahDetailPfx$surahNumber');
  }

  /// Cek berapa banyak surah yang sudah di-cache (0-114).
  static Future<int> cachedSurahCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    for (int i = 1; i <= 114; i++) {
      if (prefs.containsKey('$_surahDetailPfx$i')) count++;
    }
    return count;
  }

  /// Hapus semua cache Al-Quran (surah list + semua detail surah).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_surahListKey);
    for (int i = 1; i <= 114; i++) {
      await prefs.remove('$_surahDetailPfx$i');
    }
  }

  // ── Mushaf offline (gambar halaman) ─────────────────────────────
  // Penanda persisten bahwa SEMUA halaman mushaf sudah terunduh, beserta
  // nama cloud yang dipakai saat mengunduh. Cloud disimpan karena kunci
  // cache gambar adalah URL lengkapnya — ganti cloud = URL berubah =
  // cache lama tidak berlaku lagi, dan penanda ini sengaja ikut gugur.

  static const String _mushafDoneKey = 'quran_mushaf_downloaded';
  static const String _mushafCloudKey = 'quran_mushaf_downloaded_cloud';
  static const String _mushafCountKey = 'quran_mushaf_downloaded_count';
  static const String _mushafMigratedKey = 'quran_mushaf_migrated_to_docs';

  /// Tandai unduh mushaf selesai untuk [cloudName] sebanyak [pageCount].
  static Future<void> saveMushafDownloaded(
      {required String cloudName, required int pageCount}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mushafDoneKey, true);
    await prefs.setString(_mushafCloudKey, cloudName);
    await prefs.setInt(_mushafCountKey, pageCount);
  }

  /// True bila mushaf sudah terunduh penuh DENGAN cloud yang sama dengan
  /// [cloudName] saat ini. Beda cloud → false (cache lama tak berlaku).
  static Future<bool> isMushafDownloadedFor(String cloudName) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_mushafDoneKey) ?? false)) return false;
    return prefs.getString(_mushafCloudKey) == cloudName;
  }

  /// Jumlah halaman saat penanda disimpan (0 bila belum pernah).
  static Future<int> mushafDownloadedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mushafCountKey) ?? 0;
  }

  /// Hapus penanda unduh mushaf (mis. saat unduh ulang dari nol).
  static Future<void> clearMushafDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mushafDoneKey);
    await prefs.remove(_mushafCloudKey);
    await prefs.remove(_mushafCountKey);
  }

  /// True bila migrasi cache lama (direktori sementara → dokumen) sudah
  /// pernah dijalankan.
  static Future<bool> isMushafMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mushafMigratedKey) ?? false;
  }

  static Future<void> setMushafMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mushafMigratedKey, true);
  }
}
