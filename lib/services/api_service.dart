import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.myquran.com/v3';

  // Mencari ID Kota berdasarkan keyword (misal 'sleman' atau 'jepara')
  static Future<String?> getCityId(String keyword) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sholat/kabkota/cari/$keyword'));
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
      final response = await http.get(Uri.parse('$baseUrl/sholat/jadwal/$cityId/today'));
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

  // Mengambil daftar Surah Al-Quran
  static Future<List<dynamic>?> getSurahList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quran'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          return json['data'];
        }
      }
    } catch (e) {
      print('Error getSurahList: \$e');
    }
    return null;
  }

  // Mengambil detail Surah berserta ayat-ayatnya dari MyQuran
  static Future<Map<String, dynamic>?> getSurahDetail(int surahNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quran/$surahNumber'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          return json['data'];
        }
      }
    } catch (e) {
      print('Error getSurahDetail: \$e');
    }
    return null;
  }

  // Mengambil Laporan Santri dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getLaporanSigma(String nama) async {
    try {
      final response = await http.get(Uri.parse('https://sistem-akademik-markaz.vercel.app/api/mobile/laporan-santri?nama=$nama'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getLaporanSigma: $e');
    }
    return null;
  }
}
