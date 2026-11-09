import '../widgets/prayer_schedule_sheet.dart';
import '../widgets/markaz_components.dart';
import 'calendar_screen.dart';
import '../theme/markaz_theme.dart';
import '../siakad/api.dart';
import '../siakad/features.dart';
import '../siakad/prayer.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'denah_sakan_screen.dart';
import 'article_list_screen.dart';
import 'kiblat_screen.dart';
import 'siakad_portal_screen.dart';
import 'tafsir_screen.dart';
import 'quran_screen.dart';
import 'article_detail_screen.dart';
import 'public_pengumuman_screen.dart';
import '../data/articles.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      this.santriLoggedIn = false,
      this.onOpenSiakad,
      this.onOpenResults,
      this.onOpenCalendar,
      this.onOpenQuran});
  // Diisi MainLayout dari status login portal SIAKAD; dipakai untuk
  // memuat ulang kartu santri saat login/logout lewat portal.
  final bool santriLoggedIn;
  final VoidCallback? onOpenSiakad, onOpenResults, onOpenCalendar, onOpenQuran;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
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

  // Batch 1.0.6+7 butir 8: grid menu ciut (8 card) / melebar (semua).
  bool _menuExpanded = false;

  // Butir 7: carousel artikel (5 terbaru, auto-slide 5 detik).
  List<dynamic> _artikelCarousel = [];
  bool _artikelGagal = false;
  int _artikelPage = 0;
  PageController? _artikelCtrl;
  Timer? _artikelTimer;

  // Butir 4: pengumuman terbaru di Beranda (maks. 3 item).
  List<dynamic> _pengumumanTerbaru = [];
  // Nilai terakhir angka belum-dibaca; naik = pengumuman baru masuk.
  int _lastUnreadCount = 0;

  final _shorebirdUpdater = ShorebirdUpdater();

  // Dibuat malas di _loadSantri: konstruktor SantriApi membaca dotenv,
  // yang belum tentu siap saat State dibuat (mis. di tes widget).
  SantriApi? _santriApi;
  Json? _santriMe;
  Json? _santriStatus;

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
    _loadSantri();
    _loadArtikelCarousel();
    _loadPengumumanTerbaru();
    // Pengumuman baru yang masuk saat aplikasi dibuka: muat ulang daftar
    // begitu angka belum-dibaca naik (pesan foreground memanggil
    // refreshUnread), dan saat aplikasi kembali dari latar.
    _lastUnreadCount = SantriPush.unreadCount.value;
    SantriPush.unreadCount.addListener(_onUnreadChanged);
    WidgetsBinding.instance.addObserver(this);

  }

  void _onUnreadChanged() {
    final n = SantriPush.unreadCount.value;
    if (n > _lastUnreadCount) _loadPengumumanTerbaru();
    _lastUnreadCount = n;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPengumumanTerbaru();
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
    SantriPush.unreadCount.removeListener(_onUnreadChanged);
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _artikelTimer?.cancel();
    _artikelCtrl?.dispose();
    _santriApi?.dispose();
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

  @override
  void didUpdateWidget(covariant HomeScreen old) {
    super.didUpdateWidget(old);
    if (widget.santriLoggedIn && !old.santriLoggedIn) {
      _loadSantri();
      _loadPengumumanTerbaru();
    } else if (!widget.santriLoggedIn && old.santriLoggedIn) {
      setState(() {
        _santriMe = null;
        _santriStatus = null;
        _pengumumanTerbaru = [];
      });
      _loadPengumumanTerbaru();
    }
  }

  /// Data santri untuk kartu masa aktif di Beranda. Memakai sesi SIAKAD
  /// yang tersimpan (sama seperti portal); gagal apa pun → kartu tak tampil.
  Future<void> _loadSantri() async {
    try {
      final api = _santriApi ??= SantriApi();
      if (!await api.restore()) return;
      final me = obj(await api.call('/api/santri/me'));
      if (me['santri'] == null) return;
      Json? status;
      try {
        status = obj(await api.call('/api/santri/me/status'));
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _santriMe = me;
        _santriStatus = status;
      });
    } catch (_) {}
  }

  String? get _santriNama {
    if (_santriMe == null) return null;
    final n = val(obj(_santriMe?['santri'])['nama']);
    return n == '—' ? null : n;
  }

  /// Program.kategori riwayat berjalan (fallback: flag menu portal).
  String? get _lembagaKategori {
    final riwayat = rows(_santriMe?['riwayat']);
    if (riwayat.isNotEmpty) {
      final k = val(riwayat.first['programKategori']);
      if (k != '—' && k.isNotEmpty) return k;
    }
    final menu = obj(_santriMe?['menu']);
    if (menu['isTurats'] == true) return 'TURATS';
    if (menu['isHufadz'] == true) return 'HUFADZ';
    return null;
  }

  void _openSiakad() {
    if (widget.onOpenSiakad != null) {
      widget.onOpenSiakad!();
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SiakadPortalScreen()));
    }
  }

  /// Kartu santri di Beranda: lembaga + periode berjalan + masa aktif
  /// (sisa bulan dan kira-kira sampai periode berapa, dalam istilah lembaga).
  Widget _santriCard() {
    final riwayat = rows(_santriMe?['riwayat']);
    final kategori = _lembagaKategori;
    final masa = obj(obj(_santriStatus?['data'])['masaAktif']);
    final num? sisaRaw = masa['sisaBulanBerjalan'] ?? masa['sisaKoutaBulan'];
    final int? sisaBulan = sisaRaw?.round();
    final sekarangNum = dufahNum(
            adjustDufahName(val(obj(masa['dufahSekarangSistem'])['nama']))) ??
        dufahNum(val(riwayat.isEmpty ? null : riwayat.first['dufahNama']));
    final berakhirNum =
        dufahNum(adjustDufahName(val(masa['berakhirPadaDufahNama'])));
    final periodeSekarang = sekarangNum == null
        ? null
        : lembagaPeriodeLabel(kategori, sekarangNum);
    final periodeBerakhir = berakhirNum == null
        ? null
        : lembagaPeriodeLabel(kategori, berakhirNum);
    final low = sisaBulan != null && sisaBulan <= 2;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lembagaLabel(kategori),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (periodeSekarang != null) ...[
                    const SizedBox(height: 4),
                    Text('Periode berjalan: $periodeSekarang',
                        style: const TextStyle(color: MarkazColors.muted)),
                  ],
                  if (masa.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${sisaBulan ?? '—'}',
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Flexible(
                              child: Text('bulan tersisa',
                                  style:
                                      TextStyle(color: MarkazColors.muted))),
                        ]),
                    if (periodeBerakhir != null) ...[
                      const SizedBox(height: 8),
                      Text('Kira-kira sampai $periodeBerakhir',
                          style: const TextStyle(color: MarkazColors.muted)),
                    ],
                    if (sisaBulan != null) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                          value: (sisaBulan / 12).clamp(0.0, 1.0)),
                    ],
                    if (low) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              onPressed: _openSiakad,
                              icon: const Icon(Icons.autorenew_rounded),
                              label: const Text('Segera Daftar Ulang'))),
                    ],
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text('Masa aktif belum dapat dimuat.',
                        style: TextStyle(color: MarkazColors.muted)),
                  ],
                ])));
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
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
            Row(children: [
              Expanded(
                  child: Text('Markaz Arabiyah Tech',
                      style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(
                  tooltip: 'Notifikasi',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: _openPengumuman),
            ]),
            const SizedBox(height: 16),
            RepaintBoundary(child: WelcomePanel(name: _santriNama)),
            if (_santriMe != null) ...[
              const SizedBox(height: 16),
              _santriCard(),
            ],
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
            Text('Ibadah & layanan',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildGridMenu(context),
            const SizedBox(height: 24),
            _buildPengumumanTerbaru(context),
            _buildSectionTitle('Artikel', context),
            const SizedBox(height: 12),
            _buildArticleCarousel(context),
            const SizedBox(height: 24),
            _buildSocialSection(context),
          ])));
  }

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


  // ══════════════════════════════════════════════════════════
  // BUTIR 6 — PENDAFTARAN
  // ══════════════════════════════════════════════════════════
  /// Tile Pendaftaran: tamu memilih lembaga dulu (teks sama persis dengan
  /// PPDB) lalu dibuka di browser luar; sudah login jadi Daftar Ulang
  /// (alur portal yang sudah ada).
  Future<void> _openPendaftaran() async {
    final loggedIn = _santriMe != null || widget.santriLoggedIn;
    if (loggedIn) {
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const SiakadPortalScreen(initialFeature: 'Daftar ulang')));
      return;
    }
    final kategori = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (c) => ListView(shrinkWrap: true, children: [
        const ListTile(title: Text('Pilih Lembaga')),
        for (final (nama, desc, kode) in [
          (
            'Program Reguler',
            'Fokus intensif pembelajaran Bahasa Arab.',
            'REGULER'
          ),
          (
            'Program Turats',
            'Fokus pembelajaran kutubut turats (Fathul Qorib, Ibnu Aqil, dll).',
            'TUROTS'
          ),
          ('Program Hufadz', "Fokus tahfidz Al-Qur'an.", 'HUFADZ'),
        ])
          ListTile(
            title: Text(nama),
            subtitle: Text(desc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(c, kode),
          ),
      ]),
    );
    if (kategori == null || !mounted) return;
    final uri = Uri.parse(
        'https://ppdb.markazarabiyah.site/pendaftaran?kategori=$kategori');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ══════════════════════════════════════════════════════════
  // BUTIR 7 — CAROUSEL ARTIKEL (5 terbaru, auto-slide 5 detik)
  // ══════════════════════════════════════════════════════════
  Future<void> _loadArtikelCarousel() async {
    // Carousel hanya butuh 10 terbaru (bukan 100): muatan jauh lebih
    // ringan sehingga muat sebelum batas waktu di koneksi lambat.
    final list = await ApiService.getArticles(perPage: 10);
    if (!mounted) return;
    setState(() {
      _artikelCarousel = (list ?? []).take(5).toList();
      _artikelGagal = list == null;
      _artikelPage = 0;
    });
    _mulaiTimerArtikel();
  }

  void _mulaiTimerArtikel() {
    _artikelTimer?.cancel();
    if (_artikelCarousel.length < 2) return;
    _artikelTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final c = _artikelCtrl;
      if (c == null || !c.hasClients || _artikelCarousel.isEmpty) return;
      final next = (_artikelPage + 1) % _artikelCarousel.length;
      c.animateToPage(next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    });
  }

  Widget _buildArticleCarousel(BuildContext ctx) {
    if (_artikelGagal || _artikelCarousel.isEmpty) {
      return MarkazState(
          title: 'Artikel belum dapat dimuat',
          message: 'Periksa koneksi, lalu buka lagi halaman Beranda.',
          actionLabel: 'Coba lagi',
          onAction: _loadArtikelCarousel);
    }
    _artikelCtrl ??= PageController();
    final items = _artikelCarousel;
    return Column(children: [
      SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _artikelCtrl,
          itemCount: items.length,
          onPageChanged: (i) {
            setState(() => _artikelPage = i);
            _mulaiTimerArtikel();
          },
          itemBuilder: (context, index) {
            final a = items[index] as Map<String, dynamic>;
            final title = plainText(a['title']?['rendered'] ?? '');
            final img = articleImage(a);
            final rtl = isArabicText(title);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: MarkazColors.ivory,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(article: a))),
                  child: Stack(fit: StackFit.expand, children: [
                    if (img != null && img.isNotEmpty)
                      CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const SizedBox.shrink()),
                    Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                          Colors.transparent,
                          Colors.black54
                        ]))),
                    Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Directionality(
                                  textDirection: rtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  child: Text(title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700))),
                              const SizedBox(height: 4),
                              Text(articleDate(a),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ])),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < items.length; i++)
          Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _artikelPage
                      ? MarkazColors.gold
                      : MarkazColors.line)),
      ]),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // BUTIR 4 — PENGUMUMAN TERBARU DI BERANDA + LONCENG
  // ══════════════════════════════════════════════════════════
  /// Muat 3 pengumuman terbaru: login → lembaga + global
  /// (/api/santri/pengumuman); tamu → global saja
  /// (/api/pengumuman/publik, endpoint publik baru di Siakad).
  Future<void> _loadPengumumanTerbaru() async {
    try {
      final api = _santriApi ??= SantriApi();
      final loggedIn = await api.restore();
      final d = obj(await api.call(
          loggedIn ? '/api/santri/pengumuman' : '/api/pengumuman/publik'));
      if (!mounted) return;
      setState(() => _pengumumanTerbaru = rows(d['items']).take(3).toList());
    } catch (_) {
      // Gagal memuat: seksi pengumuman disembunyikan.
    }
  }

  String _tanggalPengumuman(dynamic v) {
    final dt = v is String ? DateTime.tryParse(v) : null;
    if (dt == null) return '';
    return DateFormat('d MMM yyyy', 'id_ID').format(dt);
  }

  Widget _buildPengumumanTerbaru(BuildContext ctx) {
    if (_pengumumanTerbaru.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text('Pengumuman Terbaru',
                style: Theme.of(ctx).textTheme.titleLarge)),
        TextButton(
            onPressed: _openPengumuman, child: const Text('Lihat Semua')),
      ]),
      const SizedBox(height: 8),
      for (final p in _pengumumanTerbaru)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(val(p['judul']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: p['sudahDibaca'] == true
                        ? FontWeight.w500
                        : FontWeight.w700)),
            subtitle: Text(
                '${val(p['pengirimLabel'])} · ${_tanggalPengumuman(p['dibuatAt'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            trailing: p['sudahDibaca'] == true
                ? null
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: MarkazColors.gold,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('Baru',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: MarkazColors.ink))),
            onTap: () => _openPengumumanItem(p),
          ),
        ),
      const SizedBox(height: 24),
    ]);
  }

  /// Lonceng Beranda: login → inbox Pengumuman di portal; tamu → daftar
  /// pengumuman global (endpoint publik, tanpa login).
  void _openPengumuman() {
    final loggedIn = _santriMe != null || widget.santriLoggedIn;
    if (loggedIn) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const SiakadPortalScreen(initialFeature: 'Pengumuman')));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const PublicPengumumanScreen()));
    }
  }

  /// Buka satu pengumuman dari seksi Beranda: tampilkan isi lengkap,
  /// tandai dibaca bila login (sama seperti inbox portal).
  Future<void> _openPengumumanItem(Json p) async {
    final loggedIn = _santriMe != null || widget.santriLoggedIn;
    final id = val(p['id']);
    if (loggedIn && p['sudahDibaca'] != true && id.isNotEmpty) {
      // Optimistis: ubah warna + turunkan badge LANGSUNG, jangan tunggu
      // server — di koneksi lambat konfirmasi POST telat/gagal diam-diam
      // sehingga warna baru berubah setelah refresh. Bila POST gagal,
      // kembalikan tampilan belum dibaca.
      if (mounted) {
        setState(() => p['sudahDibaca'] = true);
        SantriPush.unreadCount.value =
            (SantriPush.unreadCount.value - 1).clamp(0, 1 << 30);
      }
      try {
        final api = _santriApi ??= SantriApi();
        await api.call(
            '/api/santri/pengumuman/${Uri.encodeComponent(id)}/baca',
            method: 'POST');
      } catch (_) {
        if (mounted) {
          setState(() => p['sudahDibaca'] = false);
          SantriPush.unreadCount.value =
              SantriPush.unreadCount.value + 1;
        }
      }
    }
    if (!mounted) return;
    final tautan = val(p['tautan']);
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(val(p['judul'])),
        content: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                  '${val(p['pengirimLabel'])} · ${_tanggalPengumuman(p['dibuatAt'])}',
                  style: const TextStyle(
                      color: MarkazColors.muted, fontSize: 13)),
              const SizedBox(height: 12),
              Text(val(p['isi'])),
            ])),
        actions: [
          if (tautan.startsWith('https://'))
            TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  launchUrl(Uri.parse(tautan),
                      mode: LaunchMode.externalApplication);
                },
                child: const Text('Buka tautan')),
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext ctx) {
    void page(Widget page) =>
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
    // Butir 6: tile pertama = Pendaftaran (tamu) / Daftar Ulang (login).
    final loggedIn = _santriMe != null || widget.santriLoggedIn;
    final items = <(String, IconData, VoidCallback)>[
      (
        loggedIn ? 'Daftar Ulang' : 'Pendaftaran',
        Icons.app_registration_rounded,
        _openPendaftaran
      ),
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
    // Butir 8: tampilan ciut = 7 konten + card "Lainnya" (maks. 8 tombol);
    // ketuk "Lainnya" menampilkan semua, ketuk "Tutup" menciutkan lagi.
    final shown = <(String, IconData, VoidCallback)>[
      if (_menuExpanded) ...[
        ...items,
        (
          'Tutup',
          Icons.expand_less_rounded,
          () => setState(() => _menuExpanded = false),
        ),
      ] else ...[
        ...items.take(7),
        (
          'Lainnya',
          Icons.more_horiz_rounded,
          () => setState(() => _menuExpanded = true),
        ),
      ],
    ];
    return FeatureGrid(children: [
      for (final item in shown)
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
                      builder: (_) => const ArticleListScreen()));
            },
            child: const Icon(Icons.chevron_right, color: kTextSec)),
      ]),
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
