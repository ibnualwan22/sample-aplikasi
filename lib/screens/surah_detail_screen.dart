import '../theme/markaz_theme.dart';
import 'tafsir_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../data/quran_pages.dart';
import 'mushaf_viewer_screen.dart';

// ── Warna ─────────────────────────────────────────────────────────
const _kBg = MarkazColors.surface;
const _kCard = MarkazColors.ivory;
const _kGold = MarkazColors.gold;
const _kGoldL = MarkazColors.ink;
const _kGoldDim = MarkazColors.tint;
const _kWhite = MarkazColors.ink;
const _kSec = MarkazColors.muted;
const _kDiv = MarkazColors.line;
const _kHeader = MarkazColors.tint;

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
  dynamic get _info =>
      (widget.surahList != null && _currentIdx < widget.surahList!.length)
          ? widget.surahList![_currentIdx]
          : null;

  String get _name => _info?['name_latin'] ?? surahNamesLatin[_surahNum];
  String get _arabName => _info?['name'] ?? '';
  String get _rev => _info?['revelation'] ?? '';
  int get _ayahCnt => (_info?['number_of_ayahs'] ?? 0) as int;
  int get _surahNum => _currentIdx + 1;
  int get _juzNum => getJuzForPage(getSurahStartPage(_surahNum));

  void _pickSurah() {
    var query = '';
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => StatefulBuilder(builder: (context, update) {
              final numbers = List.generate(114, (i) => i + 1)
                  .where((n) =>
                      '$n' == query ||
                      surahNamesLatin[n]
                          .toLowerCase()
                          .replaceAll(RegExp(r"[\s'-]"), '')
                          .contains(query
                              .toLowerCase()
                              .replaceAll(RegExp(r"[\s'-]"), '')))
                  .toList();
              return FractionallySizedBox(
                  heightFactor: .85,
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Pindah surah',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 16),
                            TextField(
                                decoration: const InputDecoration(
                                    labelText: 'Nama atau nomor surah',
                                    prefixIcon: Icon(Icons.search)),
                                onChanged: (value) =>
                                    update(() => query = value.trim())),
                            const SizedBox(height: 8),
                            Expanded(
                                child: numbers.isEmpty
                                    ? const Center(
                                        child: Text('Surah tidak ditemukan.'))
                                    : ListView.builder(
                                        itemCount: numbers.length,
                                        itemBuilder: (_, i) {
                                          final number = numbers[i];
                                          return ListTile(
                                              title: Text(
                                                  '$number. ${surahNamesLatin[number]}'),
                                              selected: number == _surahNum,
                                              selectedTileColor:
                                                  MarkazColors.tint,
                                              textColor: MarkazColors.ink,
                                              selectedColor: MarkazColors.ink,
                                              trailing: number == _surahNum
                                                  ? const Icon(Icons.check)
                                                  : null,
                                              onTap: () {
                                                Navigator.pop(sheetContext);
                                                _pageCtrl
                                                    .jumpToPage(number - 1);
                                              });
                                        })),
                          ])));
            }));
  }

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
                surahName: surahNamesLatin[i + 1],
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
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kGoldL),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: TextButton.icon(
        onPressed: _pickSurah,
        label: const Text('Surah', style: TextStyle(fontSize: 14)),
        icon: const Icon(Icons.unfold_more, size: 18),
      ),
      actions: [
        // Font size
        PopupMenuButton<double>(
          tooltip: 'Ukuran teks Arab',
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
        child: Container(height: 1, color: _kGold.withValues(alpha: 0.15)),
      ),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: _kHeader,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$_surahNum. $_name',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_rev.isNotEmpty)
                  Text(_rev,
                      style: const TextStyle(color: _kSec, fontSize: 12)),
                if (_ayahCnt > 0)
                  Text('$_ayahCnt ayat',
                      style: const TextStyle(color: _kSec, fontSize: 12)),
                Text('Awal juz $_juzNum',
                    style: const TextStyle(color: _kSec, fontSize: 12)),
                if (_arabName.isNotEmpty)
                  Text(_arabName,
                      textDirection: TextDirection.rtl,
                      style:
                          const TextStyle(fontFamily: 'Amiri', fontSize: 20)),
              ]),
        ]),
      );

  PopupMenuItem<double> _fontItem(String label, double val) {
    final sel = _arabicFontSize == val;
    return PopupMenuItem<double>(
      value: val,
      child: Row(children: [
        Icon(Icons.check, color: sel ? _kGold : Colors.transparent, size: 16),
        const SizedBox(width: 8),
        Flexible(
            child:
                Text(label, style: TextStyle(color: sel ? _kGoldL : _kWhite))),
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
    if (mounted)
      setState(() {
        _data = data;
        _isLoading = false;
      });
  }

  // ── Utilities ─────────────────────────────────────────────────────
  String _toArab(int n) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String s = n.toString();
    for (int i = 0; i < en.length; i++) s = s.replaceAll(en[i], ar[i]);
    return s;
  }

  String _cleanArab(String arab, int num) {
    if (widget.surahNumber != 1 && widget.surahNumber != 9 && num == 1) {
      return arab.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ', '');
    }
    return arab;
  }

  // ── Copy ──────────────────────────────────────────────────────────
  void _copyAyah(Map<String, dynamic> ayah) {
    final num = ayah['ayah_number'] as int;
    final arab = (ayah['arab'] as String).trim();
    final tr = (ayah['translation'] ?? '') as String;

    final text = "Allah Subhanahu Wa Ta'ala berfirman:\n\n"
        "$arab\n\n"
        '"$tr"\n'
        '(QS. ${widget.surahName} ${widget.surahNumber}: Ayat $num).';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: const [
          Icon(Icons.check_circle, color: Colors.black87, size: 18),
          SizedBox(width: 8),
          Text('Ayat disalin!', style: TextStyle(color: Colors.black87)),
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
      useSafeArea: true,
      isScrollControlled: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: _kDiv, borderRadius: BorderRadius.circular(2)),
          ),
          // Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: _kGoldDim,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kGold.withValues(alpha: 0.5))),
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
              Expanded(
                  child: Text(
                'QS. ${widget.surahName} ${widget.surahNumber}: Ayat ${ayah['ayah_number']}',
                style: const TextStyle(color: _kSec, fontSize: 12),
              )),
            ]),
          ),
          const Divider(color: _kDiv),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kGoldDim, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.copy_outlined, color: _kGoldL, size: 18),
            ),
            title: const Text('Salin Ayat',
                style: TextStyle(color: _kWhite, fontWeight: FontWeight.w600)),
            subtitle: const Text('Format siap pakai untuk disalin.',
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
                  color: _kGoldDim, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_stories_outlined,
                  color: _kGoldL, size: 18),
            ),
            title: const Text('Lihat Tafsir',
                style: TextStyle(color: _kWhite, fontWeight: FontWeight.w600)),
            subtitle: const Text('Tafsir dari berbagai kitab ulama',
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
          heightFactor: .94,
          child: Directionality(
              textDirection: TextDirection.ltr,
              child: TafsirScreen(
                  initialSurah: widget.surahNumber,
                  initialAyah: ayah['ayah_number'] as int))),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(MarkazColors.ink)),
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
        final ayah = ayahs[i] as Map<String, dynamic>;
        final num = ayah['ayah_number'] as int;
        final arab = _cleanArab(ayah['arab'] as String, num);
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
                  style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 26,
                      color: _kWhite,
                      height: 2.2),
                ),
              ),

            // ── Satu baris ayat ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Konten kanan (berada di kanan karena RTL)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arab + nomor ayat
                        Text(
                          '$arab ﴿${_toArab(num)}﴾',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
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
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                                color: _kGoldL, fontSize: 13, height: 1.6),
                          ),
                        ],

                        // Terjemahan
                        if (trans.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            trans,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                                color: _kSec, fontSize: 14, height: 1.75),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                                onPressed: () => _showTafsirModal(ayah),
                                icon: const Icon(Icons.auto_stories_outlined,
                                    size: 18),
                                label: Text('Tafsir ayat $num',
                                    textDirection: TextDirection.ltr))),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // ⋮ Kiri (berada di kiri layar karena elemen kedua dalam RTL)
                  IconButton(
                    tooltip: 'Pilihan ayat $num',
                    icon: const Icon(Icons.more_vert, color: _kSec, size: 20),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => _showOptions(ayah),
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
