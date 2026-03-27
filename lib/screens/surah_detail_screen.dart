import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../data/quran_pages.dart';
import 'mushaf_viewer_screen.dart';

// ── Warna ─────────────────────────────────────────────────────────
const _kBg       = Color(0xFF181A1F);
const _kCard     = Color(0xFF1E2028);
const _kGold     = Color(0xFFD4AF37);
const _kGoldL    = Color(0xFFEDD56A);
const _kGoldDim  = Color(0xFF3A2E0A);
const _kWhite    = Colors.white;
const _kSec      = Color(0xFFAAAAAA);
const _kDiv      = Color(0xFF2A2A2D);
const _kHeader   = Color(0xFF0D3330);

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  /// Daftar 114 surah untuk navigasi swipe antar surah.
  final List<dynamic>? surahList;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.surahList,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late PageController _pageCtrl;
  int _currentIdx = 0;
  double _arabicFontSize = 26.0;

  @override
  void initState() {
    super.initState();
    _currentIdx = widget.surahNumber - 1;
    _pageCtrl = PageController(initialPage: _currentIdx);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────
  dynamic get _info => (widget.surahList != null &&
          _currentIdx < widget.surahList!.length)
      ? widget.surahList![_currentIdx]
      : null;

  String get _name     => _info?['name_latin']       ?? widget.surahName;
  String get _arabName => _info?['name']             ?? '';
  String get _rev      => _info?['revelation']       ?? '';
  int    get _ayahCnt  => (_info?['number_of_ayahs'] ?? 0) as int;
  int    get _surahNum => _currentIdx + 1;
  int    get _juzNum   => getJuzForPage(getSurahStartPage(_surahNum));

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: Directionality(
            // RTL: geser kiri→kanan = surah berikutnya (Mushaf Arab style)
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: 114,
              onPageChanged: (i) => setState(() => _currentIdx = i),
              itemBuilder: (_, i) => _SurahAyahPage(
                key: ValueKey(i + 1),
                surahNumber: i + 1,
                surahName:
                    widget.surahList?[i]?['name_latin'] ?? 'Surah ${i + 1}',
                arabicFontSize: _arabicFontSize,
              ),
            ),
          ),
        ),
      ]),

    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _kCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: _kGoldL),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {/* bisa tambah picker juz nanti */},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: _kGold.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Juz $_juzNum',
                style: const TextStyle(color: _kGoldL, fontSize: 13)),
            const Icon(Icons.keyboard_arrow_down,
                color: _kGoldL, size: 16),
          ]),
        ),
      ),
      actions: [
        // Font size
        PopupMenuButton<double>(
          icon: const Icon(Icons.text_fields, color: _kGoldL, size: 20),
          color: _kCard,
          onSelected: (v) => setState(() => _arabicFontSize = v),
          itemBuilder: (_) => [
            _fontItem('Kecil', 22),
            _fontItem('Sedang', 26),
            _fontItem('Besar', 30),
            _fontItem('Sangat Besar', 34),
          ],
        ),
        // Buka Mushaf
        IconButton(
          icon: const Icon(Icons.menu_book, color: _kGoldL, size: 20),
          tooltip: 'Tampilan Mushaf',
          onPressed: () {
            final p = getSurahStartPage(_surahNum);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MushafViewerScreen(initialPage: p)),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child:
            Container(height: 1, color: _kGold.withValues(alpha: 0.15)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: _kHeader,
        border: Border(
            bottom:
                BorderSide(color: _kGold.withValues(alpha: 0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _pill(_rev.isNotEmpty ? _rev : '-'),
          // Nama Arab dalam oval
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2220),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: _kGold.withValues(alpha: 0.6)),
            ),
            child: Text(
              _arabName.isNotEmpty ? _arabName : _name,
              style: GoogleFonts.amiri(
                  fontSize: 20,
                  color: _kGoldL,
                  fontWeight: FontWeight.bold),
            ),
          ),
          _pill('$_ayahCnt Ayat'),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2220),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _kGold.withValues(alpha: 0.35)),
        ),
        child: Text(text,
            style: const TextStyle(color: _kGoldL, fontSize: 12)),
      );

  PopupMenuItem<double> _fontItem(String label, double val) {
    final sel = _arabicFontSize == val;
    return PopupMenuItem<double>(
      value: val,
      child: Row(children: [
        Icon(Icons.check,
            color: sel ? _kGold : Colors.transparent, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: sel ? _kGoldL : _kWhite)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// _SurahAyahPage — satu halaman = satu surah penuh (scrollable)
// ══════════════════════════════════════════════════════════════════
class _SurahAyahPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final double arabicFontSize;

  const _SurahAyahPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.arabicFontSize,
  });

  @override
  State<_SurahAyahPage> createState() => _SurahAyahPageState();
}

class _SurahAyahPageState extends State<_SurahAyahPage>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await ApiService.getSurahDetail(widget.surahNumber);
    if (mounted) setState(() { _data = data; _isLoading = false; });
  }

  // ── Utilities ─────────────────────────────────────────────────────
  String _toArab(int n) {
    const en = ['0','1','2','3','4','5','6','7','8','9'];
    const ar = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    String s = n.toString();
    for (int i = 0; i < en.length; i++) s = s.replaceAll(en[i], ar[i]);
    return s;
  }

  String _cleanArab(String arab, int num) {
    if (widget.surahNumber != 1 && widget.surahNumber != 9 && num == 1) {
      return arab
          .replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ', '');
    }
    return arab;
  }

  // ── Copy ──────────────────────────────────────────────────────────
  void _copyAyah(Map<String, dynamic> ayah) {
    final num   = ayah['ayah_number'] as int;
    final arab  = (ayah['arab'] as String).trim();
    final tr    = (ayah['translation'] ?? '') as String;

    final text =
        "Allah Subhanahu Wa Ta'ala berfirman:\n\n"
        "$arab\n\n"
        '"$tr"\n'
        '(QS. ${widget.surahName} ${widget.surahNumber}: Ayat $num).';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: const [
          Icon(Icons.check_circle, color: Colors.black87, size: 18),
          SizedBox(width: 8),
          Text('Ayat disalin!',
              style: TextStyle(color: Colors.black87)),
        ]),
        backgroundColor: _kGold,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Options Bottom Sheet ──────────────────────────────────────────
  void _showOptions(Map<String, dynamic> ayah) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: _kDiv, borderRadius: BorderRadius.circular(2)),
          ),
          // Header info
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _kGoldDim,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _kGold.withValues(alpha: 0.5))),
                alignment: Alignment.center,
                child: Text(
                  '${ayah['ayah_number']}',
                  style: const TextStyle(
                      color: _kGoldL,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'QS. ${widget.surahName} ${widget.surahNumber}: Ayat ${ayah['ayah_number']}',
                style: const TextStyle(color: _kSec, fontSize: 12),
              ),
            ]),
          ),
          const Divider(color: _kDiv),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kGoldDim,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.copy_outlined,
                  color: _kGoldL, size: 18),
            ),
            title: const Text('Salin Ayat',
                style: TextStyle(color: _kWhite, fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Format siap pakai untuk disalin.',
                style: TextStyle(color: _kSec, fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              _copyAyah(ayah);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kGoldDim,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_stories_outlined,
                  color: _kGoldL, size: 18),
            ),
            title: const Text('Lihat Tafsir',
                style: TextStyle(color: _kWhite, fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Tafsir dari berbagai kitab ulama',
                style: TextStyle(color: _kSec, fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              _showTafsirModal(ayah);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Tafsir Modal ─────────────────────────────────────────────────
  void _showTafsirModal(Map<String, dynamic> ayah) {
    final num  = ayah['ayah_number'] as int;
    final arab = (ayah['arab'] as String? ?? '').trim();
    final surahName = widget.surahName;
    final surahNum  = widget.surahNumber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TafsirModal(
        surahNum: surahNum,
        ayatNum: num,
        surahName: surahName,
        arabText: arab,
        transText: (ayah['translation'] as String? ?? ''),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_kGold)),
      );
    }

    if (_data == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: _kSec, size: 52),
          const SizedBox(height: 12),
          Text('Surah ${widget.surahName} belum di-cache',
              style: const TextStyle(color: _kSec)),
          const SizedBox(height: 4),
          const Text('Butuh internet untuk pertama kali',
              style: TextStyle(color: _kSec, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kGoldDim, foregroundColor: _kGoldL),
          ),
        ]),
      );
    }

    final ayahs = _data!['ayahs'] as List;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 0, bottom: 48),
      itemCount: ayahs.length,
      itemBuilder: (_, i) {
        final ayah  = ayahs[i] as Map<String, dynamic>;
        final num   = ayah['ayah_number'] as int;
        final arab  = _cleanArab(ayah['arab'] as String, num);
        final latin = (ayah['transliteration'] ?? '') as String;
        final trans = (ayah['translation'] ?? '') as String;

        // Basmallah sebelum ayat 1 (kecuali surah 1 & 9)
        final bool showBasmallah =
            num == 1 && widget.surahNumber != 1 && widget.surahNumber != 9;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showBasmallah)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                      fontSize: 26, color: _kWhite, height: 2.2),
                ),
              ),

            // ── Satu baris ayat ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⋮ Kiri
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: _kSec, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                    onPressed: () => _showOptions(ayah),
                  ),

                  // Konten kanan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arab + nomor ayat
                        Text(
                          '$arab ﴿${_toArab(num)}﴾',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(
                            fontSize: widget.arabicFontSize,
                            color: _kWhite,
                            height: 2.1,
                          ),
                        ),

                        // Transliterasi (warna emas)
                        if (latin.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            latin,
                            style: const TextStyle(
                                color: _kGoldL,
                                fontSize: 13,
                                height: 1.6),
                          ),
                        ],

                        // Terjemahan
                        if (trans.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            trans,
                            style: const TextStyle(
                                color: _kSec,
                                fontSize: 14,
                                height: 1.75),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Garis pemisah
            Divider(color: _kDiv, height: 1, indent: 52),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// _TafsirModal — DraggableScrollableSheet untuk tafsir per-ayat
// ══════════════════════════════════════════════════════════════════
class _TafsirModal extends StatefulWidget {
  final int surahNum;
  final int ayatNum;
  final String surahName;
  final String arabText;
  final String transText;

  const _TafsirModal({
    required this.surahNum,
    required this.ayatNum,
    required this.surahName,
    required this.arabText,
    required this.transText,
  });

  @override
  State<_TafsirModal> createState() => _TafsirModalState();
}

class _TafsirModalState extends State<_TafsirModal> {
  int? _selectedId;
  String? _tafsirText;
  bool _isLoading = false;
  String _selectedName = 'Kemenag';

  static const _kitabs = [
    {'id': null,  'name': 'Kemenag'},
    {'id': 14,    'name': 'Ibn Kathir'},
    {'id': 15,    'name': 'Al-Thabari'},
    {'id': 16,    'name': 'Muyassar'},
    {'id': 90,    'name': 'Al-Qurthubi'},
    {'id': 91,    'name': "Al-Sa'di"},
    {'id': 93,    'name': 'Al-Wasith'},
    {'id': 94,    'name': 'Al-Baghawi'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTafsir(null);
  }

  Future<void> _fetchTafsir(int? tafsirId) async {
    setState(() { _isLoading = true; _tafsirText = null; });
    try {
      String? result;
      if (tafsirId == null) {
        result = await ApiService.getTafsirIndo(widget.surahNum, widget.ayatNum);
      } else {
        result = await ApiService.getTafsirArab(tafsirId, widget.surahNum, widget.ayatNum);
      }
      if (mounted) setState(() { _tafsirText = result; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _copyTafsir() {
    if (_tafsirText == null) return;
    Clipboard.setData(ClipboardData(text:
      '${widget.arabText}\n\n'
      'Tafsir $_selectedName:\n$_tafsirText\n\n'
      '(QS. ${widget.surahName} ${widget.surahNum}:${widget.ayatNum})'
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Tafsir disalin!', style: TextStyle(color: Colors.black87)),
      backgroundColor: _kGold,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.93,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: _kDiv, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGoldDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                ),
                child: Text('QS. ${widget.surahName} : ${widget.ayatNum}',
                  style: const TextStyle(color: _kGoldL, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              if (_tafsirText != null)
                IconButton(
                  icon: const Icon(Icons.copy_outlined, color: _kGoldL, size: 20),
                  onPressed: _copyTafsir,
                  tooltip: 'Salin Tafsir',
                ),
            ]),
          ),
          // Preview Arab
          if (widget.arabText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.arabText,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(fontSize: 20, color: _kWhite, height: 2.0),
              ),
            ),
          // Chips kitab
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _kitabs.length,
              itemBuilder: (_, i) {
                final k    = _kitabs[i];
                final kId  = k['id'] as int?;
                final kNm  = k['name'] as String;
                final sel  = _selectedId == kId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(kNm),
                    selected: sel,
                    onSelected: (_) {
                      setState(() { _selectedId = kId; _selectedName = kNm; });
                      _fetchTafsir(kId);
                    },
                    selectedColor: _kGold,
                    backgroundColor: _kBg,
                    labelStyle: TextStyle(
                      color: sel ? Colors.black : _kSec,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: sel ? _kGold : _kDiv),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          const Divider(color: _kDiv, height: 1),
          // Konten
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_kGold)))
              : _tafsirText == null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.info_outline, color: _kSec, size: 32),
                    const SizedBox(height: 8),
                    Text('Tafsir $_selectedName belum tersedia untuk ayat ini.',
                      style: const TextStyle(color: _kSec, fontSize: 13),
                      textAlign: TextAlign.center),
                  ]))
                : Scrollbar(
                    controller: ctrl,
                    child: SingleChildScrollView(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.auto_stories, color: _kGoldL, size: 16),
                          const SizedBox(width: 6),
                          Text('Tafsir $_selectedName',
                            style: const TextStyle(color: _kGoldL, fontWeight: FontWeight.bold, fontSize: 13)),
                        ]),
                        const SizedBox(height: 10),
                        Text(_tafsirText!,
                          style: const TextStyle(color: _kWhite, fontSize: 14, height: 1.8)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_outlined, size: 16),
                            label: const Text('Salin Tafsir'),
                            onPressed: _copyTafsir,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kGoldL,
                              side: const BorderSide(color: _kGold),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
