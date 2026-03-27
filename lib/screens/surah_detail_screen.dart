import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

// ── Konstanta Warna (sama dengan home_screen) ─────────────────
const kBgDark    = Color(0xFF0A0A0A);
const kBgCard    = Color(0xFF141414);
const kBgCard2   = Color(0xFF1C1C1C);
const kGold      = Color(0xFFD4AF37);
const kGoldLight = Color(0xFFEDD56A);
const kGoldDim   = Color(0xFF3A2E0A);
const kTextPri   = Colors.white;
const kTextSec   = Color(0xFFAAAAAA);
const kDivider   = Color(0xFF2A2A2A);

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  Map<String, dynamic>? _surahData;
  bool _isLoading = true;
  bool _isPageMode = false;

  // Ukuran font bisa disesuaikan pengguna
  double _arabicFontSize = 26.0;

  // Pagination
  int _currentPage = 0;
  final int _versesPerPage = 12;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final data = await ApiService.getSurahDetail(widget.surahNumber);
    if (mounted) setState(() { _surahData = data; _isLoading = false; });
  }

  String _toArabicNumber(int n) {
    const en = ['0','1','2','3','4','5','6','7','8','9'];
    const ar = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    String s = n.toString();
    for (int i = 0; i < en.length; i++) s = s.replaceAll(en[i], ar[i]);
    return s;
  }

  // Hapus Bismillah yang disertakan API di ayat 1
  String _cleanAyah(String arab, int number) {
    if (widget.surahNumber != 1 && widget.surahNumber != 9 && number == 1) {
      return arab.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ', '');
    }
    return arab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      // ── AppBar ────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: kGoldLight,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Surah ${widget.surahName}',
              style: const TextStyle(
                color: kTextPri, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_surahData != null)
              Text(
                '${_surahData!['revelation'] ?? ''} · ${_surahData!['number_of_ayahs']} Ayat',
                style: const TextStyle(color: kTextSec, fontSize: 11),
              ),
          ],
        ),
        actions: [
          // Toggle mode
          GestureDetector(
            onTap: () => setState(() => _isPageMode = !_isPageMode),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isPageMode ? kGoldDim : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kGold.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _isPageMode ? Icons.menu_book : Icons.list,
                  color: kGoldLight, size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _isPageMode ? 'Mushaf' : 'Ayat',
                  style: const TextStyle(color: kGoldLight, fontSize: 11),
                ),
              ]),
            ),
          ),
          // Pengaturan font
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields, color: kGoldLight, size: 20),
            color: kBgCard2,
            onSelected: (v) => setState(() => _arabicFontSize = v),
            itemBuilder: (_) => [
              _fontItem('Kecil', 22),
              _fontItem('Sedang', 26),
              _fontItem('Besar', 30),
              _fontItem('Sangat Besar', 34),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kGoldLight, size: 20),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kGold.withOpacity(0.2)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kGold)))
          : _surahData == null
              ? const Center(
                  child: Text('Gagal memuat surat.',
                      style: TextStyle(color: kTextPri)))
              : Column(children: [
                  _buildSurahHeader(),
                  Expanded(
                    child: _isPageMode ? _buildPageMode() : _buildAyahMode(),
                  ),
                ]),
    );
  }

  PopupMenuItem<double> _fontItem(String label, double val) {
    final sel = (_arabicFontSize == val);
    return PopupMenuItem<double>(
      value: val,
      child: Row(children: [
        Icon(Icons.check, color: sel ? kGold : Colors.transparent, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: sel ? kGoldLight : kTextPri)),
      ]),
    );
  }

  // ── Header Surah ────────────────────────────────────────────
  Widget _buildSurahHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        color: kBgCard,
        border: Border(bottom: BorderSide(color: kGold.withOpacity(0.15))),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _headerPill(_surahData!['revelation'] ?? ''),
          // Nama Arab
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: kGoldDim,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kGold.withOpacity(0.6)),
            ),
            child: Text(
              _surahData!['name'] ?? '',
              style: GoogleFonts.amiri(
                fontSize: 22, color: kGoldLight, fontWeight: FontWeight.bold),
            ),
          ),
          _headerPill('${_surahData!['number_of_ayahs']} Ayat'),
        ]),
        const SizedBox(height: 12),
        // Page indicator
        if (_surahData != null && _surahData!['ayahs'] != null)
          Text(
            'Halaman ${_currentPage + 1} / ${((_surahData!['ayahs'] as List).length / _versesPerPage).ceil()}',
            style: const TextStyle(color: kGoldLight, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        // Basmallah
        if (widget.surahNumber != 1 && widget.surahNumber != 9)
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 4),
            child: Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              style: GoogleFonts.amiri(
                fontSize: 26, color: kTextPri, height: 2),
            ),
          ),
      ]),
    );
  }

  Widget _headerPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: kBgCard2,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kDivider),
    ),
    child: Text(text, style: const TextStyle(color: kTextSec, fontSize: 13)),
  );

  // ── MODE AYAT ───────────────────────────────────────────────
  Widget _buildAyahMode() {
    final ayahs = _surahData!['ayahs'] as List;
    if (ayahs.isEmpty) return const SizedBox();
    
    final totalPages = (ayahs.length / _versesPerPage).ceil();

    return PageView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: totalPages,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, pageIndex) {
        final start = pageIndex * _versesPerPage;
        final end = (start + _versesPerPage > ayahs.length) ? ayahs.length : start + _versesPerPage;
        final pageAyahs = ayahs.sublist(start, end);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: pageAyahs.length,
          itemBuilder: (_, i) {
            final ayah = pageAyahs[i];
            final num  = ayah['ayah_number'] as int;
            final arab = _cleanAyah(ayah['arab'] as String, num);

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDivider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header nomor ayat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kBgCard2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: kGold.withOpacity(0.12))),
              ),
              child: Row(children: [
                // Nomor ayat emas bulat
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: kGoldDim,
                    border: Border.all(color: kGold.withOpacity(0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text('$num',
                    style: const TextStyle(color: kGoldLight, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: kTextSec, size: 18),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ]),
            ),
            // Teks Arab
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                '$arab ﴿${_toArabicNumber(num)}﴾',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: _arabicFontSize,
                  color: kTextPri,
                  height: 2.0,
                  letterSpacing: 0,
                ),
              ),
            ),
            // Terjemahan
            if (ayah['translation'] != null && (ayah['translation'] as String).isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: kGold, width: 2)),
                ),
                child: Text(
                  ayah['translation'],
                  style: const TextStyle(color: kTextSec, fontSize: 13, height: 1.7),
                ),
              ),
          ]),
        );
      },
    );
      },
    );
  }

  // ── MODE HALAMAN (MUSHAF) ───────────────────────────────────
  Widget _buildPageMode() {
    final ayahs = _surahData!['ayahs'] as List;
    if (ayahs.isEmpty) return const SizedBox();

    final totalPages = (ayahs.length / _versesPerPage).ceil();

    return PageView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: totalPages,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, pageIndex) {
        final start = pageIndex * _versesPerPage;
        final end = (start + _versesPerPage > ayahs.length) ? ayahs.length : start + _versesPerPage;
        final pageAyahs = ayahs.sublist(start, end);

        final List<InlineSpan> spans = [];
        for (int i = 0; i < pageAyahs.length; i++) {
          final ayah = pageAyahs[i];
          final num  = ayah['ayah_number'] as int;
          final arab = _cleanAyah(ayah['arab'] as String, num);

          spans.add(TextSpan(
            text: '$arab ﴿${_toArabicNumber(num)}﴾ ',
            style: GoogleFonts.amiri(
              fontSize: _arabicFontSize + 2, // sedikit lebih besar agar terbaca jelas
              color: kTextPri,
              height: 2.2,
              fontWeight: FontWeight.w600, // lebih tebal dan rapi layaknya mushaf
            ),
          ));
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            // Info halaman (opsional, dari API jika ada)
            _buildPageInfoBar(pageIndex + 1, totalPages),
            // Halaman mushaf
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: kGold.withOpacity(0.18), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(children: [
                // Bingkai atas halaman
                const _PageBorder(isTop: true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Text.rich(
                    TextSpan(children: spans),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    strutStyle: const StrutStyle(
                      forceStrutHeight: true,
                      height: 2.2,
                      leading: 0.5,
                    ),
                  ),
                ),
                // Bingkai bawah halaman
                const _PageBorder(isTop: false),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildPageInfoBar(int current, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: kBgCard2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.surahName,
            style: const TextStyle(color: kGoldLight, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(
            'Halaman $current / $total',
            style: const TextStyle(color: kTextSec, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Ornamen Bingkai Halaman Atas/Bawah ───────────────────────
class _PageBorder extends StatelessWidget {
  final bool isTop;
  const _PageBorder({required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1500),
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(4))
            : const BorderRadius.vertical(bottom: Radius.circular(4)),
        border: Border(
          top: isTop ? BorderSide(color: kGold.withOpacity(0.5), width: 1) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: kGold.withOpacity(0.5), width: 1) : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(), _line(), _diamond(), _line(), _dot(),
        ],
      ),
    );
  }

  Widget _dot() => Container(
    width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: const BoxDecoration(shape: BoxShape.circle, color: kGold),
  );

  Widget _diamond() => Transform.rotate(
    angle: 0.785,
    child: Container(
      width: 8, height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: kGold,
        borderRadius: BorderRadius.circular(1),
      ),
    ),
  );

  Widget _line() => Expanded(
    child: Container(height: 1, color: kGold.withOpacity(0.45)),
  );
}
