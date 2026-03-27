import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Satu pintu akses untuk semua environment variables.
/// Gunakan class ini di seluruh aplikasi — jangan hardcode URL/key.
class AppConfig {
  AppConfig._();

  // ── Cloudinary ────────────────────────────────────────────────
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  // ── API Al-Quran ──────────────────────────────────────────────
  static String get quranApiBaseUrl =>
      dotenv.env['QURAN_API_BASE_URL'] ?? 'https://api.myquran.com/v3';

  static String get equranApiBaseUrl =>
      dotenv.env['EQURAN_API_BASE_URL'] ?? 'https://equran.id/api/v2';

  // ── API Sistem Akademik SIGMA ─────────────────────────────────
  static String get sigmaApiBaseUrl =>
      dotenv.env['SIGMA_API_BASE_URL'] ??
      'https://sistem-akademik-markaz.vercel.app/api';
}
