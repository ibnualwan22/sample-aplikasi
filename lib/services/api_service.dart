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

  // Mengambil detail Surah berserta ayat-ayatnya dari equran.id (menjamin full ayat)
  static Future<Map<String, dynamic>?> getSurahDetail(int surahNumber) async {
    try {
      final response = await http.get(Uri.parse('https://equran.id/api/v2/surat/$surahNumber'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 200 && json['data'] != null) {
          final data = json['data'];
          // Konversi format equran ke format existing aplikasi
          return {
            'number_of_ayahs': data['jumlahAyat'],
            'name': data['nama'],
            'revelation': data['tempatTurun'],
            'ayahs': (data['ayat'] as List).map((a) => {
              'ayah_number': a['nomorAyat'],
              'arab': a['teksArab'],
              'translation': a['teksIndonesia'],
            }).toList(),
          };
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
      final response = await http.get(Uri.parse('https://sistem-akademik-markaz.vercel.app/api/mobile/laporan-santri?nama=$nama'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getLaporanSigma: $e');
    }
    return null;
  }

  // Mengambil Hasil Tes dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getHasilTes() async {
    try {
      final response = await http.get(Uri.parse('https://sistem-akademik-markaz.vercel.app/api/mobile/hasil-tes'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getHasilTes: $e');
    }
    return null;
  }

  // Mengambil daftar postingan Instagram dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getInstagramPosts() async {
    try {
      final response = await http.get(Uri.parse('https://sistem-akademik-markaz.vercel.app/api/instagram/feed'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getInstagramPosts: $e');
    }
    return null;
  }

  // Mengambil agenda rutinan dari API SIGMA (Vercel)
  static Future<Map<String, dynamic>?> getAgenda({int? month, int? year}) async {
    try {
      String url = 'https://sistem-akademik-markaz.vercel.app/api/mobile/agenda';
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
}
