import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../widgets/coming_soon_dialog.dart';
import 'denah_sakan_screen.dart';

// ============================================================
// WARNA TEMA — Hitam & Emas
// ============================================================
const kBgDark    = Color(0xFF0A0A0A);
const kBgCard    = Color(0xFF181818);
const kBgCard2   = Color(0xFF202020);
const kGold      = Color(0xFFD4AF37);
const kGoldLight = Color(0xFFEDD56A);
const kGoldDark  = Color(0xFF9E7E1A);
const kGoldDim   = Color(0xFF3A2E0A);
const kTextPri   = Colors.white;
const kTextSec   = Color(0xFFAAAAAA);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentDate    = '';
  String _hijriDate      = '5 Syawal 1447 H';
  String _lokasiKota     = 'Mencari lokasi...';
  String _nextPrayerName = 'MEMUAT...';
  String _nextPrayerTime = '--:--';
  String _countdownStr   = '--:--:--';
  bool   _isLoading      = true;

  double _lat = -6.5333;
  double _lng = 110.7000;

  DateTime? _nextPrayerDt;
  Timer?    _timer;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    _determinePosition();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  // ── GPS ────────────────────────────────────────────────────
  Future<void> _determinePosition() async {
    bool svc = await Geolocator.isLocationServiceEnabled();
    if (!svc) {
      if (mounted) setState(() => _lokasiKota = 'Bangsri, Jepara (GPS Off)');
      _calcPrayer(); return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      final lbl = perm == LocationPermission.deniedForever ? 'Diblokir' : 'Ditahan';
      if (mounted) setState(() => _lokasiKota = 'Bangsri, Jepara ($lbl)');
      _calcPrayer(); return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}';
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'SigmaApp/1.0'});
      if (res.statusCode == 200 && mounted) {
        final addr = (jsonDecode(res.body)['address'] as Map<String, dynamic>?) ?? {};
        final v = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'];
        final d = addr['city_district'] ?? addr['county'] ?? addr['district'];
        final c = addr['city'] ?? addr['town'] ?? addr['municipality'] ?? addr['state_district'];
        final parts = [v, d, c].where((e) => e != null && e.toString().trim().isNotEmpty).toSet().toList();
        setState(() => _lokasiKota = parts.isNotEmpty ? parts.join(', ') : 'Lokasi Terdeteksi');
      } else if (mounted) {
        setState(() => _lokasiKota = 'Lokasi Terdeteksi');
      }
    } catch (_) { if (mounted) setState(() => _lokasiKota = 'Lokasi Terdeteksi'); }
    _calcPrayer();
  }

  void _showLocationDialog(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => LocationSearchDialog(onUseGps: _determinePosition))
      .then((result) {
        if (result != null && mounted) {
          final addr = result['address'] ?? {};
          final v = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'];
          final d = addr['city_district'] ?? addr['county'] ?? addr['district'];
          final c = addr['city'] ?? addr['town'] ?? addr['municipality'] ?? addr['state_district'];
          final parts = [v, d, c].where((e) => e != null && e.toString().trim().isNotEmpty).toSet().toList();
          setState(() {
            _lat = double.parse(result['lat']);
            _lng = double.parse(result['lon']);
            _lokasiKota = parts.isNotEmpty ? parts.join(', ') : (result['name'] ?? 'Wilayah Terpilih');
            _isLoading = true;
          });
          _calcPrayer();
        }
      });
  }

  // ── Prayer ─────────────────────────────────────────────────
  void _calcPrayer() {
    final coords = Coordinates(_lat, _lng);
    final params = CalculationMethod.singapore.getParameters()..madhab = Madhab.shafi;
    final now = DateTime.now();
    final today = PrayerTimes.today(coords, params);
    final list = [
      {'name': 'Subuh',   'dt': today.fajr},
      {'name': 'Zuhur',   'dt': today.dhuhr},
      {'name': 'Ashar',   'dt': today.asr},
      {'name': 'Maghrib', 'dt': today.maghrib},
      {'name': 'Isya',    'dt': today.isha},
    ];
    DateTime? nextDt; String nextName = 'Subuh';
    for (final p in list) {
      if (now.isBefore(p['dt'] as DateTime)) { nextDt = p['dt'] as DateTime; nextName = p['name'] as String; break; }
    }
    if (nextDt == null) {
      final tmr = now.add(const Duration(days: 1));
      final t = PrayerTimes(coords, DateComponents(tmr.year, tmr.month, tmr.day), params, utcOffset: const Duration(hours: 7));
      nextDt = t.fajr; nextName = 'Subuh';
    }
    if (mounted) setState(() {
      _isLoading = false;
      _nextPrayerDt = nextDt;
      _nextPrayerName = nextName;
      _nextPrayerTime = DateFormat('HH:mm').format(nextDt!);
    });
    _updateCountdown();
  }

  void _updateCountdown() {
    if (_nextPrayerDt == null || _isLoading) return;
    final diff = _nextPrayerDt!.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds == 0) { _calcPrayer(); return; }
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final str = '- $h : $m : $s';
    if (mounted && _countdownStr != str) setState(() => _countdownStr = str);
  }

  // ── Jadwal Dialog ──────────────────────────────────────────
  void _showJadwalDialog(BuildContext ctx) {
    DateTime sel = DateTime.now();
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (c, ss) {
      final params = CalculationMethod.singapore.getParameters()..madhab = Madhab.shafi;
      final pt = PrayerTimes(Coordinates(_lat, _lng), DateComponents(sel.year, sel.month, sel.day), params, utcOffset: const Duration(hours: 7));
      final fmt = DateFormat('HH:mm');
      return AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(children: [
          const Text('Jadwal Sholat', style: TextStyle(color: kGold, fontSize: 18)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: kTextPri), onPressed: () => ss(() => sel = sel.subtract(const Duration(days: 1)))),
            Text(DateFormat('dd MMM yyyy').format(sel), style: const TextStyle(color: kTextSec, fontSize: 13)),
            IconButton(icon: const Icon(Icons.chevron_right, color: kTextPri), onPressed: () => ss(() => sel = sel.add(const Duration(days: 1)))),
          ]),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _jRow('Imsak',   fmt.format(pt.fajr.subtract(const Duration(minutes: 10)))),
          _jRow('Subuh',   fmt.format(pt.fajr)),
          _jRow('Terbit',  fmt.format(pt.sunrise)),
          _jRow('Dhuha',   fmt.format(pt.sunrise.add(const Duration(minutes: 20)))),
          _jRow('Dzuhur',  fmt.format(pt.dhuhr)),
          _jRow('Ashar',   fmt.format(pt.asr)),
          _jRow('Maghrib', fmt.format(pt.maghrib)),
          _jRow('Isya',    fmt.format(pt.isha)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup', style: TextStyle(color: kGold)))],
      );
    }));
  }

  Widget _jRow(String t, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(t, style: const TextStyle(color: kTextSec)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: kGoldDim, borderRadius: BorderRadius.circular(8)),
        child: Text(v, style: const TextStyle(color: kGoldLight, fontWeight: FontWeight.bold)),
      ),
    ]),
  );

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMosqueHeader(),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: _buildGridMenu(context)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildSearchBar(context)),
            const SizedBox(height: 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildBanner()),
            const SizedBox(height: 20),
            _buildSectionTitle('Headline', context),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildArticleList(context)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // MOSQUE HEADER
  // ──────────────────────────────────────────────────────────
  Widget _buildMosqueHeader() {
    return Stack(
      children: [
        // Background gradien emas gelap
        Container(
          width: double.infinity,
          height: 380,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2C1F00), Color(0xFF1A1200), Color(0xFF0A0A0A)],
              stops: [0.0, 0.55, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Pola geometri arabesque (emas redup)
        Positioned.fill(child: CustomPaint(painter: _GeometricPatternPainter())),
        // Silhouette masjid di bawah
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SizedBox(height: 140, child: CustomPaint(painter: _MosqueSilhouettePainter())),
        ),
        // Garis aksen emas
        Positioned(bottom: 138, left: 0, right: 0,
          child: Container(height: 1, color: kGold.withOpacity(0.35))),
        // Konten teks
        SafeArea(
          child: SizedBox(
            height: 380 - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none, color: kGoldLight, size: 26),
                      onPressed: () => showComingSoonDialog(context, 'Notifikasi'),
                    ),
                  ),
                ),
                const Text('Markaz Arabiyah',
                  style: TextStyle(
                    color: kGoldLight, fontSize: 27, fontWeight: FontWeight.bold, letterSpacing: 1.5,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showLocationDialog(context),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 15),
                    const SizedBox(width: 4),
                    Text(_lokasiKota, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Ganti', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Text(
                  _isLoading ? 'MEMUAT...' : '$_nextPrayerName  $_nextPrayerTime WIB',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLoading ? '--:--:--' : _countdownStr,
                  style: const TextStyle(color: kGoldLight, fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 10),
                Text('$_currentDate / $_hijriDate',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const Spacer(),
                const SizedBox(height: 140), // beri ruang untuk silhouette
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // GRID MENU
  // ──────────────────────────────────────────────────────────
  Widget _buildGridMenu(BuildContext ctx) {
    final items = [
      {'icon': Icons.menu_book,          'label': 'Al-Quran'},
      {'icon': Icons.volunteer_activism, 'label': 'Wirid & Doa'},
      {'icon': Icons.access_time_filled, 'label': 'Jadwal\nShalat'},
      {'icon': Icons.explore,            'label': 'Kiblat'},
      {'icon': Icons.person_outline,     'label': 'Tahlil & Yasin'},
      {'icon': Icons.map,                'label': 'Denah Sakan'},
      {'icon': Icons.favorite_outline,   'label': 'Zakat &\nSedekah'},
      {'icon': Icons.grid_view,          'label': 'Lainnya'},
    ];
    return GridView.count(
      crossAxisCount: 4, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 18, childAspectRatio: 0.85,
      children: items.map((item) {
        final isJadwal = item['label'].toString().contains('Shalat');
        final isDenah = item['label'].toString().contains('Denah Sakan');
        return GestureDetector(
          onTap: () {
            if (isJadwal) _showJadwalDialog(ctx);
            else if (isDenah) Navigator.push(ctx, MaterialPageRoute(builder: (_) => const DenahSakanScreen()));
            else showComingSoonDialog(ctx, item['label'] as String);
          },
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: kGoldDim,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kGold.withOpacity(0.45), width: 1.2),
                boxShadow: [BoxShadow(color: kGold.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(item['icon'] as IconData, color: kGoldLight, size: 26),
            ),
            const SizedBox(height: 6),
            Text(item['label'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextPri, fontSize: 11, height: 1.3), maxLines: 2),
          ]),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext ctx) {
    return GestureDetector(
      onTap: () => showComingSoonDialog(ctx, 'Pencarian'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: kBgCard2, borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kGold.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(Icons.search, color: kGold.withOpacity(0.5), size: 20),
          const SizedBox(width: 10),
          Text('Cari doa, wirid, artikel',
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14)),
        ]),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // BANNER
  // ──────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      width: double.infinity, height: 115,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2C00), Color(0xFF1A1200)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        border: Border.all(color: kGold.withOpacity(0.4), width: 1),
      ),
      child: Stack(children: [
        Positioned(right: -10, top: -10, child: Container(
          width: 110, height: 110,
          decoration: BoxDecoration(shape: BoxShape.circle, color: kGold.withOpacity(0.05)))),
        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Selamat Hari Raya', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            const Text('Idul Fitri 1447 H', style: TextStyle(color: kGoldLight, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Minal Aidin Wal Faizin', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          ],
        )),
        const Positioned(right: 16, top: 0, bottom: 0,
          child: Center(child: Icon(Icons.mosque, color: Color(0x20D4AF37), size: 55))),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION TITLE
  // ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: kTextPri, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        GestureDetector(
          onTap: () => showComingSoonDialog(ctx, 'Semua Artikel'),
          child: const Icon(Icons.chevron_right, color: kTextSec)),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ARTICLE LIST
  // ──────────────────────────────────────────────────────────
  Widget _buildArticleList(BuildContext ctx) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(3, (i) => GestureDetector(
          onTap: () => showComingSoonDialog(ctx, 'Artikel ${i + 1}'),
          child: Container(
            width: 230, margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: kBgCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kGold.withOpacity(0.15))),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 100, color: kGoldDim,
                child: const Center(child: Icon(Icons.article, color: kGoldLight, size: 32))),
              Padding(padding: const EdgeInsets.all(10), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tradisi Markaz Arabiyah #${i + 1}',
                    style: const TextStyle(color: kTextPri, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  const Text('Belajar bahasa Arab secara mendalam dan menyeluruh...',
                    style: TextStyle(color: kTextSec, fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
            ]),
          ),
        )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════

/// Pola segi delapan arabesque di latar belakang header
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const step = 46.0;
    for (double y = 0; y < size.height * 0.7; y += step) {
      for (double x = 0; x < size.width + step; x += step) {
        _drawOctagon(canvas, Offset(x, y), step * 0.36, p);
      }
    }
    final pBig = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.15), 72, pBig);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.5), 48, pBig);
  }

  void _drawOctagon(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = (2 * math.pi / 8) * i - math.pi / 8;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
    canvas.drawCircle(c, r * 0.48, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Silhouette masjid: dua menara di kiri-kanan + kubah besar di tengah
class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final W = size.width;
    final H = size.height;
    final path = _buildMosquePath(W, H);

    canvas.drawPath(path, bg);
    canvas.drawPath(path, outline);

    // Hiasan puncak
    _drawFinial(canvas, Offset(W * 0.50, _domeTopY(H)),  7.0);
    _drawFinial(canvas, Offset(W * 0.085, _minaretTopY(H)), 4.0);
    _drawFinial(canvas, Offset(W * 0.915, _minaretTopY(H)), 4.0);
  }

  double _domeTopY(double H) => H * (-0.18);   // kubah menjulur ke atas canvas
  double _minaretTopY(double H) => H * 0.025;   // puncak menara

  Path _buildMosquePath(double W, double H) {
    final path = Path();
    path.moveTo(0, H);

    // ── MENARA KIRI ────────────────────────────────────────
    const mW = 0.065; // setengah lebar menara (fraksi W)
    const mH = 0.92;  // tinggi menara total (fraksi H)
    double lx = W * 0.085;

    path.lineTo(0, H * 0.68);
    path.lineTo(lx - W * mW * 1.5, H * 0.68);
    path.lineTo(lx - W * mW * 1.5, H * 0.58);
    path.lineTo(lx - W * mW,       H * 0.58);
    path.lineTo(lx - W * mW,       H * (1 - mH + 0.28));
    // Jenjang / teras menara
    path.lineTo(lx - W * mW * 1.3, H * (1 - mH + 0.28));
    path.lineTo(lx - W * mW * 1.3, H * (1 - mH + 0.20));
    path.lineTo(lx - W * mW * 0.7, H * (1 - mH + 0.20));
    // Badan ramping menara
    path.lineTo(lx - W * mW * 0.5, H * (1 - mH + 0.10));
    // Puncak runcing
    path.lineTo(lx,                 H * (1 - mH));
    path.lineTo(lx + W * mW * 0.5, H * (1 - mH + 0.10));
    path.lineTo(lx + W * mW * 0.7, H * (1 - mH + 0.20));
    path.lineTo(lx + W * mW * 1.3, H * (1 - mH + 0.20));
    path.lineTo(lx + W * mW * 1.3, H * (1 - mH + 0.28));
    path.lineTo(lx + W * mW,       H * (1 - mH + 0.28));
    path.lineTo(lx + W * mW,       H * 0.58);
    path.lineTo(lx + W * mW * 1.5, H * 0.58);
    path.lineTo(lx + W * mW * 1.5, H * 0.68);

    // ── LENGKUNGAN KIRI (busur kecil) ──────────────────────
    path.lineTo(W * 0.30, H * 0.68);
    path.quadraticBezierTo(W * 0.33, H * 0.42, W * 0.38, H * 0.65);

    // ── KUBAH UTAMA ────────────────────────────────────────
    path.lineTo(W * 0.41, H * 0.52);
    // Busur kubah (kubik Bezier)
    path.cubicTo(
      W * 0.42, H * (-0.20),
      W * 0.58, H * (-0.20),
      W * 0.59, H * 0.52,
    );
    path.lineTo(W * 0.62, H * 0.65);

    // ── LENGKUNGAN KANAN ───────────────────────────────────
    path.quadraticBezierTo(W * 0.67, H * 0.42, W * 0.70, H * 0.68);

    // ── MENARA KANAN ──────────────────────────────────────
    double rx = W * 0.915;
    path.lineTo(rx - W * mW * 1.5, H * 0.68);
    path.lineTo(rx - W * mW * 1.5, H * 0.58);
    path.lineTo(rx - W * mW,       H * 0.58);
    path.lineTo(rx - W * mW,       H * (1 - mH + 0.28));
    path.lineTo(rx - W * mW * 1.3, H * (1 - mH + 0.28));
    path.lineTo(rx - W * mW * 1.3, H * (1 - mH + 0.20));
    path.lineTo(rx - W * mW * 0.7, H * (1 - mH + 0.20));
    path.lineTo(rx - W * mW * 0.5, H * (1 - mH + 0.10));
    path.lineTo(rx,                 H * (1 - mH));
    path.lineTo(rx + W * mW * 0.5, H * (1 - mH + 0.10));
    path.lineTo(rx + W * mW * 0.7, H * (1 - mH + 0.20));
    path.lineTo(rx + W * mW * 1.3, H * (1 - mH + 0.20));
    path.lineTo(rx + W * mW * 1.3, H * (1 - mH + 0.28));
    path.lineTo(rx + W * mW,       H * (1 - mH + 0.28));
    path.lineTo(rx + W * mW,       H * 0.58);
    path.lineTo(rx + W * mW * 1.5, H * 0.58);
    path.lineTo(rx + W * mW * 1.5, H * 0.68);

    path.lineTo(W, H * 0.68);
    path.lineTo(W, H);
    path.close();
    return path;
  }

  void _drawFinial(Canvas canvas, Offset c, double r) {
    // Bola emas puncak
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFEDD56A));
    canvas.drawCircle(c, r * 0.5, Paint()..color = const Color(0xFF0A0A0A));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
