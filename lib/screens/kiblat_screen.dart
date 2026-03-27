import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ──────────────────────────────────────────────────────────
// KONSTANTA WARNA (Sinkron dengan home_screen.dart)
// ──────────────────────────────────────────────────────────
const _kBg          = Color(0xFF0A0A0A);
const _kBgCard      = Color(0xFF1A1400);
const _kGold        = Color(0xFFD4AF37);
const _kGoldLight   = Color(0xFFEDD56A);
const _kGoldDim     = Color(0x22D4AF37);
const _kTextPri     = Colors.white;
const _kTextSec     = Color(0xFFB0A090);

class KiblatScreen extends StatefulWidget {
  const KiblatScreen({super.key});

  @override
  State<KiblatScreen> createState() => _KiblatScreenState();
}

class _KiblatScreenState extends State<KiblatScreen>
    with TickerProviderStateMixin {
  // ── State ───────────────────────────────────────────────
  bool _locationPermissionGranted = false;
  String _lokasiName = 'Memuat lokasi...';
  double _qiblahOffset = 0.0;    // Arah kiblat dari utara statis (offset)

  // Animasi putaran kompas
  late AnimationController _compassCtrl;
  late Animation<double> _compassAnim;
  double _prevCompassAngle = 0.0;

  // ── Lifecycle ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _compassCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _compassAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _compassCtrl, curve: Curves.easeOut));
    _init();
  }

  @override
  void dispose() {
    _compassCtrl.dispose();
    super.dispose();
  }

  // ── Init / Permission ────────────────────────────────────
  Future<void> _init() async {
    bool svc = await Geolocator.isLocationServiceEnabled();
    if (!svc) {
      _setError('GPS tidak aktif'); return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _setError('Izin GPS ditolak'); return;
    }
    setState(() => _locationPermissionGranted = true);

    try {
      final pos = await Geolocator.getCurrentPosition();
      _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {
      setState(() => _lokasiName = 'Lokasi Terdeteksi');
    }
  }

  void _setError(String msg) =>
      setState(() { _lokasiName = msg; _locationPermissionGranted = false; });

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng'),
        headers: {'User-Agent': 'SigmaApp/1.0'},
      );
      if (res.statusCode == 200 && mounted) {
        final addr = (jsonDecode(res.body)['address'] as Map<String, dynamic>?) ?? {};
        final v = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'];
        final d = addr['city_district'] ?? addr['county'] ?? addr['district'];
        final parts = [v, d].where((e) => e != null && e.toString().trim().isNotEmpty).toSet().toList();
        setState(() => _lokasiName = parts.isNotEmpty ? parts.join(', ') : 'Lokasi Terdeteksi');
      }
    } catch (_) {
      setState(() => _lokasiName = 'Lokasi Terdeteksi');
    }
  }

  // ── Animasi Kompas ───────────────────────────────────────
  void _animateCompass(double targetAngle) {
    // Pilih rute terpendek
    double delta = targetAngle - _prevCompassAngle;
    while (delta > math.pi)  delta -= 2 * math.pi;
    while (delta < -math.pi) delta += 2 * math.pi;
    final newAngle = _prevCompassAngle + delta;

    _compassAnim = Tween<double>(begin: _prevCompassAngle, end: newAngle).animate(
        CurvedAnimation(parent: _compassCtrl, curve: Curves.easeOut));
    _compassCtrl.forward(from: 0);
    _prevCompassAngle = newAngle;
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: _locationPermissionGranted
            ? _buildQiblahStream()
            : _buildPermissionError(),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: _kGold),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Arah Kiblat',
      style: TextStyle(color: _kGold, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    centerTitle: false,
  );

  Widget _buildPermissionError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.location_off, color: _kGold, size: 60),
      const SizedBox(height: 20),
      Text(_lokasiName,
        style: const TextStyle(color: _kTextSec, fontSize: 16),
        textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _init,
        child: const Text('Coba Lagi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    ]),
  );

  Widget _buildQiblahStream() {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kGold));
        }
        if (snap.hasData) {
          final data = snap.data!;
          _qiblahOffset = data.offset; // Sudut statis kiblat dari utara

          final headingRad = data.direction * (math.pi / 180);
          _animateCompass(headingRad);
        }

        return _buildBody();
      },
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // ── Info Lokasi ───────────────────────────────────
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.location_on, color: Colors.red, size: 18),
          const SizedBox(width: 6),
          Text(
            _lokasiName,
            style: const TextStyle(
              color: _kTextPri, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Derajat Sudut Kiblat dari Utara',
          style: TextStyle(color: _kTextSec, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          '${_qiblahOffset.toStringAsFixed(2)}°',
          style: const TextStyle(
            color: _kTextPri, fontSize: 36, fontWeight: FontWeight.bold,
            letterSpacing: 1),
        ),

        const SizedBox(height: 40),

        // ── Kompas ────────────────────────────────────────
        Expanded(
          child: Center(
            child: _buildCompass(),
          ),
        ),

        // ── Tombol Bawah ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _kBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGold.withOpacity(0.4)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore, color: _kGold, size: 20),
                SizedBox(width: 10),
                Text(
                  'Sensor Kompas Aktif & Realtime',
                  style: TextStyle(color: _kGold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Widget Kompas ────────────────────────────────────────
  Widget _buildCompass() {
    const size = 280.0;
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: _compassAnim,
        builder: (_, __) {
          return CustomPaint(
            painter: _CompassPainter(
              headingAngle: _compassAnim.value,
              qiblahOffsetAngle: _qiblahOffset * (math.pi / 180),
            ),
            size: const Size(size, size),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// CUSTOM PAINTER: KOMPAS ELEGAN EMAS
// ══════════════════════════════════════════════════════════
class _CompassPainter extends CustomPainter {
  final double headingAngle; // radian dari utara HP
  final double qiblahOffsetAngle; // radian posisi kiblat dari utara
  const _CompassPainter({required this.headingAngle, required this.qiblahOffsetAngle});

  static const kGold      = Color(0xFFD4AF37);
  static const kGoldLight = Color(0xFFEDD56A);
  static const kBgCard    = Color(0xFF1A1400);
  static const kBg        = Color(0xFF0A0A0A);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Putar seluruh kompas (dial) agar Utara menunjuk arah Utara asli
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-headingAngle);
    canvas.translate(-cx, -cy);

    // ── Lingkaran Luar (shadow + border emas) ──────────────
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = kGold.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      Offset(cx, cy), r - 4,
      Paint()..color = const Color(0xFF1E1800),
    );
    canvas.drawCircle(
      Offset(cx, cy), r - 4,
      Paint()
        ..color = kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── Cincin Dalam (dekorasi) ────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy), r * 0.72,
      Paint()
        ..color = kGold.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Tick Marks ─────────────────────────────────────────
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < 72; i++) {
      final angle    = (2 * math.pi / 72) * i;
      final isMajor  = i % 6 == 0;   // setiap 30°
      final isMid    = i % 3 == 0;   // setiap 15°
      final len      = isMajor ? 14.0 : isMid ? 8.0 : 5.0;
      tickPaint
        ..color     = isMajor ? kGoldLight : kGold.withOpacity(0.45)
        ..strokeWidth = isMajor ? 2.5 : 1;
      final outerR = r - 6;
      final innerR = outerR - len;
      canvas.drawLine(
        Offset(cx + outerR * math.sin(angle), cy - outerR * math.cos(angle)),
        Offset(cx + innerR * math.sin(angle), cy - innerR * math.cos(angle)),
        tickPaint,
      );
    }

    // ── Label Arah (S = Selatan, T = Timur, B = Barat, U = Utara) ──
    final tf = TextStyle(
      color: kGoldLight, fontSize: 16, fontWeight: FontWeight.bold,
      letterSpacing: 1,
    );
    final dirs = {'U': 0.0, 'T': math.pi * 0.5, 'S': math.pi, 'B': math.pi * 1.5};
    final labelR = r * 0.78;
    dirs.forEach((lbl, angle) {
      final xp = cx + labelR * math.sin(angle);
      final yp = cy - labelR * math.cos(angle);
      final span = TextSpan(text: lbl, style: tf);
      final tp   = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(xp - tp.width / 2, yp - tp.height / 2));
    });

    // ── Ornamen Bunga (tengah) ─────────────────────────────
    _drawFlower(canvas, cx, cy, r * 0.26);

    // ── Jarum (Kiblat) ─────────────────────────────────────
    canvas.save();
    canvas.translate(cx, cy);
    // Jarum menunjuk ke arah Kiblat dari Utara.
    // Karena canvas sudah dirotasi sehingga orientasinya adalah Utara secara fisik,
    // kita cukup putar jarum sebesar sudut Kiblat dari Utara (qiblahOffsetAngle)
    canvas.rotate(qiblahOffsetAngle);

    // bayangan jarum
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(_needlePath(r), shadowPaint);

    // bagian belakang (emas)
    final backPaint = Paint()..color = kGold;
    canvas.drawPath(_needleBackPath(r), backPaint);

    // bagian depan (emas terang) — menunjuk kiblat
    final frontPaint = Paint()
      ..shader = LinearGradient(
        colors: [kGoldLight, kGold],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-8, -r * 0.62, 16, r * 0.62));
    canvas.drawPath(_needleFrontPath(r), frontPaint);

    // lingkaran tengah jarum
    canvas.drawCircle(Offset.zero, 10,
      Paint()..color = kGold);
    canvas.drawCircle(Offset.zero, 6,
      Paint()..color = kBg);
    canvas.drawCircle(Offset.zero, 3,
      Paint()..color = kGoldLight);

    canvas.restore(); // restore jarum
    canvas.restore(); // restore putaran kompas luar
  }

  void _drawFlower(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..color = kGold.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 8; i++) {
      final a = (math.pi / 4) * i;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + r * 0.5 * math.cos(a), cy + r * 0.5 * math.sin(a)),
          width: r, height: r * 0.5,
        ),
        paint,
      );
    }
  }

  // Jarum depan — menunjuk kiblat (ke atas / ujung segitiga runcing)
  Path _needleFrontPath(double r) {
    final path = Path();
    path.moveTo(0, -r * 0.62);
    path.lineTo(8, 0);
    path.lineTo(-8, 0);
    path.close();
    return path;
  }

  // Jarum belakang (ekor)
  Path _needleBackPath(double r) {
    final path = Path();
    path.moveTo(0, r * 0.32);
    path.lineTo(5, 0);
    path.lineTo(-5, 0);
    path.close();
    return path;
  }

  Path _needlePath(double r) {
    final path = Path();
    path.moveTo(0, -r * 0.62);
    path.lineTo(8, r * 0.32);
    path.lineTo(-8, r * 0.32);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_CompassPainter old) => 
    old.headingAngle != headingAngle || old.qiblahOffsetAngle != qiblahOffsetAngle;
}
