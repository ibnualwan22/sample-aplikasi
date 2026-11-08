import '../widgets/prayer_schedule_sheet.dart';
import '../widgets/markaz_components.dart';
import 'calendar_screen.dart';
import '../theme/markaz_theme.dart';
import '../siakad/prayer.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../widgets/coming_soon_dialog.dart';
import 'denah_sakan_screen.dart';
import 'article_list_screen.dart';
import 'kiblat_screen.dart';
import 'siakad_portal_screen.dart';
import 'tafsir_screen.dart';
import 'quran_screen.dart';
import 'instagram_grid_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';

// ============================================================
// WARNA TEMA — Putih & Emas
// ============================================================
const kBgDark = MarkazColors.surface;
const kBgCard = MarkazColors.surface;
const kBgCard2 = MarkazColors.ivory;
const kGold = MarkazColors.gold;
const kGoldLight = MarkazColors.ink;
const kGoldDark = MarkazColors.warning;
const kGoldDim = MarkazColors.tint;
const kTextPri = MarkazColors.ink;
const kTextSec = MarkazColors.muted;

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key,
      this.onOpenSiakad,
      this.onOpenResults,
      this.onOpenCalendar,
      this.onOpenQuran});
  final VoidCallback? onOpenSiakad, onOpenResults, onOpenCalendar, onOpenQuran;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentDate = '';
  String _lokasiKota = 'Mencari lokasi...';
  String _nextPrayerName = 'MEMUAT...';
  String _nextPrayerTime = '--:--';
  String _countdownStr = '--:--:--';
  String _currentTime = '';
  bool _isLoading = true;
  double _lat = -7.7613;
  double _lng = 112.1818;

  DateTime? _nextPrayerDt;
  Timer? _timer;

  WebViewController? _elfsightWebViewController;

  final _shorebirdUpdater = ShorebirdUpdater();

  @override
  void initState() {
    super.initState();
    _currentDate =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    _updateClock();
    _determinePosition();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
      _updateClock();
      prayerInfo.value = (
        clock: _currentTime,
        location: _lokasiKota,
        prayer: _nextPrayerName,
        time: _nextPrayerTime,
        countdown: _countdownStr,
        schedule: _openPrayerSchedule,
      );
    });
    _checkForUpdates();

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      _elfsightWebViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) async {
              final url = request.url;

              // Biarkan skrip internal WebView berjalan dengan aman
              if (url.startsWith('data:') || url.contains('elfsightcdn.com')) {
                return NavigationDecision.navigate;
              }

              // Cegat semua tautan ke luar, termasuk intent khusus Android (Instagram)
              Uri uri;
              if (url.startsWith('intent://')) {
                // Konversi Android intent URL kembali ke link web standar
                // Contoh: intent://instagram.com/_u/foo... -> https://instagram.com/_u/foo...
                final cleanStr = url
                    .replaceFirst('intent://', 'https://')
                    .split('#Intent')
                    .first;
                uri = Uri.parse(cleanStr);
              } else {
                uri = Uri.parse(url);
              }

              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Tidak dapat membuka aplikasi Instagram')));
                }
              } catch (e) {
                debugPrint('NavigationError: $e');
              }

              return NavigationDecision
                  .prevent; // Tolak render ke WebView karena kita sudah melemparnya ke Aplikasi!
            },
          ),
        )
        ..loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>body { margin: 0; padding: 0; background-color: #FFFFFF; }</style>
</head>
<body>
  <script src="https://elfsightcdn.com/platform.js" async></script>
  <div class="elfsight-app-6f1e26c4-1501-4e35-9fc8-c7d3ab6c84ad" data-elfsight-app-lazy></div>
</body>
</html>
        ''');
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      if (!_shorebirdUpdater.isAvailable) return;

      final currentPatch = await _shorebirdUpdater.readCurrentPatch();
      final currentVersion = currentPatch?.number ?? 0;

      final status = await _shorebirdUpdater.checkForUpdate();

      if (status == UpdateStatus.outdated && mounted) {
        _showUpdateDialog(context, currentVersion);
      }
    } catch (e) {
      debugPrint('Shorebird error: $e');
    }
  }

  void _showUpdateDialog(BuildContext ctx, int currentVersion) {
    showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
              backgroundColor: kBgCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.system_update_alt, color: MarkazColors.ink),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text('Pembaruan aplikasi',
                          style: TextStyle(
                              color: MarkazColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Terdapat versi pembaruan aplikasi terbaru dari Markaz. (Versi Lama Anda: v$currentVersion)',
                      style: const TextStyle(
                          color: MarkazColors.muted,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 16),
                  const Text('Silakan unduh untuk memperbarui.',
                      style: TextStyle(
                          color: kGoldLight,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Nanti Saja',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (ctx.mounted)
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text(
                              'Mengunduh Pembaruan di Latar Belakang...')));
                    try {
                      await _shorebirdUpdater.update();
                      if (ctx.mounted) {
                        showDialog(
                          context: ctx,
                          builder: (_) => AlertDialog(
                            backgroundColor: kBgCard,
                            title: const Text('Berhasil Diunduh!',
                                style: TextStyle(color: MarkazColors.ink)),
                            content: const Text(
                                'Silakan tutup aplikasi ini sepenuhnya (Hapus dari Recent Apps) dan buka Google/Aplikasi kembali untuk menikmati fitur baru!',
                                style: TextStyle(color: MarkazColors.muted)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Mengerti',
                                      style:
                                          TextStyle(color: MarkazColors.ink)))
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted)
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Gagal mengunduh pembaruan.')));
                    }
                  },
                  child: const Text('Unduh Sekarang',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ));
  }

  void _openPrayerSchedule() {
    if (mounted) _showJadwalDialog(context);
  }

  void _updateClock() {
    final str = DateFormat('HH:mm').format(DateTime.now());
    if (mounted && _currentTime != str) {
      final date =
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
      _currentTime = str;
      if (date != _currentDate) setState(() => _currentDate = date);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    prayerInfo.value = (
      clock: prayerInfo.value.clock,
      location: prayerInfo.value.location,
      prayer: prayerInfo.value.prayer,
      time: prayerInfo.value.time,
      countdown: prayerInfo.value.countdown,
      schedule: null
    );
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────
  Future<void> _determinePosition() async {
    try {
      bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        if (mounted) setState(() => _lokasiKota = 'Tulungrejo, Pare (GPS Off)');
        _calcPrayer();
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        final lbl =
            perm == LocationPermission.deniedForever ? 'Diblokir' : 'Ditahan';
        if (mounted) setState(() => _lokasiKota = 'Tulungrejo, Pare ($lbl)');
        _calcPrayer();
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted)
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}';
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'SigmaApp/1.0'});
      if (res.statusCode == 200 && mounted) {
        final addr =
            (jsonDecode(res.body)['address'] as Map<String, dynamic>?) ?? {};
        final v = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'];
        final d = addr['city_district'] ?? addr['county'] ?? addr['district'];
        final c = addr['city'] ??
            addr['town'] ??
            addr['municipality'] ??
            addr['state_district'];
        final parts = [v, d, c]
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .toSet()
            .toList();
        setState(() => _lokasiKota =
            parts.isNotEmpty ? parts.join(', ') : 'Lokasi Terdeteksi');
      } else if (mounted) {
        setState(() => _lokasiKota = 'Lokasi Terdeteksi');
      }
    } catch (_) {
      if (mounted)
        setState(() => _lokasiKota = 'Tulungrejo, Pare (lokasi bawaan)');
    }
    _calcPrayer();
  }

  void _showLocationDialog(BuildContext ctx) {
    showDialog(
            context: ctx,
            builder: (_) => LocationSearchDialog(onUseGps: _determinePosition))
        .then((result) {
      if (result != null && mounted) {
        final addr = result['address'] ?? {};
        final v = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'];
        final d = addr['city_district'] ?? addr['county'] ?? addr['district'];
        final c = addr['city'] ??
            addr['town'] ??
            addr['municipality'] ??
            addr['state_district'];
        final parts = [v, d, c]
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .toSet()
            .toList();
        setState(() {
          _lat = double.parse(result['lat']);
          _lng = double.parse(result['lon']);
          _lokasiKota = parts.isNotEmpty
              ? parts.join(', ')
              : (result['name'] ?? 'Wilayah Terpilih');
          _isLoading = true;
        });
        _calcPrayer();
      }
    });
  }

  // ── Prayer ─────────────────────────────────────────────────
  void _calcPrayer() {
    final coords = Coordinates(_lat, _lng);
    final params = CalculationMethod.singapore.getParameters()
      ..madhab = Madhab.shafi;
    final now = DateTime.now();
    final today = PrayerTimes.today(coords, params);
    final list = [
      {'name': 'Subuh', 'dt': today.fajr},
      {'name': 'Zuhur', 'dt': today.dhuhr},
      {'name': 'Ashar', 'dt': today.asr},
      {'name': 'Maghrib', 'dt': today.maghrib},
      {'name': 'Isya', 'dt': today.isha},
    ];
    DateTime? nextDt;
    String nextName = 'Subuh';
    for (final p in list) {
      if (now.isBefore(p['dt'] as DateTime)) {
        nextDt = p['dt'] as DateTime;
        nextName = p['name'] as String;
        break;
      }
    }
    if (nextDt == null) {
      final tmr = now.add(const Duration(days: 1));
      final t = PrayerTimes(
          coords, DateComponents(tmr.year, tmr.month, tmr.day), params);
      nextDt = t.fajr;
      nextName = 'Subuh';
    }
    if (mounted)
      setState(() {
        _isLoading = false;
        _nextPrayerDt = nextDt;
        _nextPrayerName = nextName;
        _nextPrayerTime = DateFormat('HH:mm').format(nextDt!);
      });
    _updateCountdown();
    prayerInfo.value = (
      clock: _currentTime,
      location: _lokasiKota,
      prayer: _nextPrayerName,
      time: _nextPrayerTime,
      countdown: _countdownStr,
      schedule: _openPrayerSchedule
    );
  }

  void _updateCountdown() {
    if (_nextPrayerDt == null || _isLoading) return;
    final diff = _nextPrayerDt!.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds == 0) {
      _calcPrayer();
      return;
    }
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final str = '- $h : $m : $s';
    _countdownStr = str;
  }

  void _showJadwalDialog(BuildContext ctx) {
    showModalBottomSheet<void>(
      context: ctx,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
          maxWidth: 560, maxHeight: MediaQuery.sizeOf(ctx).height * .92),
      builder: (_) => PrayerScheduleSheet(
          latitude: _lat, longitude: _lng, location: _lokasiKota),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
            Row(children: [
              Expanded(
                  child: Text('Markaz Arabiyah',
                      style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(
                  tooltip: 'Notifikasi',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => showComingSoonDialog(context, 'Notifikasi')),
            ]),
            const SizedBox(height: 16),
            const RepaintBoundary(child: WelcomePanel()),
            const SizedBox(height: 20),
            Text(_currentDate,
                style:
                    const TextStyle(color: MarkazColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            const PrayerPanel(),
            TextButton.icon(
                onPressed: () => _showLocationDialog(context),
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: Text(_lokasiKota, textAlign: TextAlign.center)),
            _dailyPrayers(),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Text('Ibadah & layanan',
                      style: Theme.of(context).textTheme.titleLarge)),
              TextButton(onPressed: _showMore, child: const Text('Lainnya'))
            ]),
            const SizedBox(height: 8),
            _buildGridMenu(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Kabar Markaz', context),
            const SizedBox(height: 12),
            _buildInstagramList(context),
            const SizedBox(height: 24),
            _buildSocialSection(context),
          ])));

  Widget _dailyPrayers() {
    final p = PrayerTimes.today(Coordinates(_lat, _lng),
        CalculationMethod.singapore.getParameters()..madhab = Madhab.shafi);
    final times = [
      ('Subuh', p.fajr),
      ('Zuhur', p.dhuhr),
      ('Ashar', p.asr),
      ('Maghrib', p.maghrib),
      ('Isya', p.isha)
    ];
    return LayoutBuilder(builder: (c, box) {
      final n = MediaQuery.textScalerOf(c).scale(1) > 1.3 ? 3 : 5;
      return Wrap(spacing: 4, runSpacing: 8, children: [
        for (final t in times)
          SizedBox(
              width: (box.maxWidth - (n - 1) * 4) / n,
              child: Material(
                  color: t.$1 == _nextPrayerName
                      ? MarkazColors.tint
                      : MarkazColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                      onTap: _openPrayerSchedule,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(children: [
                            Text(t.$1,
                                style: const TextStyle(
                                    fontSize: 12, color: MarkazColors.muted)),
                            const SizedBox(height: 4),
                            Text(DateFormat('HH:mm').format(t.$2),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))
                          ])))))
      ]);
    });
  }

  void _showMore() => showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (c) => ListView(shrinkWrap: true, children: [
            const ListTile(title: Text('Layanan lainnya')),
            for (final label in ['Wirid & Doa', 'Pencarian', 'Semua Artikel'])
              ListTile(
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(c);
                    if (label == 'Semua Artikel') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ArticleListScreen()));
                    } else {
                      showComingSoonDialog(context, label);
                    }
                  }),
          ]));

  Widget _buildGridMenu(BuildContext ctx) {
    void page(Widget page) =>
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
    final items = <(String, IconData, VoidCallback)>[
      (
        'Al-Qur’an',
        Icons.menu_book_rounded,
        widget.onOpenQuran ?? () => page(const QuranScreen())
      ),
      (
        'Artikel',
        Icons.article_rounded,
        () => page(const ArticleListScreen())
      ),
      ('Jadwal Salat', Icons.schedule_rounded, _openPrayerSchedule),
      ('Kiblat', Icons.explore_rounded, () => page(const KiblatScreen())),
      ('Tafsir', Icons.auto_stories_rounded, () => page(const TafsirScreen())),
      ('Denah Sakan', Icons.map_rounded, () => page(const DenahSakanScreen())),
      (
        'Hasil Tes',
        Icons.fact_check_rounded,
        widget.onOpenResults ??
            () => page(const SiakadPortalScreen(initialFeature: 'Hasil Tes'))
      ),
      (
        'Kalender',
        Icons.calendar_month_rounded,
        widget.onOpenCalendar ?? () => page(const CalendarScreen())
      ),
      (
        'SIAKAD',
        Icons.school_rounded,
        widget.onOpenSiakad ?? () => page(const SiakadPortalScreen())
      ),
    ];
    return FeatureGrid(children: [
      for (final item in items)
        FeatureCard(label: item.$1, icon: item.$2, onTap: item.$3)
    ]);
  }

  Widget _buildSectionTitle(String title, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                  color: kGold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: kTextPri, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        GestureDetector(
            onTap: () {
              Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => const InstagramGridScreen()));
            },
            child: const Icon(Icons.chevron_right, color: kTextSec)),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────
  // INSTAGRAM LIST
  // ──────────────────────────────────────────────────────────
  Widget _buildInstagramList(BuildContext ctx) {
    if (_elfsightWebViewController == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGold.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.web, color: kGoldDim, size: 48),
            SizedBox(height: 12),
            Text('Ikuti kabar dan kegiatan Markaz di Instagram.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MarkazColors.muted, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      height:
          480, // Memberikan batasan tinggi agar WebView bisa memuat konten embed
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _elfsightWebViewController!),
    );
  }

  // ──────────────────────────────────────────────────────────
  // IKUTI KAMI (logo sosmed)
  // ──────────────────────────────────────────────────────────
  Widget _buildSocialSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                    color: kGold, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Ikuti Kami',
                style: TextStyle(
                    color: kTextPri,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _socialButton('Instagram', 'assets/icons/instagram.svg',
                'https://www.instagram.com/ofc_markazarabiyah/'),
            _socialButton('TikTok', 'assets/icons/tiktok.svg',
                'https://www.tiktok.com/@markazarabiyah/'),
            _socialButton(
                'Website', null, 'https://www.markazarabiyah.com/'),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(String label, String? svgAsset, String url) {
    final graphic = svgAsset != null
        ? SvgPicture.asset(svgAsset,
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(
                MarkazColors.ink, BlendMode.srcIn))
        : const Icon(Icons.language, size: 26, color: MarkazColors.ink);
    return Column(children: [
      Material(
        color: MarkazColors.tint,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openSocial(url),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: graphic,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: const TextStyle(fontSize: 12, color: MarkazColors.muted)),
    ]);
  }

  Future<void> _openSocial(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class LocationSearchDialog extends StatefulWidget {
  final VoidCallback onUseGps;
  const LocationSearchDialog({super.key, required this.onUseGps});
  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final _ctrl = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  Timer? _debounce;
  String? _searchError;
  bool _searched = false;
  int _request = 0;

  void _onChange(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (q.trim().length < 3) {
      _request++;
      setState(() {
        _results = [];
        _loading = false;
        _searched = false;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () => _search(q));
  }

  Future<void> _search(String q) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _searchError = null;
    });
    try {
      final res = await http.get(
          Uri.https('nominatim.openstreetmap.org', '/search', {
            'q': q,
            'format': 'json',
            'addressdetails': '1',
            'countrycodes': 'id',
            'limit': '6',
          }),
          headers: {
            'User-Agent': 'MarkazArabiyah/1.0'
          }).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw const FormatException();
      final results = jsonDecode(res.body) as List;
      if (mounted && request == _request) setState(() => _results = results);
    } catch (_) {
      if (mounted && request == _request)
        setState(() {
          _searchError =
              'Wilayah belum dapat dicari. Periksa koneksi lalu coba lagi.';
          _results = [];
        });
    } finally {
      if (mounted && request == _request)
        setState(() {
          _loading = false;
          _searched = true;
        });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cari Wilayah Anda',
          style: TextStyle(color: MarkazColors.ink)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _ctrl,
            onChanged: _onChange,
            style: const TextStyle(color: MarkazColors.ink),
            decoration: InputDecoration(
              hintText: 'Misal: Bangsri, Sleman...',
              hintStyle: const TextStyle(color: MarkazColors.muted),
              filled: true,
              fillColor: kBgCard2,
              prefixIcon: const Icon(Icons.search, color: MarkazColors.muted),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(MarkazColors.ink)))
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          if (_searchError != null)
            Text(_searchError!,
                style: const TextStyle(color: MarkazColors.danger)),
          if (_searched &&
              _results.isEmpty &&
              _searchError == null &&
              !_loading)
            const Text(
                'Wilayah tidak ditemukan. Coba nama kota atau kecamatan.'),
          if (_results.isNotEmpty)
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: MarkazColors.line, height: 1),
              itemBuilder: (_, i) {
                final item = _results[i];
                final addr = item['address'] ?? {};

                final v =
                    addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'];
                final d =
                    addr['city_district'] ?? addr['district'] ?? addr['county'];
                final c = addr['city'] ??
                    addr['town'] ??
                    addr['municipality'] ??
                    addr['state_district'];

                final titleParts = [v, d]
                    .where((e) => e != null && e.toString().trim().isNotEmpty)
                    .toSet()
                    .toList();
                final titleStr = titleParts.isNotEmpty
                    ? titleParts.join(', ')
                    : (item['name'] ?? 'Wilayah');

                final subParts = [c, addr['state']]
                    .where((e) => e != null && e.toString().trim().isNotEmpty)
                    .toSet()
                    .toList();
                final subStr =
                    subParts.isNotEmpty ? subParts.join(', ') : 'Indonesia';

                return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(titleStr,
                        style: const TextStyle(
                            color: MarkazColors.ink,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(subStr,
                        style: const TextStyle(
                            color: MarkazColors.muted, fontSize: 12)),
                    onTap: () => Navigator.pop(context, item));
              },
            ),
          if (_results.isEmpty && !_loading)
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.gps_fixed, color: Colors.black),
                  label: const Text('Gunakan GPS Saat Ini',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onUseGps();
                  },
                )),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
