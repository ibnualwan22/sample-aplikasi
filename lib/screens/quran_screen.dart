import 'package:flutter/material.dart';
import '../widgets/markaz_components.dart';
import '../theme/markaz_theme.dart';
import '../services/api_service.dart';
import '../services/quran_image_cache_manager.dart';
import '../data/quran_pages.dart';
import 'surah_detail_screen.dart';
import 'mushaf_viewer_screen.dart';

const _kCard2 = MarkazColors.ivory;
const _kGoldL = MarkazColors.ink;
const _kSec = MarkazColors.muted;
const _kDiv = MarkazColors.line;

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<dynamic> _surahs = [];
  bool _loading = true;
  bool _byJuz = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _search.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    List<dynamic>? list;
    try {
      list = await ApiService.getSurahList();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _surahs = list ?? [];
      _loading = false;
    });
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r"[\s'’‘-]"), '')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

  bool _matches(String name, String arabic, int number) {
    final query = _normalize(_search.text);
    if (query.isEmpty) return true;
    if (int.tryParse(query) != null) return number.toString() == query;
    return _normalize(name).contains(query) ||
        _normalize(arabic).contains(query);
  }

  Future<void> _download() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              scrollable: true,
              title: const MarkazDialogTitle('Simpan mushaf',
                  icon: Icons.download_outlined),
              content: const Text(
                  'Unduh 604 halaman agar mushaf dapat dibaca tanpa internet. Gunakan koneksi yang stabil. Halaman yang sudah tersimpan akan dilewati.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Nanti')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Mulai unduh')),
              ],
            ));
    if (!mounted || confirmed != true) return;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _DownloadMushafDialog());
  }

  @override
  Widget build(BuildContext context) {
    final surahs = _surahs
        .where((s) =>
            _matches('${s['name_latin']}', '${s['name']}', s['number'] as int))
        .toList();
    final juz = List.generate(30, (i) => i + 1).where((j) {
      final query = _normalize(_search.text).replaceFirst(RegExp(r'^juz'), '');
      if (query.isEmpty) return true;
      if (int.tryParse(query) != null) return j.toString() == query;
      return _normalize(
              '${juzNames[j]} ${surahNamesLatin[getSurahForPage(juzStartPage[j])]}')
          .contains(query);
    }).toList();
    final count = _byJuz ? juz.length : surahs.length;
    return Scaffold(
      appBar: AppBar(title: const Text("Al-Qur’an")),
      body: SafeArea(
          top: false,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  sliver: SliverToBoxAdapter(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: MarkazColors.tint,
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 30),
                                const SizedBox(height: 12),
                                Text('Ruang untuk membaca',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                const SizedBox(height: 8),
                                const Text(
                                    'Pilih surah untuk membaca ayat dan terjemahan, atau buka tampilan mushaf.'),
                                const SizedBox(height: 16),
                                Wrap(spacing: 8, runSpacing: 4, children: [
                                  FilledButton.icon(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const MushafViewerScreen())),
                                      icon: const Icon(
                                          Icons.auto_stories_outlined,
                                          size: 20),
                                      label: const Text('Buka mushaf')),
                                  TextButton.icon(
                                      onPressed: _download,
                                      icon: const Icon(Icons.download_outlined,
                                          size: 20),
                                      label: const Text('Unduh')),
                                ]),
                              ])),
                      const SizedBox(height: 24),
                      TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                              labelText: _byJuz ? 'Cari juz' : 'Cari surah',
                              hintText: _byJuz
                                  ? 'Nomor juz atau surah awal'
                                  : 'Nama atau nomor surah',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Hapus pencarian',
                                      onPressed: _search.clear,
                                      icon: const Icon(Icons.close)))),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ChoiceChip(
                            label: const Text('Per Surah'),
                            selected: !_byJuz,
                            onSelected: (_) => setState(() => _byJuz = false)),
                        ChoiceChip(
                            label: const Text('Per Juz'),
                            selected: _byJuz,
                            onSelected: (_) => setState(() => _byJuz = true)),
                      ]),
                      const SizedBox(height: 12),
                      if (!_loading || _byJuz)
                        Text(
                            '$count ${_byJuz ? 'juz' : 'surah'}${_search.text.trim().isEmpty ? '' : ' ditemukan'}',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ))),
              if (_loading && !_byJuz)
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator())))
              else if (count == 0)
                SliverToBoxAdapter(
                    child: MarkazState(
                        title: !_byJuz && _surahs.isEmpty
                            ? 'Surah belum dapat dimuat'
                            : 'Tidak ditemukan',
                        message: !_byJuz && _surahs.isEmpty
                            ? 'Periksa koneksi lalu coba lagi. Mushaf yang sudah diunduh tetap dapat dibuka.'
                            : 'Coba nama atau nomor yang lain.',
                        pose: !_byJuz && _surahs.isEmpty
                            ? MascotPose.help
                            : MascotPose.empty,
                        actionLabel: !_byJuz && _surahs.isEmpty
                            ? 'Coba lagi'
                            : 'Hapus pencarian',
                        onAction: !_byJuz && _surahs.isEmpty
                            ? _fetch
                            : _search.clear))
              else
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.builder(
                        itemCount: count,
                        itemBuilder: (context, i) {
                          if (_byJuz) {
                            final j = juz[i];
                            final start = juzStartPage[j];
                            final end = j < 30
                                ? juzStartPage[j + 1] - 1
                                : kTotalMushafPages;
                            return _entry(
                                number: j,
                                title: 'Juz $j',
                                subtitle: '${juzNames[j]} • Hal. $start–$end',
                                detail:
                                    'Mulai ${surahNamesLatin[getSurahForPage(start)]}',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => MushafViewerScreen(
                                            initialPage: start))));
                          }
                          final s = surahs[i];
                          return _entry(
                              number: s['number'] as int,
                              title: '${s['name_latin']}',
                              subtitle:
                                  '${s['revelation']} • ${s['number_of_ayahs']} ayat',
                              arabic: '${s['name']}',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => SurahDetailScreen(
                                          surahNumber: s['number'] as int,
                                          surahName: '${s['name_latin']}',
                                          surahList: _surahs))));
                        })),
            ],
          )),
    );
  }

  Widget _entry(
          {required int number,
          required String title,
          required String subtitle,
          String? arabic,
          String? detail,
          required VoidCallback onTap}) =>
      Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 44,
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: MarkazColors.gold,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('$number',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: MarkazColors.muted)),
                          if (arabic != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(arabic,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                        fontFamily: 'Amiri', fontSize: 22))),
                          if (detail != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(detail)),
                        ])),
                    const Icon(Icons.chevron_right,
                        size: 20, color: MarkazColors.muted),
                  ],
                ))),
      );
}

