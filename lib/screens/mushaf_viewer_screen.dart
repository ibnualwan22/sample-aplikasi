import '../theme/markaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/quran_pages.dart';
import '../services/quran_image_cache_manager.dart';

const _kGold = MarkazColors.gold;
const _kGoldLight = MarkazColors.ink;
const _kGoldDim = MarkazColors.tint;
const _kTextSec = MarkazColors.muted;
const _kBgCard2 = MarkazColors.ivory;

class MushafViewerScreen extends StatefulWidget {
  final int initialPage;
  const MushafViewerScreen({super.key, this.initialPage = 1});

  @override
  State<MushafViewerScreen> createState() => _MushafViewerScreenState();
}

class _MushafViewerScreenState extends State<MushafViewerScreen> {
  late final PageController _ctrl;
  late int _currentPage;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, kTotalMushafPages);
    // Animasi kertas (paper_curl) DIHAPUS 11 Nov 2026 atas perintah user:
    // sulit di-RTL-kan (cermin ganda + indeks terbalik, arah lipat tak
    // kunjung benar) — dikerjakan lagi kapan-kapan. Penggantinya PageView
    // polos dengan reverse: true — halaman 0 di kanan, geser kiri =
    // halaman berikut, persis arah baca mushaf. Tanpa cermin, tanpa
    // indeks terbalik: indeks widget i = halaman mushaf (i + 1).
    _ctrl = PageController(initialPage: _currentPage - 1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _precache(int currentPage) {
    for (final d in [-2, -1, 1, 2]) {
      final p = currentPage + d;
      if (p >= 1 && p <= kTotalMushafPages) {
        precacheImage(NetworkImage(mushafPageUrl(p)), context);
      }
    }
  }

  void _goToPage(int page) {
    final p = page.clamp(1, kTotalMushafPages);
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.jumpToPage(p - 1);
    } else if (p == _currentPage + 1) {
      // Satu halaman maju (di PageView reverse, ini geser ke kiri).
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    } else if (p == _currentPage - 1) {
      _ctrl.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    } else {
      _ctrl.jumpToPage(p - 1);
    }
  }

  void _showJumpDialog() {
    String answer = '$_currentPage';
    final form = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        backgroundColor: _kBgCard2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lompat ke Halaman',
            style: TextStyle(color: _kGoldLight)),
        content: Form(
            key: form,
            child: TextFormField(
              initialValue: answer,
              onChanged: (v) => answer = v,
              validator: (v) {
                final page = int.tryParse(v ?? '');
                return page == null || page < 1 || page > kTotalMushafPages
                    ? 'Masukkan halaman 1–$kTotalMushafPages.'
                    : null;
              },
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MarkazColors.ink, fontSize: 20),
              decoration: InputDecoration(
                hintText: '1 – $kTotalMushafPages',
                hintStyle: const TextStyle(color: _kTextSec),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: _kGold.withValues(alpha: 0.4))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MarkazColors.ink)),
              ),
            )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: _kTextSec))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              if (!form.currentState!.validate()) return;
              final p = int.parse(answer);
              Navigator.pop(context);
              _goToPage(p);
            },
            child: const Text('Pergi',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahNum = getSurahForPage(_currentPage);
    final juzNum = getJuzForPage(_currentPage);
    final surahName = surahNamesLatin[surahNum];

    return Scaffold(
      backgroundColor: MarkazColors.ivory,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          children: [
            // ── PageView polos (tanpa animasi kertas): geser kiri =
            // halaman berikut (RTL via reverse). Animasi curl dihapus
            // 11 Nov — dikerjakan lagi kapan-kapan.
            PageView.builder(
              controller: _ctrl,
              reverse: true,
              itemCount: kTotalMushafPages,
              onPageChanged: (i) {
                final page = i + 1;
                setState(() => _currentPage = page);
                _precache(page);
              },
              itemBuilder: (context, index) => _buildPage(index + 1),
            ),

            // ── Overlay ──────────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: Duration(
                  milliseconds:
                      MediaQuery.disableAnimationsOf(context) ? 0 : 180),
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopBar(surahName, juzNum),
                    _buildBottomBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int pageNum) {
    final url = mushafPageUrl(pageNum);
    return Container(
      color: MarkazColors.ivory,
      child: CachedNetworkImage(
        imageUrl: url,
        cacheManager: QuranImageCacheManager.instance,
        fit: BoxFit.contain,
        // Loading
        progressIndicatorBuilder: (context, url, progress) {
          final pct = progress.progress;
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: pct,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kGold),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                pct != null
                    ? 'Memuat ${(pct * 100).toInt()}%'
                    : 'Memuat halaman $pageNum...',
                style: const TextStyle(color: _kTextSec, fontSize: 13),
              ),
            ]),
          );
        },
        // Error
        errorWidget: (context, url, error) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.signal_wifi_off_rounded,
                color: _kTextSec, size: 52),
            const SizedBox(height: 10),
            Text('Halaman $pageNum belum di-cache',
                style: const TextStyle(color: _kTextSec, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Butuh koneksi internet untuk pertama kali',
                style: TextStyle(color: _kTextSec, fontSize: 11)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kGoldDim,
                  foregroundColor: _kGoldLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar(String surahName, int juzNum) {
    return Container(
      decoration: BoxDecoration(
        color: MarkazColors.surface,
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 24),
      child: Row(children: [
        // Tombol kembali
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MarkazColors.tint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGold.withValues(alpha: 0.4)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.arrow_back_ios_new, color: _kGoldLight, size: 14),
              SizedBox(width: 6),
              Text('Kembali',
                  style: TextStyle(color: _kGoldLight, fontSize: 12)),
            ]),
          ),
        ),
        const Spacer(),
        // Info surah & juz
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(surahName,
              style: const TextStyle(
                  color: _kGoldLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          Text('Juz $juzNum  ·  Hal. $_currentPage / $kTotalMushafPages',
              style: const TextStyle(color: _kTextSec, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: MarkazColors.surface,
      ),
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, MediaQuery.of(context).padding.bottom + 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol next (kiri = halaman berikutnya, RTL: maju ke kiri)
          _navBtn(
            Icons.chevron_left,
            enabled: _currentPage < kTotalMushafPages,
            onTap: () => _goToPage(_currentPage + 1),
          ),
          // Lompat ke halaman
          GestureDetector(
            onTap: _showJumpDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: _kGoldDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGold.withValues(alpha: 0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.swap_vert, color: _kGoldLight, size: 14),
                const SizedBox(width: 6),
                Text('Halaman $_currentPage',
                    style: const TextStyle(
                        color: _kGoldLight,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          // Tombol prev (kanan = halaman sebelumnya, RTL: mundur ke kanan)
          _navBtn(
            Icons.chevron_right,
            enabled: _currentPage > 1,
            onTap: () => _goToPage(_currentPage - 1),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon,
      {required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MarkazColors.tint,
            shape: BoxShape.circle,
            border: Border.all(color: _kGold.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: _kGoldLight, size: 26),
        ),
      ),
    );
  }
}