// LOCATION SEARCH DIALOG
// ═══════════════════════════════════════════════════════════════
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

  void _onChange(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (q.trim().length < 3) { setState(() => _results = []); return; }
    _debounce = Timer(const Duration(milliseconds: 800), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&addressdetails=1&countrycodes=id&limit=6'),
        headers: {'User-Agent': 'SigmaApp/1.0'});
      if (res.statusCode == 200 && mounted) setState(() { _results = jsonDecode(res.body); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  void dispose() { _debounce?.cancel(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cari Wilayah Anda', style: TextStyle(color: kGold)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _ctrl, onChanged: _onChange,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Misal: Bangsri, Sleman...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true, fillColor: kBgCard2,
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: _loading
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(kGold)))
                : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          if (_results.isNotEmpty)
            Flexible(child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2A2A), height: 1),
              itemBuilder: (_, i) {
                final item = _results[i];
                final addr = item['address'] ?? {};
                
                final v = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'];
                final d = addr['city_district'] ?? addr['district'] ?? addr['county'];
                final c = addr['city'] ?? addr['town'] ?? addr['municipality'] ?? addr['state_district'];
                
                final titleParts = [v, d].where((e) => e != null && e.toString().trim().isNotEmpty).toSet().toList();
                final titleStr = titleParts.isNotEmpty ? titleParts.join(', ') : (item['name'] ?? 'Wilayah');
                
                final subParts = [c, addr['state']].where((e) => e != null && e.toString().trim().isNotEmpty).toSet().toList();
                final subStr = subParts.isNotEmpty ? subParts.join(', ') : 'Indonesia';

                return ListTile(contentPadding: EdgeInsets.zero,
                  title: Text(titleStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(subStr, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  onTap: () => Navigator.pop(context, item));
              },
            )),
          if (_results.isEmpty && !_loading)
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.gps_fixed, color: Colors.black),
                label: const Text('Gunakan GPS Saat Ini',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold, padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () { Navigator.pop(context); widget.onUseGps(); },
              )),
        ]),
      ),
      actions: [TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal', style: TextStyle(color: Colors.grey)))],
    );
  }
}