class _DownloadMushafDialog extends StatefulWidget {
  const _DownloadMushafDialog();
  @override
  State<_DownloadMushafDialog> createState() => _DownloadMushafDialogState();
}

class _DownloadMushafDialogState extends State<_DownloadMushafDialog> {
  int _progress = 0;
  bool _isDownloading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
    });
    try {
      final cacheManager = QuranImageCacheManager.instance;
      for (int i = 1; i <= kTotalMushafPages; i++) {
        if (!mounted) return;
        final url = mushafPageUrl(i);
        final file = await cacheManager.getFileFromCache(url);
        if (!mounted) return;
        if (file == null) {
          await cacheManager.downloadFile(url);
        }
        if (!mounted) return;
        setState(() => _progress = i);
      }
      if (mounted) setState(() => _isDownloading = false);
    } catch (_) {
      if (mounted)
        setState(() {
          _isDownloading = false;
          _hasError = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = _progress / kTotalMushafPages;
    return AlertDialog(
      scrollable: true,
      backgroundColor: _kCard2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const MarkazDialogTitle('Unduh mushaf',
          icon: Icons.download_outlined),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading) ...[
            const Text('Mengunduh halaman untuk akses offline...',
                style: TextStyle(color: MarkazColors.ink, fontSize: 13)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
                value: pct, color: MarkazColors.ink, backgroundColor: _kDiv),
            const SizedBox(height: 8),
            Text('$_progress / $kTotalMushafPages halaman',
                style: const TextStyle(color: _kSec, fontSize: 12)),
          ] else if (_hasError) ...[
            const Icon(Icons.error_outline,
                color: MarkazColors.danger, size: 48),
            const SizedBox(height: 16),
            const Text('Gagal mengunduh. Periksa koneksi internet Anda.',
                style: TextStyle(color: MarkazColors.ink, fontSize: 13),
                textAlign: TextAlign.center),
          ] else ...[
            const Icon(Icons.check_circle_outline,
                color: MarkazColors.ink, size: 48),
            const SizedBox(height: 16),
            const Text('Mushaf berhasil diunduh dan siap dibaca offline!',
                style: TextStyle(color: MarkazColors.ink, fontSize: 13),
                textAlign: TextAlign.center),
          ]
        ],
      ),
      actions: [
        if (_hasError)
          FilledButton(
              onPressed: _startDownload, child: const Text('Coba lagi')),
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Tutup', style: TextStyle(color: MarkazColors.ink)),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: _kSec)),
          ),
      ],
    );
  }
}
