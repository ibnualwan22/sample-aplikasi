import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/markaz_theme.dart';
import '../widgets/markaz_components.dart';
import '../services/api_service.dart';

class _AyatIndex {
  final int surah, ayah;
  final String name, arabicName, searchText, snippet;
  _AyatIndex(Map<String, dynamic> item)
      : surah = item['s'] as int,
        ayah = item['a'] as int,
        name = item['l'] as String,
        arabicName = item['n'] as String,
        searchText = item['q'] as String,
        snippet = item['t'] as String;
  String get reference => 'QS. $name $surah:$ayah';
}

class TafsirScreen extends StatefulWidget {
  final int? initialSurah;
  final int? initialAyah;
  const TafsirScreen({super.key, this.initialSurah, this.initialAyah});
  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  List<_AyatIndex> _index = [];
  List<_AyatIndex> _results = [];
  bool _indexLoading = true, _indexFailed = false;
  _AyatIndex? _selected;
  Map<String, dynamic>? _verse;
  String? _tafsir;
  bool _verseLoading = false, _tafsirLoading = false;
  int _source = 0, _verseRequest = 0, _tafsirRequest = 0;
  double _arabicSize = 28;
  static const _sources = [
    {'id': 0, 'name': 'Kemenag', 'language': 'Indonesia'},
    ...kTafsirArab,
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(_find);
    _loadIndex();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadIndex() async {
    setState(() {
      _indexLoading = true;
      _indexFailed = false;
    });
    try {
      final raw = await rootBundle.loadString('assets/quran_index.json');
      final entries = (jsonDecode(raw) as List)
          .map((e) => _AyatIndex(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _index = entries;
        _indexLoading = false;
      });
      _find();
      if (widget.initialSurah != null && _selected == null) {
        final matches = entries.where((e) =>
            e.surah == widget.initialSurah &&
            e.ayah == (widget.initialAyah ?? 1));
        if (matches.isNotEmpty) _select(matches.first);
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _indexLoading = false;
          _indexFailed = true;
        });
    }
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(
          RegExp(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED\u0670]'), '')
      .replaceAll(RegExp(r"[\s'’‘-]"), '');

  void _find() {
    final raw = _search.text.trim();
    final reference = RegExp(r'^(\d{1,3})\s*[:/]\s*(\d{1,3})$').firstMatch(raw);
    final query = _normalize(raw);
    setState(() {
      _results = query.isEmpty
          ? []
          : _index.where((e) {
              if (reference != null)
                return e.surah == int.parse(reference[1]!) &&
                    e.ayah == int.parse(reference[2]!);
              if (int.tryParse(raw) != null) return e.surah == int.parse(raw);
              return _normalize(e.name).contains(query) ||
                  _normalize(e.arabicName).contains(query) ||
                  _normalize(e.searchText).contains(query) ||
                  _normalize(e.snippet).contains(query);
            }).toList();
    });
  }

  void _select(_AyatIndex entry) {
    FocusManager.instance.primaryFocus?.unfocus();
    _search.clear();
    setState(() {
      _selected = entry;
      _verse = null;
      _tafsir = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _loadVerse();
    _loadTafsir();
  }

  Future<void> _loadVerse() async {
    final entry = _selected!;
    final request = ++_verseRequest;
    setState(() {
      _verseLoading = true;
      _verse = null;
    });
    Map<String, dynamic>? verse;
    try {
      final surah = await ApiService.getSurahDetail(entry.surah)
          .timeout(const Duration(seconds: 20));
      final matches = (surah?['ayahs'] as List? ?? [])
          .where((a) => a['ayah_number'] == entry.ayah);
      if (matches.isNotEmpty)
        verse = Map<String, dynamic>.from(matches.first as Map);
    } catch (_) {}
    if (!mounted || request != _verseRequest) return;
    setState(() {
      _verse = verse;
      _verseLoading = false;
    });
  }

  Future<void> _loadTafsir() async {
    final entry = _selected!;
    final request = ++_tafsirRequest;
    final source = _source;
    setState(() {
      _tafsirLoading = true;
      _tafsir = null;
    });
    String? text;
    try {
      text = await (source == 0
              ? ApiService.getTafsirIndo(entry.surah, entry.ayah)
              : ApiService.getTafsirArab(source, entry.surah, entry.ayah))
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
    if (!mounted || request != _tafsirRequest) return;
    setState(() {
      _tafsir = text;
      _tafsirLoading = false;
    });
  }

  Future<void> _pickAyah() async {
    final entry = await showModalBottomSheet<_AyatIndex>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AyahPicker(index: _index, selected: _selected));
    if (mounted && entry != null) _select(entry);
  }

  void _step(int delta) {
    final current = _selected!;
    final matches = _index.where(
        (e) => e.surah == current.surah && e.ayah == current.ayah + delta);
    if (matches.isNotEmpty) _select(matches.first);
  }

  Future<void> _copy() async {
    final reference = _selected!.reference;
    final source = _sources.firstWhere((s) => s['id'] == _source)['name'];
    await Clipboard.setData(
        ClipboardData(text: '$reference\n\nTafsir $source\n$_tafsir'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafsir dan rujukan ayat disalin.')));
  }

  @override
  Widget build(BuildContext context) {
    final searching = _search.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Tafsir Al-Qur’an'), actions: [
        if (_selected != null)
          PopupMenuButton<double>(
              tooltip: 'Ukuran teks Arab',
              icon: const Icon(Icons.text_fields),
              onSelected: (size) => setState(() => _arabicSize = size),
              itemBuilder: (_) => [
                    for (final (label, size) in [
                      ('Sedang', 28.0),
                      ('Besar', 32.0),
                      ('Sangat besar', 36.0)
                    ])
                      PopupMenuItem(value: size, child: Text(label))
                  ]),
      ]),
      body: SafeArea(
          top: false,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (_selected == null && !searching) ...[
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: MarkazColors.tint,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_stories_outlined, size: 30),
                          const SizedBox(height: 12),
                          Text('Baca ayat, pahami maknanya',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          const Text(
                              'Temukan ayat, lalu baca penjelasannya dari tafsir Kemenag atau kitab berbahasa Arab.'),
                        ])),
                const SizedBox(height: 24),
              ],
              TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                      labelText: 'Cari ayat atau surah',
                      hintText: 'Contoh: sabar, Al-Fatihah, 2:255',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searching
                          ? IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: _search.clear,
                              icon: const Icon(Icons.close))
                          : null)),
              const SizedBox(height: 8),
              Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                      onPressed:
                          _indexLoading || _indexFailed ? null : _pickAyah,
                      icon: const Icon(Icons.tune, size: 20),
                      label: const Text('Pilih surah & ayat'))),
              if (_indexLoading)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()))
              else if (_indexFailed)
                MarkazState(
                    title: 'Pencarian belum siap',
                    message:
                        'Indeks ayat tidak dapat dibuka. Coba muat kembali.',
                    pose: MascotPose.help,
                    actionLabel: 'Coba lagi',
                    onAction: _loadIndex)
              else if (searching)
                ..._searchResults()
              else if (_selected == null) ...[
                const SizedBox(height: 16),
                Text('Mulai membaca',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _suggestion('Al-Fatihah', 'Surah pembuka • Ayat 1', 1, 1),
                _suggestion('Ayat Kursi', 'Al-Baqarah • Ayat 255', 2, 255),
                _suggestion('Al-Ikhlas', 'Surah ke-112 • Ayat 1', 112, 1),
                const SizedBox(height: 16),
                const Text(
                    'Pencarian tersedia tanpa internet. Isi ayat yang belum tersimpan dan tafsir memerlukan koneksi.',
                    style: TextStyle(color: MarkazColors.muted, fontSize: 12)),
              ] else
                ..._reading(),
            ],
          )),
    );
  }

  Widget _suggestion(String title, String subtitle, int surah, int ayah) =>
      Card(
          child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _select(_index
                  .firstWhere((e) => e.surah == surah && e.ayah == ayah))));

  List<Widget> _searchResults() => [
        const SizedBox(height: 12),
        if (_results.isEmpty)
          MarkazState(
              title: 'Ayat tidak ditemukan',
              message: 'Coba kata lain atau pilih nomor surah dan ayat.',
              pose: MascotPose.empty,
              actionLabel: 'Pilih surah & ayat',
              onAction: _pickAyah)
        else ...[
          Text(
              '${_results.length} ayat ditemukan${_results.length > 20 ? ' • 20 ditampilkan' : ''}',
              style: const TextStyle(color: MarkazColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          for (final entry in _results.take(20))
            Card(
                child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(entry.reference,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(entry.snippet,
                            maxLines: 3, overflow: TextOverflow.ellipsis)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _select(entry))),
          if (_results.length > 20)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                    'Persempit kata pencarian atau gunakan nomor seperti 2:255.')),
        ],
      ];

  List<Widget> _reading() {
    final entry = _selected!;
    final last = _index.lastWhere((e) => e.surah == entry.surah).ayah;
    return [
      const SizedBox(height: 8),
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: MarkazColors.tint,
              borderRadius: BorderRadius.circular(16)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(entry.reference,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Ayat ${entry.ayah} dari $last',
                style:
                    const TextStyle(color: MarkazColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                      onPressed: entry.ayah == 1 ? null : () => _step(-1),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Sebelumnya')),
                  FilledButton.icon(
                      onPressed: entry.ayah == last ? null : () => _step(1),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Berikutnya')),
                ]),
          ])),
      const SizedBox(height: 24),
      if (_verseLoading)
        const LinearProgressIndicator(semanticsLabel: 'Memuat ayat')
      else if (_verse == null)
        _retry('Teks ayat belum dapat dimuat.', _loadVerse)
      else ...[
        SelectableText('${_verse!['arab']}',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontFamily: 'Amiri', fontSize: _arabicSize, height: 2)),
        const SizedBox(height: 20),
        const Text('TERJEMAHAN',
            style: TextStyle(
                color: MarkazColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        SelectableText('${_verse!['translation']}',
            style: const TextStyle(fontSize: 15, height: 1.8)),
      ],
      const Divider(height: 40),
      Text('Penjelasan ayat', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
          key: ValueKey(_source),
          initialValue: _source,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Sumber tafsir',
              prefixIcon: Icon(Icons.menu_book_outlined)),
          items: [
            for (final source in _sources)
              DropdownMenuItem(
                  value: source['id'] as int,
                  child: Text('${source['name']}',
                      maxLines: 1, overflow: TextOverflow.ellipsis))
          ],
          onChanged: (source) {
            if (source == null || source == _source) return;
            setState(() => _source = source);
            _loadTafsir();
          }),
      const SizedBox(height: 8),
      Text(
          _source == 0
              ? 'Bahasa Indonesia • Kemenag melalui EQuran.id'
              : 'Bahasa Arab • melalui Quran.com',
          style: const TextStyle(color: MarkazColors.muted, fontSize: 12)),
      const SizedBox(height: 20),
      if (_tafsirLoading)
        const LinearProgressIndicator(semanticsLabel: 'Memuat tafsir')
      else if (_tafsir == null || _tafsir!.isEmpty)
        _retry(
            'Tafsir belum dapat dimuat. Periksa koneksi atau pilih sumber lain.',
            _loadTafsir)
      else ...[
        SelectableText(_tafsir!,
            textDirection: _source == 0 ? TextDirection.ltr : TextDirection.rtl,
            style: TextStyle(
                fontFamily: _source == 0 ? 'Roboto' : 'Amiri',
                fontSize: _source == 0 ? 16 : _arabicSize,
                height: _source == 0 ? 1.85 : 2)),
        const SizedBox(height: 16),
        Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Salin tafsir'))),
      ],
    ];
  }

  Widget _retry(String message, VoidCallback retry) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: MarkazColors.ivory,
          border: Border.all(color: MarkazColors.line),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.wifi_off_outlined),
        const SizedBox(height: 8),
        Text(message),
        TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi')),
      ]));
}

