import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

// ── Warna (konsisten dengan tema app) ────────────────────────────
const _kBg      = Color(0xFF181A1F);
const _kCard    = Color(0xFF1E2028);
const _kGold    = Color(0xFFD4AF37);
const _kGoldL   = Color(0xFFEDD56A);
const _kGoldDim = Color(0xFF3A2E0A);
const _kWhite   = Colors.white;
const _kSec     = Color(0xFFAAAAAA);
const _kDiv     = Color(0xFF2A2A2D);
const _kRed     = Color(0xFFFF4444); // warna highlight query

// ── Model index ayat ─────────────────────────────────────────────
class _AyatIdx {
  final int s;    // surahNum
  final int a;    // ayatNum
  final String l; // surahLatin
  final String n; // surahArab
  final String q; // arabStripped (tanpa harakat — untuk search)
  final String t; // transSnippet
  const _AyatIdx(this.s, this.a, this.l, this.n, this.q, this.t);
}

// ── Entry point screen ───────────────────────────────────────────
class TafsirScreen extends StatefulWidget {
  const TafsirScreen({super.key});

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  // Index
  List<_AyatIdx>? _index;
  bool _indexLoading = true;
  String _indexError = '';

  // Search — simpan query yg sudah distrip untuk highlight
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  List<_AyatIdx> _suggestions  = [];
  bool _showSuggestions = false;
  String _activeQuery = ''; // query terakhir untuk highlight

  // Tafsir result
  _AyatIdx? _selectedAyat;
  int? _selectedKitabId;
  String _selectedKitabName = 'Kemenag';
  String? _tafsirText;
  bool _tafsirLoading = false;

  static const _kitabs = [
    {'id': null, 'name': 'Kemenag'},
    {'id': 14,   'name': 'Ibn Kathir'},
    {'id': 15,   'name': 'Al-Thabari'},
    {'id': 16,   'name': 'Muyassar'},
    {'id': 90,   'name': 'Al-Qurthubi'},
    {'id': 91,   'name': "Al-Sa'di"},
    {'id': 93,   'name': 'Al-Wasith'},
    {'id': 94,   'name': 'Al-Baghawi'},
  ];

  // ── Strip harakat ────────────────────────────────────────────
  static String _strip(String s) => s
      .replaceAll(RegExp(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u0670\u06DF-\u06E4\u06EA-\u06ED]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  void initState() {
    super.initState();
    _loadIndex();
    _searchCtrl.addListener(_onSearchChanged);

    // FIX: delay sebelum sembunyikan suggestions agar tap sempat terdaftar
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Load JSON index ──────────────────────────────────────────
  Future<void> _loadIndex() async {
    try {
      final raw = await rootBundle.loadString('assets/quran_index.json');
      final list = (jsonDecode(raw) as List).map((e) => _AyatIdx(
        e['s'] as int,
        e['a'] as int,
        e['l'] as String,
        e['n'] as String,
        e['q'] as String,
        e['t'] as String,
      )).toList();
      if (mounted) setState(() { _index = list; _indexLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _indexLoading = false; _indexError = e.toString(); });
    }
  }

  // ── Search handler ───────────────────────────────────────────
  void _onSearchChanged() {
    final raw = _searchCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; _activeQuery = ''; });
      return;
    }
    final queryStripped = _strip(raw).toLowerCase();
    final queryLatin    = raw.toLowerCase();
    final idx = _index;
    if (idx == null) return;

    // Cari: Arab stripped, terjemahan, nama surah latin, nama Arab
    final results = idx.where((e) {
      return e.q.contains(queryStripped) ||
             e.t.toLowerCase().contains(queryLatin) ||
             e.l.toLowerCase().contains(queryLatin) ||
             e.n.contains(raw);
    }).take(12).toList();

