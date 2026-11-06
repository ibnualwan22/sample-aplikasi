import 'package:flutter/material.dart';
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
  final nis = TextEditingController();
  Json? me;
  String? error, detail;
  bool busy = true, pending = false;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    pending = widget.resultRequest > 0 || widget.initialFeature == 'Hasil Tes';
    api.onExpired = expired;
    restore();
  }

  void expired() {
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() {
      me = null;
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
        detail = 'Hasil Tes';
        tab = 1;
        pending = false;
      }
    });
    widget.onAuth?.call(true);
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
  Widget cards(List<Feature> items) => LayoutBuilder(builder: (c, box) {
        final scale = MediaQuery.textScalerOf(c).scale(14) / 14;
        final n = (box.maxWidth / (95 * scale)).floor().clamp(1, 4);
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in items)
            SizedBox(
                width: (box.maxWidth - (n - 1) * 8) / n,
                child: Material(
                    color: const Color(0xff202020),
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                        onTap: () => open(f),
                        borderRadius: BorderRadius.circular(9),
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(f.icon,
                                      color: Theme.of(c).colorScheme.primary),
                                  const SizedBox(height: 9),
                                  Text(f.title)
                                ])))))
        ]);
      });
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    final user = obj(me?['santri']);
    final history = rows(me?['riwayat']);
    final signed = me != null;
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
                title: Text(detail ?? 'SIAKAD Markaz Arabiyah',
                    maxLines: 2, style: const TextStyle(fontSize: 17)),
                actions: [
                  if (signed)
                    TextButton.icon(
                        onPressed: exit,
                        icon: const Icon(Icons.home_outlined, size: 18),
                        label: const Text('Halaman umum'))
                ]),
            body: SafeArea(
                child: !signed
                    ? ListView(padding: const EdgeInsets.all(24), children: [
                        const SizedBox(height: 48),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(Icons.school_outlined, size: 40)),
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
                            decoration: const InputDecoration(
                                labelText: 'Nomor Induk Santri',
                                border: OutlineInputBorder()),
                            onSubmitted: (_) => login()),
                        if (error != null) Text(error!),
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
                                    await api.logout();
                                  } finally {
                                    expired();
                                    if (mounted) setState(() => error = null);
                                  }
                                })
                            : ListView(
                                padding: const EdgeInsets.all(18),
                                children: [
                                    if (error != null) Text(error!),
                                    if (tab == 0 && detail == null) ...[
                                      Text(val(user['nama']),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall),
                                      if (history.isNotEmpty)
                                        Text(
                                            "${val(history.first['kelasNama'])} · ${val(history.first['programNama'])}"),
                                      const SizedBox(height: 16),
                                      const PrayerPanel(),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                : BottomNavigationBar(
                    currentIndex: tab,
                    onTap: (v) => setState(() {
                          tab = v;
                          detail = null;
                        }),
                    items: const [
                        BottomNavigationBarItem(
                            icon: Icon(Icons.home_outlined), label: 'Beranda'),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.menu_book_outlined),
                            label: 'Akademik'),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.assignment_outlined),
                            label: 'Layanan'),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.person_outline), label: 'Akun')
                      ])));
  }
}
