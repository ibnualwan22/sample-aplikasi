import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom CacheManager khusus untuk gambar halaman mushaf Al-Quran.
///
/// - maxNrOfCacheObjects: 608 → semua halaman bisa tersimpan
/// - stalePeriod: 365 hari → cache bertahan 1 tahun penuh
/// - Cache ini TIDAK hilang saat update aplikasi.
class QuranImageCacheManager {
  static const String _key = 'quranMushafImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      maxNrOfCacheObjects: 608,
      stalePeriod: const Duration(days: 365),
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );

  QuranImageCacheManager._();
}
