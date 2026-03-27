import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/quran_pages.dart';
import 'surah_detail_screen.dart';
import 'mushaf_viewer_screen.dart';

const _kBg     = Color(0xFF0A0A0A);
const _kCard   = Color(0xFF141414);
const _kCard2  = Color(0xFF1C1C1C);
const _kGold   = Color(0xFFD4AF37);
const _kGoldL  = Color(0xFFEDD56A);
const _kGoldD  = Color(0xFF3A2E0A);
const _kSec    = Color(0xFFAAAAAA);
const _kDiv    = Color(0xFF2A2A2A);

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _surahList = [];
  bool _isLoading = true;

  // Tab: 0 = Per Surah, 1 = Per Juz
  late TabController _tabCtrl;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _fetchSurahList();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSurahList() async {
    final list = await ApiService.getSurahList();
    if (mounted) {
      setState(() {
        _surahList = list ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredSurah {
    if (_query.isEmpty) return _surahList;
    final q = _query.toLowerCase();
    return _surahList.where((s) {
      final latin = (s['name_latin'] ?? '').toString().toLowerCase();
      final arab  = (s['name'] ?? '').toString();
      final num   = (s['number'] ?? '').toString();
      return latin.contains(q) || arab.contains(q) || num.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: const Text("Al-Qur'an Digital",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(children: [
            // ── Search bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari surah...',
                  hintStyle: const TextStyle(color: _kSec),
                  prefixIcon:
                      const Icon(Icons.search, color: _kSec, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: _kSec, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: _kCard2,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: _kGold.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            // ── Tab Filter ──────────────────────────────────────
            TabBar(
              controller: _tabCtrl,
              indicatorColor: _kGold,
              indicatorWeight: 2,
              labelColor: _kGoldL,
              unselectedLabelColor: _kSec,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Per Surah'),
                Tab(text: 'Per Juz'),
              ],
            ),
          ]),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_kGold)))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSurahTab(),
                _buildJuzTab(),
              ],
            ),
    );
  }

  // ════════════════════════════════════════════
  // TAB 1 — Per Surah
  // ════════════════════════════════════════════
  Widget _buildSurahTab() {
    final list = _filteredSurah;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty
              ? 'Gagal memuat data surat.'
              : 'Surah "$_query" tidak ditemukan.',
          style: const TextStyle(color: _kSec),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) =>
          _buildSurahCard(list[index]),
    );
  }

  Widget _buildSurahCard(dynamic surah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDiv),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGold.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text('${surah['number']}',
              style: const TextStyle(
                  color: _kGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        title: Text(surah['name_latin'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Text(surah['revelation'] ?? '',
                style: const TextStyle(color: _kSec, fontSize: 12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.circle,
                  size: 3, color: _kSec.withValues(alpha: 0.6)),
            ),
            Text('${surah['number_of_ayahs']} Ayat',
                style: const TextStyle(color: _kSec, fontSize: 12)),
          ]),
        ),
        trailing: Text(surah['name'] ?? '',
            style: const TextStyle(
                color: _kGold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri')),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailScreen(
              surahNumber: surah['number'] ?? 1,
              surahName: surah['name_latin'] ?? '',
              surahList: _surahList,
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // TAB 2 — Per Juz
  // ════════════════════════════════════════════
  Widget _buildJuzTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: 30,
      itemBuilder: (context, index) => _buildJuzCard(index + 1),
    );
  }

  Widget _buildJuzCard(int juzNum) {
    final startPage  = juzStartPage[juzNum];
    final endPage    = juzNum < 30
        ? juzStartPage[juzNum + 1] - 1
        : kTotalMushafPages;
    final surahIndex = getSurahForPage(startPage);
    final surahName  = surahNamesLatin[surahIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDiv),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MushafViewerScreen(initialPage: startPage),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Nomor Juz
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _kGoldD,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGold.withValues(alpha: 0.5)),
              ),
              alignment: Alignment.center,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Juz',
                        style:
                            TextStyle(color: _kGoldL, fontSize: 9)),
                    Text('$juzNum',
                        style: const TextStyle(
                            color: _kGoldL,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ]),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(juzNames[juzNum],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Dimulai dari $surahName',
                        style: const TextStyle(
                            color: _kSec, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Halaman $startPage – $endPage',
                        style: TextStyle(
                            color: _kGold.withValues(alpha: 0.8),
                            fontSize: 11)),
                  ]),
            ),
            // Icon buka mushaf
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _kGoldD,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book,
                  color: _kGoldL, size: 18),
            ),
          ]),
        ),
      ),
    );
  }
}