class _AyahPicker extends StatefulWidget {
  final List<_AyatIndex> index;
  final _AyatIndex? selected;
  const _AyahPicker({required this.index, this.selected});
  @override
  State<_AyahPicker> createState() => _AyahPickerState();
}

class _AyahPickerState extends State<_AyahPicker> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _ayah;
  late int _surah;
  @override
  void initState() {
    super.initState();
    _surah = widget.selected?.surah ?? 1;
    _ayah = TextEditingController(text: '${widget.selected?.ayah ?? 1}');
  }

  @override
  void dispose() {
    _ayah.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.index.lastWhere((e) => e.surah == _surah).ayah;
    return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 +
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom),
        child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MarkazDialogTitle('Pilih ayat',
                      icon: Icons.auto_stories_outlined),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                      initialValue: _surah,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Surah'),
                      items: [
                        for (final entry
                            in widget.index.where((e) => e.ayah == 1))
                          DropdownMenuItem(
                              value: entry.surah,
                              child: Text('${entry.surah}. ${entry.name}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _surah = value;
                          _ayah.text = '1';
                        });
                      }),
                  const SizedBox(height: 20),
                  TextFormField(
                      controller: _ayah,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                          labelText: 'Nomor ayat', helperText: 'Ayat 1–$max'),
                      validator: (value) {
                        final number = int.tryParse(value ?? '');
                        return number == null || number < 1 || number > max
                            ? 'Masukkan ayat antara 1 dan $max.'
                            : null;
                      }),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        Navigator.pop(
                            context,
                            widget.index.firstWhere((e) =>
                                e.surah == _surah &&
                                e.ayah == int.parse(_ayah.text)));
                      },
                      child: const Text('Baca tafsir')),
                ])));
  }
}
