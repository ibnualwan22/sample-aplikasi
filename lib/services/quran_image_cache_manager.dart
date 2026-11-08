import 'dart:io' as io;

import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'quran_cache_service.dart';

/// Custom CacheManager khusus untuk gambar halaman mushaf Al-Quran.
///
/// - maxNrOfCacheObjects: 608 → semua halaman bisa tersimpan
/// - stalePeriod: 365 hari → cache bertahan 1 tahun penuh
/// - File tersimpan di direktori dokumen PRIVAT aplikasi (BUKAN direktori
///   cache sementara), supaya Android tidak menghapusnya saat penyimpanan
///   menipis atau saat pengguna menekan "Hapus cache". Folder privat ini
///   TIDAK dipindai Galeri / Google Photos; file `.nomedia` ditambahkan
///   sebagai pengaman tambahan. Cache hanya hilang saat uninstall atau
///   "Hapus data" — sama seperti cache teks surah.
class QuranImageCacheManager {
  static const String _key = 'quranMushafImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      maxNrOfCacheObjects: 608,
      stalePeriod: const Duration(days: 365),
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
      fileSystem: _DocumentsFileSystem(_key),
    ),
  );

  QuranImageCacheManager._();

  /// Migrasi satu kali: salin file cache lama dari direktori sementara ke
  /// direktori dokumen dengan nama file yang SAMA, sehingga unduhan yang
  /// sudah ada tetap terpakai (nama file = relativePath UUID yang tercatat
  /// di database cache; database-nya sendiri tidak dipindah).
  /// Mengembalikan jumlah file yang disalin. Aman dipanggil berulang —
  /// setelah berhasil, penanda di SharedPreferences mencegah jalan ulang.
  static Future<int> migrateLegacyCacheIfNeeded() async {
    if (await QuranCacheService.isMushafMigrated()) return 0;
    int moved = 0;
    try {
      final temp = await getTemporaryDirectory();
      final legacy = io.Directory(p.join(temp.path, _key));
      if (await legacy.exists()) {
        final docs = await getApplicationDocumentsDirectory();
        final target = io.Directory(p.join(docs.path, _key));
        await target.create(recursive: true);
        await for (final entity in legacy.list()) {
          if (entity is io.File) {
            final dest = io.File(p.join(target.path, p.basename(entity.path)));
            if (!await dest.exists()) {
              await entity.copy(dest.path);
              moved++;
            }
          }
        }
      }
    } catch (_) {
      // Migrasi gagal → biarkan unduhan berikutnya mengisi lokasi baru.
    }
    await QuranCacheService.setMushafMigrated();
    return moved;
  }
}

/// FileSystem yang menyimpan file cache di direktori dokumen aplikasi,
/// meniru [IOFileSystem] bawaan yang memakai direktori sementara.
class _DocumentsFileSystem implements FileSystem {
  final String _cacheKey;
  static const _fs = LocalFileSystem();

  _DocumentsFileSystem(this._cacheKey);

  Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = _fs.directory(p.join(base.path, _cacheKey));
    await dir.create(recursive: true);
    // Pengaman: pemindai media melewati folder ini.
    final nomedia = _fs.file(p.join(dir.path, '.nomedia'));
    if (!await nomedia.exists()) await nomedia.create();
    return dir;
  }

  @override
  Future<File> createFile(String name) async {
    final dir = await _directory();
    return dir.childFile(name);
  }
}