    setState(() {
      _suggestions   = results;
      _showSuggestions = results.isNotEmpty;
      _activeQuery   = queryStripped; // simpan untuk highlight
    });
  }

  void _selectAyat(_AyatIdx ayat) {
    _searchCtrl.text = 'QS. ${ayat.l} (${ayat.s}): Ayat ${ayat.a}';
    _searchFocus.unfocus();
    setState(() {
      _selectedAyat      = ayat;
      _showSuggestions   = false;
      _tafsirText        = null;
      _selectedKitabId   = null;
      _selectedKitabName = 'Kemenag';
    });
    _fetchTafsir(null);
  }

  // ── Fetch tafsir ─────────────────────────────────────────────
  Future<void> _fetchTafsir(int? tafsirId) async {
    final ayat = _selectedAyat;
    if (ayat == null) return;
    setState(() { _tafsirLoading = true; _tafsirText = null; });
    try {
      String? result;
      if (tafsirId == null) {
        // FIX: Kemenag → gunakan equran.id (terjemahan Kemenag langsung dari API)
        result = await ApiService.getTafsirIndo(ayat.s, ayat.a);
      } else {
        result = await ApiService.getTafsirArab(tafsirId, ayat.s, ayat.a);
      }
      if (mounted) setState(() { _tafsirText = result; _tafsirLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _tafsirLoading = false; });
    }
  }

  void _copyTafsir() {
    final ayat = _selectedAyat;
    if (ayat == null || _tafsirText == null) return;
    Clipboard.setData(ClipboardData(text:
      '${ayat.q}\n\nTafsir $_selectedKitabName:\n$_tafsirText\n\n'
      '(QS. ${ayat.l} ${ayat.s}:${ayat.a})'
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Tafsir disalin!', style: TextStyle(color: Colors.black87)),
      backgroundColor: _kGold,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Helper: highlight query dalam teks ───────────────────────
  // Mengembalikan RichText dengan bagian yang cocok berwarna merah
  Widget _highlighted(
    String text,
    String query, {
    TextStyle? baseStyle,
    TextDirection dir = TextDirection.ltr,
    int maxLines = 3,
  }) {
    final base = baseStyle ?? const TextStyle(color: _kSec, fontSize: 11);
    if (query.isEmpty) {
      return Text(text, style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis,
        textDirection: dir);
    }

    // Cari posisi query (case-insensitive)
    final lower     = text.toLowerCase();
    final queryLow  = query.toLowerCase();
    final spans     = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(queryLow, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: base));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: base.copyWith(color: _kRed, fontWeight: FontWeight.bold),
      ));
      start = idx + query.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textDirection: dir,
      text: TextSpan(children: spans),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _indexLoading
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_kGold)),
            SizedBox(height: 16),
            Text('Memuat indeks Al-Quran...', style: TextStyle(color: _kSec)),
          ]))
        : _indexError.isNotEmpty
          ? _buildError()
          : _buildBody(),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: _kCard,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kGoldL),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Tafsir Al-Quran',
      style: TextStyle(color: _kGoldL, fontWeight: FontWeight.bold, fontSize: 16)),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _kGold.withValues(alpha: 0.15)),
    ),
  );

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.warning_amber_rounded, color: _kSec, size: 48),
      const SizedBox(height: 12),
      const Text('Gagal memuat indeks ayat.', style: TextStyle(color: _kWhite, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Pastikan assets/quran_index.json sudah ada.',
        style: TextStyle(color: _kSec, fontSize: 12),
        textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () { setState(() { _indexLoading = true; _indexError = ''; }); _loadIndex(); },
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Coba Lagi'),
        style: ElevatedButton.styleFrom(backgroundColor: _kGoldDim, foregroundColor: _kGoldL),
      ),
    ]),
  ));

  Widget _buildBody() => Column(children: [
    // ── Search area ──────────────────────────────────────────
    Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGold.withValues(alpha: 0.35)),
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            style: const TextStyle(color: _kWhite, fontSize: 14),
            cursorColor: _kGold,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari: nama surah, teks Arab, atau terjemahan...',
              hintStyle: TextStyle(color: _kSec.withValues(alpha: 0.7), fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: _kGoldL, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: _kSec, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _suggestions    = [];
                        _showSuggestions = false;
                        _selectedAyat   = null;
                        _tafsirText     = null;
                        _activeQuery    = '';
                      });
                    })
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            ),
          ),
        ),

        // ── Suggestions dropdown ──────────────────────────────
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(color: _kDiv, height: 1),
              itemBuilder: (_, i) {
                final e = _suggestions[i];
                final q = _activeQuery; // query untuk highlight
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectAyat(e),
                    highlightColor: _kGoldDim,
                    splashColor: _kGold.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Badge nomor ayat
                        Container(
                          width: 38, height: 38,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: _kGoldDim,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text('${e.a}',
                            style: const TextStyle(color: _kGoldL, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nama surah — highlight jika query Latin cocok
                            _highlighted(
                              'QS. ${e.l} (${e.s}) : Ayat ${e.a}',
                              e.l.toLowerCase().contains(q) || e.l.toLowerCase().contains(_strip(q)) ? q : '',
                              baseStyle: const TextStyle(
                                color: _kGoldL, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            // ── Teks Arab — tampilkan bukan terjemahan
                            _highlighted(
                              e.q, // Arab tanpa harakat
                              q,
                              baseStyle: GoogleFonts.amiri(
                                color: _kWhite, fontSize: 16, height: 1.8),
                              dir: TextDirection.rtl,
                              maxLines: 2,
                            ),
                          ],
                        )),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ]),
    ),

    // ── Tafsir Content ───────────────────────────────────────
    Expanded(
      child: _selectedAyat == null
        ? _buildPlaceholder()
        : _buildTafsirView(),
    ),
  ]);

  Widget _buildPlaceholder() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _kGoldDim,
            shape: BoxShape.circle,
            border: Border.all(color: _kGold.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Icon(Icons.auto_stories_outlined, color: _kGoldL, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('Tafsir Al-Quran',
          style: TextStyle(color: _kWhite, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          'Cari ayat di kolom pencarian di atas.\nBisa mencari dengan teks Arab (tanpa harakat), terjemahan Indonesia, atau nama surah.',
          style: TextStyle(color: _kSec.withValues(alpha: 0.8), fontSize: 13, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _exampleChip('Al-Fatihah'),
          _exampleChip('baqarah'),
          _exampleChip('يس'),
          _exampleChip('petunjuk'),
        ]),
      ]),
    ),
  );

  Widget _exampleChip(String label) => GestureDetector(
    onTap: () {
      _searchCtrl.text = label;
      _searchFocus.requestFocus();
      _onSearchChanged();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _kGoldDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: const TextStyle(color: _kGoldL, fontSize: 12)),
    ),
  );

  Widget _buildTafsirView() {
    final ayat = _selectedAyat!;
    return ListView(children: [
      // ── Ayat Header Card ──────────────────────────────────
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGold.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGoldDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGold.withValues(alpha: 0.4)),
              ),
              child: Text('QS. ${ayat.l} : ${ayat.a}',
                style: const TextStyle(color: _kGoldL, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Text(ayat.n,
              style: GoogleFonts.amiri(color: _kGoldL, fontSize: 18)),
          ]),
          const SizedBox(height: 14),
          // Teks Arab (stripped, tanpa harakat)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              ayat.q,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(fontSize: 22, color: _kWhite, height: 2.1),
            ),
          ),
          const SizedBox(height: 10),
          if (ayat.t.isNotEmpty)
            Text('"${ayat.t}"',
              style: TextStyle(color: _kSec.withValues(alpha: 0.9), fontSize: 13, height: 1.6,
                fontStyle: FontStyle.italic)),
        ]),
      ),

      // ── Pilihan Kitab ─────────────────────────────────────
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Text('Pilih Kitab Tafsir',
          style: TextStyle(color: _kSec.withValues(alpha: 0.7), fontSize: 12, letterSpacing: 0.5)),
      ),
      SizedBox(
        height: 46,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _kitabs.length,
          itemBuilder: (_, i) {
            final k   = _kitabs[i];
            final kId = k['id'] as int?;
            final kNm = k['name'] as String;
            final sel = _selectedKitabId == kId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(kNm),
                selected: sel,
                onSelected: (_) {
                  setState(() { _selectedKitabId = kId; _selectedKitabName = kNm; });
                  _fetchTafsir(kId);
                },
                selectedColor: _kGold,
                backgroundColor: _kCard,
                labelStyle: TextStyle(
                  color: sel ? Colors.black : _kSec,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(color: sel ? _kGold : _kDiv),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                showCheckmark: false,
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 12),
      const Divider(color: _kDiv, indent: 16, endIndent: 16),
      const SizedBox(height: 8),

      // ── Teks Tafsir ───────────────────────────────────────
      _tafsirLoading
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_kGold))),
          )
        : _tafsirText == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(children: [
                const Icon(Icons.info_outline, color: _kSec, size: 32),
                const SizedBox(height: 8),
                Text('Tafsir $_selectedKitabName tidak tersedia untuk ayat ini.',
                  style: const TextStyle(color: _kSec, fontSize: 13),
                  textAlign: TextAlign.center),
              ]),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_stories, color: _kGoldL, size: 16),
                  const SizedBox(width: 6),
                  Text('Tafsir $_selectedKitabName',
                    style: const TextStyle(color: _kGoldL, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _copyTafsir,
                    icon: const Icon(Icons.copy_outlined, size: 14),
                    label: const Text('Salin', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: _kGoldL),
                  ),
                ]),
                const SizedBox(height: 10),
                SelectableText(
                  _tafsirText!,
                  style: const TextStyle(color: _kWhite, fontSize: 14.5, height: 1.9),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: const Text('Salin Arab + Tafsir'),
                    onPressed: _copyTafsir,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kGoldL,
                      side: const BorderSide(color: _kGold),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
    ]);
  }
}
