import 'dart:async';

import '../widgets/markaz_components.dart';
import '../theme/markaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/push_service.dart';
import '../siakad/api.dart';
import '../siakad/catalog.dart';
import '../siakad/features.dart';
import '../siakad/prayer.dart';

class SiakadPortalScreen extends StatefulWidget {
  const SiakadPortalScreen(
      {super.key,
      this.isActive = true,
      this.onExit,
      this.onAuth,
      this.resultRequest = 0,
      this.initialFeature,
      this.api});
  final bool isActive;
  final VoidCallback? onExit;
  final ValueChanged<bool>? onAuth;
  final int resultRequest;
  final String? initialFeature;
  final SantriApi? api;
  @override
  State<SiakadPortalScreen> createState() => _Portal();
}

class _Portal extends State<SiakadPortalScreen> {
  late final api = widget.api ?? SantriApi();
  late final push = SantriPush(api);
  final nis = TextEditingController();
  Json? me;
  Json? statusData;
  String? error, detail;
  bool busy = true, pending = false;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    pending = widget.resultRequest > 0 || widget.initialFeature != null;
    api.onExpired = expired;
    push.pendingLink.addListener(_onPendingLink);
    restore();
  }

  /// Ketukan notifikasi: buka tautan eksternal, atau buka inbox
  /// Pengumuman (dan satu pengumumannya bila ada id).
  void _onPendingLink() {
    final link = push.pendingLink.value;
    if (link == null || link.isEmpty) return;
    push.pendingLink.value = null;
    if (link.externalUrl != null) {
      unawaited(launchUrl(Uri.parse(link.externalUrl!),
          mode: LaunchMode.externalApplication));
      return;
    }
    if (!mounted) return;
    SantriPush.openPengumumanId = link.pengumumanId;
    open(features.firstWhere((f) => f.title == 'Pengumuman'));
  }

  void expired() {
    if (!mounted) return;
    SantriPush.unreadCount.value = 0;
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() {
      me = null;
      statusData = null;
      detail = null;
      tab = 0;
      error = 'Sesi berakhir. Masuk kembali.';
    });
    widget.onAuth?.call(false);
  }

  Future<void> restore() async {
    try {
      if (await api.restore()) await identity();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> identity() async {
    final data = obj(await api.call('/api/santri/me'));
    if (data['santri'] == null)
      throw const PortalError('Profil tidak dapat dibaca.');
    if (!mounted) return;
    setState(() {
      me = data;
      error = null;
      if (pending) {
        // Fitur awal yang diminta pemanggil (mis. 'Pengumuman' dari lonceng
        // Beranda, 'Daftar ulang' dari tile Pendaftaran); tanpa itu,
        // perilaku lama: buka 'Hasil Tes'.
        final target = widget.initialFeature ?? 'Hasil Tes';
        final matches =
            features.where((f) => f.title == target).toList();
        detail = matches.isNotEmpty ? matches.first.title : 'Hasil Tes';
        tab = matches.isNotEmpty ? matches.first.tab : 1;
        pending = false;
      }
    });
    widget.onAuth?.call(true);
    loadStatus();
    // Push FCM: daftarkan perangkat + muat badge belum-dibaca.
    unawaited(push.registerAfterLogin());
    unawaited(push.refreshUnread());
  }

  /// Masa aktif (PPDB me/status) untuk kartu Beranda. Gagal memuat
  /// tidak mengganggu login — kartu tinggal tidak tampil.
  Future<void> loadStatus() async {
    try {
      final s = obj(await api.call('/api/santri/me/status'));
      if (mounted) setState(() => statusData = s);
    } catch (_) {}
  }

  /// Kartu Masa aktif ala dashboard website; null bila datanya belum ada.
  Widget? masaAktifCard() {
    final masa = obj(obj(statusData?['data'])['masaAktif']);
    if (masa.isEmpty) return null;
    final num? sisaRaw = masa['sisaBulanBerjalan'] ?? masa['sisaKoutaBulan'];
    final int? sisaBulan = sisaRaw?.round();
    final berakhir = adjustDufahName(val(masa['berakhirPadaDufahNama']));
    final berjalan =
        adjustDufahName(val(obj(masa['dufahSekarangSistem'])['nama']));
    final berakhirTampil = berakhir != '—' && berakhir != 'Belum Ditentukan';
    final berjalanTampil = berjalan != '—' && berjalan != 'Belum Ditentukan';
    final low = sisaBulan != null && sisaBulan <= 2;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masa aktif',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
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
                  if (berakhirTampil) ...[
                    const SizedBox(height: 8),
                    Text('Berakhir pada: $berakhir',
                        style: const TextStyle(color: MarkazColors.muted)),
                  ],
                  if (berjalanTampil) ...[
                    const SizedBox(height: 4),
                    Text('Sedang berjalan: $berjalan',
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
                            onPressed: () => open(features.firstWhere(
                                (f) => f.title == 'Daftar ulang')),
                            icon: const Icon(Icons.autorenew_rounded),
                            label: const Text('Segera Daftar Ulang'))),
                  ],
                ])));
  }

  Future<void> login() async {
    if (busy || nis.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (api.session == null) {
        await api.call('/api/santri/auth/login',
            method: 'POST', body: {'nis': nis.text.trim()});
      }
      await identity();
      nis.clear();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant SiakadPortalScreen old) {
    super.didUpdateWidget(old);
    if (widget.resultRequest != old.resultRequest) {
      if (me == null) {
        pending = true;
      } else {
        tab = 1;
        detail = 'Hasil Tes';
      }
    } else if (widget.isActive && !old.isActive && me != null) {
      tab = 0;
      detail = null;
      identity().catchError((Object e) {
        if (mounted) setState(() => error = e.toString());
      });
    }
  }

  @override
  void dispose() {
    api.onExpired = null;
    push.pendingLink.removeListener(_onPendingLink);
    if (widget.api == null) api.dispose();
    nis.dispose();
    super.dispose();
  }

  void exit() {
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      Navigator.pop(context);
    }
  }

  void back() {
    if (detail != null) {
      setState(() => detail = null);
    } else if (tab != 0) {
      setState(() => tab = 0);
    } else {
      exit();
    }
  }

  void open(Feature f) => setState(() {
        detail = f.title;
        tab = f.tab;
      });
  List<Feature> get allowed => features.where((f) {
        final r = obj(me?['menu']);
        if (f.title == 'QR Saya' && obj(me?['santri'])['isAktif'] != true)
          return false;
        return f.role == null ||
            (f.role == 'pelapor'
                ? (r['isJasus'] == true || r['isLajnah'] == true)
                : r[f.role] == true);
      }).toList();
  Widget cards(List<Feature> items) => FeatureGrid(children: [
        for (final f in items)
          FeatureCard(
              // Website: santri Turats melihat "Pemilihan OSIM".
              // Nama internal tetap 'Pemilihan' agar FeaturePage tak berubah.
              label: f.title == 'Pemilihan' &&
                      obj(me?['menu'])['isTurats'] == true
                  ? 'Pemilihan OSIM'
                  : f.title,
              icon: f.icon,
              onTap: () => open(f)),
      ]);
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    final user = obj(me?['santri']);
    final history = rows(me?['riwayat']);
    final signed = me != null;
    final masaCard = masaAktifCard();
    return PopScope(
        canPop: !widget.isActive ||
            (widget.onExit == null && detail == null && tab == 0),
        onPopInvokedWithResult: (did, _) {
          if (!did && widget.isActive) back();
        },
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: detail != null || !signed
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back), onPressed: back)
                    : null,
                title: Text(detail ?? (tab == 3 ? 'Profil' : 'SIAKAD'),
                    maxLines: 2, style: const TextStyle(fontSize: 17)),
                actions: [
                  if (signed)
                    ValueListenableBuilder<int>(
                        valueListenable: SantriPush.unreadCount,
                        builder: (_, count, __) => IconButton(
                            tooltip: 'Pengumuman',
                            onPressed: () => open(features.firstWhere(
                                (f) => f.title == 'Pengumuman')),
                            icon: Badge.count(
                                count: count.clamp(0, 99),
                                isLabelVisible: count > 0,
                                child: const Icon(
                                    Icons.notifications_outlined)))),
                  if (signed)
                    if (MediaQuery.sizeOf(context).width /
                            MediaQuery.textScalerOf(context).scale(1) <
                        280)
                      IconButton(
                          tooltip: 'Halaman umum',
                          onPressed: exit,
                          icon: const Icon(Icons.home_outlined))
                    else
                      TextButton.icon(
                          onPressed: exit,
                          icon: const Icon(Icons.home_outlined, size: 18),
                          label: const Text('Halaman umum'))
                ]),
            body: SafeArea(
                child: !signed
                    ? ListView(padding: const EdgeInsets.all(24), children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: MarkazMascot(size: 120)),
                        const SizedBox(height: 20),
                        Text('Masuk sebagai santri',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        const Text(
                            'Gunakan Nomor Induk Santri yang sama dengan akun website.'),
                        const SizedBox(height: 32),
                        TextField(
                            controller: nis,
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                                labelText: 'Nomor Induk Santri',
                                prefixIcon: Icon(Icons.badge_outlined)),
                            onSubmitted: (_) => login()),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(error!,
                                  style: const TextStyle(
                                      color: MarkazColors.danger))),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: busy
                                ? null
                                : api.session != null
                                    ? restore
                                    : login,
                            child: Text(busy
                                ? 'Memeriksa sesi…'
                                : api.session != null
                                    ? 'Muat ulang profil'
                                    : 'Masuk'))
                      ])
                    : detail != null && detail != 'Semua fitur'
                        ? FeaturePage(
                            key: ValueKey('${user['id']}:$detail'),
                            name: detail!,
                            me: me!,
                            api: api,
                            onChanged: identity)
                        : tab == 3
                            ? FeaturePage(
                                name: 'Akun',
                                me: me!,
                                api: api,
                                onChanged: identity,
                                onLogout: () async {
                                  try {
                                    // Hapus token FCM perangkat sebelum sesi
                                    // dihapus, agar santri tak lagi menerima
                                    // push setelah keluar akun.
                                    await push.unregisterBeforeLogout();
                                    await api.logout();
                                  } finally {
                                    expired();
                                    if (mounted) setState(() => error = null);
                                  }
                                })
                            : ListView(
                                padding: const EdgeInsets.all(18),
                                children: [
                                    if (error != null)
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Text(error!,
                                              style: const TextStyle(
                                                  color: MarkazColors.danger))),
                                    if (tab == 0 && detail == null) ...[
                                      WelcomePanel(name: val(user['nama'])),
                                      const SizedBox(height: 12),
                                      if (history.isNotEmpty)
                                        Text(
                                            "${val(history.first['kelasNama'])} · ${val(history.first['programNama'])}"),
                                      if (masaCard != null) ...[
                                        const SizedBox(height: 16),
                                        masaCard,
                                      ],
                                      const SizedBox(height: 16),
                                      const PrayerPanel(),
                                      Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 16,
                                          children: [
                                            const Text('Fitur santri'),
                                            TextButton(
                                                onPressed: () => setState(() =>
                                                    detail = 'Semua fitur'),
                                                child:
                                                    const Text('Semua fitur'))
                                          ]),
                                      cards(allowed.take(6).toList()),
                                      if (history.any((h) =>
                                          rows(h['perizinan']).any((p) =>
                                              p['statusIzin'] == 'AKTIF' &&
                                              ['KELUAR_PARE', 'BERHARI_HARI']
                                                  .contains(p['tipeIzin']) &&
                                              p['selfieAt'] == null)))
                                        ListTile(
                                            leading: const Icon(
                                                Icons.camera_alt_outlined),
                                            title: const Text(
                                                'Konfirmasi kembali'),
                                            subtitle: const Text(
                                                'Lihat tasrih aktif'),
                                            onTap: () => open(features[4])),
                                      for (final u
                                          in rows(me?['ujianAktif']).take(1))
                                        ListTile(
                                            title: Text(val(u['nama'])),
                                            trailing:
                                                const Icon(Icons.chevron_right),
                                            onTap: () => open(features[2]))
                                    ] else ...[
                                      Text(
                                          detail ??
                                              (tab == 1
                                                  ? 'Akademik'
                                                  : 'Layanan santri'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall),
                                      const SizedBox(height: 16),
                                      cards(allowed
                                          .where((f) =>
                                              detail != null || f.tab == tab)
                                          .toList())
                                    ]
                                  ])),
            bottomNavigationBar: !signed
                ? null
                : MarkazNavigation(
                    index: tab,
                    onSelect: (v) => setState(() {
                          tab = v;
                          detail = null;
                        }),
                    items: const [
                        (Icons.home_rounded, 'Beranda'),
                        (Icons.menu_book_rounded, 'Akademik'),
                        (Icons.assignment_rounded, 'Layanan'),
                        (Icons.person_rounded, 'Akun'),
                      ])));
  }
}
