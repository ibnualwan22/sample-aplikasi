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
}
