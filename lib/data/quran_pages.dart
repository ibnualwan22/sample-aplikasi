import '../config/app_config.dart';

/// Index ke-0 diabaikan. surahStartPage[N] = halaman pertama surah ke-N.
const List<int> surahStartPage = [
  0, 1, 2, 50, 77, 106, 128, 151, 177, 187, 208,
  221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
  322, 332, 342, 350, 359, 367, 377, 385, 396, 404,
  411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
  477, 483, 489, 496, 499, 502, 507, 511, 515, 518,
  520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
  551, 553, 554, 556, 558, 560, 562, 564, 566, 568,
  570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
  586, 587, 587, 589, 590, 591, 591, 592, 593, 594,
  595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
  600, 600, 601, 601, 601, 602, 602, 602, 603, 603,
  603, 604, 604, 604,
];

/// Halaman pertama setiap Juz (1-30). Index ke-0 diabaikan.
const List<int> juzStartPage = [
  0,
  1,   // Juz 1
  22,  // Juz 2
  42,  // Juz 3
  62,  // Juz 4
  82,  // Juz 5
  102, // Juz 6
  122, // Juz 7
  142, // Juz 8
  162, // Juz 9
  182, // Juz 10
  202, // Juz 11
  222, // Juz 12
  242, // Juz 13
  262, // Juz 14
  282, // Juz 15
  302, // Juz 16
  322, // Juz 17
  342, // Juz 18
  362, // Juz 19
  382, // Juz 20
  402, // Juz 21
  422, // Juz 22
  442, // Juz 23
  462, // Juz 24
  482, // Juz 25
  502, // Juz 26
  522, // Juz 27
  542, // Juz 28
  562, // Juz 29
  582, // Juz 30
];

/// Nama Latin setiap surah (114 surah). Index ke-0 diabaikan.
const List<String> surahNamesLatin = [
  '',
  'Al-Fatihah', 'Al-Baqarah', "Ali 'Imran", 'An-Nisa', "Al-Ma'idah",
  "Al-An'am", "Al-A'raf", 'Al-Anfal', 'At-Tawbah', 'Yunus',
  'Hud', 'Yusuf', "Ar-Ra'd", 'Ibrahim', 'Al-Hijr',
  'An-Nahl', "Al-Isra'", 'Al-Kahf', 'Maryam', 'Ta-Ha',
  'Al-Anbiya', 'Al-Hajj', "Al-Mu'minun", 'An-Nur', 'Al-Furqan',
  "Ash-Shu'ara", 'An-Naml', 'Al-Qasas', 'Al-Ankabut', 'Ar-Rum',
  'Luqman', 'As-Sajdah', 'Al-Ahzab', "Saba'", 'Fatir',
  'Ya-Sin', 'As-Saffat', 'Sad', 'Az-Zumar', 'Ghafir',
  'Fussilat', 'Ash-Shura', 'Az-Zukhruf', 'Ad-Dukhan', 'Al-Jathiyah',
  'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujurat', 'Qaf',
  'Adh-Dhariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahman',
  "Al-Waqi'ah", 'Al-Hadid', 'Al-Mujadila', 'Al-Hashr', 'Al-Mumtahanah',
  'As-Saf', "Al-Jumu'ah", 'Al-Munafiqun', 'At-Taghabun', 'At-Talaq',
  'At-Tahrim', 'Al-Mulk', 'Al-Qalam', 'Al-Haqqah', "Al-Ma'arij",
  'Nuh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddaththir', 'Al-Qiyamah',
  'Al-Insan', 'Al-Mursalat', 'An-Naba', "An-Nazi'at", "'Abasa",
  'At-Takwir', 'Al-Infitar', 'Al-Mutaffifin', 'Al-Inshiqaq', 'Al-Buruj',
  'At-Tariq', "Al-A'la", 'Al-Ghashiyah', 'Al-Fajr', 'Al-Balad',
  'Ash-Shams', 'Al-Layl', 'Ad-Duha', 'Ash-Sharh', 'At-Tin',
  'Al-Alaq', 'Al-Qadr', 'Al-Bayyinah', 'Az-Zalzalah', "Al-'Adiyat",
  "Al-Qari'ah", 'At-Takathur', "Al-'Asr", 'Al-Humazah', 'Al-Fil',
  'Quraysh', "Al-Ma'un", 'Al-Kawthar', 'Al-Kafirun', 'An-Nasr',
  'Al-Masad', 'Al-Ikhlas', 'Al-Falaq', 'An-Nas',
];

/// Nama Juz (1-30). Index ke-0 diabaikan.
const List<String> juzNames = [
  '',
  'Alif Lam Mim', 'Sayaqul', 'Tilkar Rusul', 'Lan Tanalu',
  'Wal Muhsanat', 'La Yuhibbullah', "Wa Iza Sami'u", 'Wa Lau Annana',
  'Qalal Mala', "Wa A'lamu", "Ya'taziroon", 'Wa Ma Min Dabbah',
  "Wa Ma Ubari'u", 'Rubama', 'Subhana', 'Qal Alam',
  'Iqtaraba', 'Qad Aflaha', 'Waqalallazina', 'Amman Khalaqa',
  'Utlu', 'Wa Man Yaqnut', 'Wa Mali', 'Faman Azlamu',
  'Ilaihi Yuraddu', 'Ha Mim', 'Qala Fama', "Qad Sami'allah",
  'Tabarakallazi', 'Amma',
];

/// Total halaman mushaf yang di-upload ke Cloudinary.
const int kTotalMushafPages = 608;

/// URL Cloudinary untuk halaman mushaf ke-[pageNum] (1-indexed).
String mushafPageUrl(int pageNum) {
  final p = pageNum.toString().padLeft(3, '0');
  final cloud = AppConfig.cloudinaryCloudName;
  return 'https://res.cloudinary.com/$cloud/image/upload/quran/halaman-$p.jpg';
}

/// Halaman pertama surah [surahNumber] di mushaf (1-indexed).
int getSurahStartPage(int surahNumber) {
  if (surahNumber < 1 || surahNumber > 114) return 1;
  return surahStartPage[surahNumber];
}

/// Nomor Juz (1-30) berdasarkan nomor halaman mushaf.
int getJuzForPage(int page) {
  for (int j = 30; j >= 1; j--) {
    if (page >= juzStartPage[j]) return j;
  }
  return 1;
}

/// Nomor surah (1-114) berdasarkan nomor halaman mushaf.
int getSurahForPage(int page) {
  for (int s = 114; s >= 1; s--) {
    if (page >= surahStartPage[s]) return s;
  }
  return 1;
}
