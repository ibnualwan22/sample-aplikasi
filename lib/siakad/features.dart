import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart' show Html;
import 'api.dart';
import 'exam.dart';
import 'scan.dart';
import 'file_view.dart';
part 'services.dart';

class FeaturePage extends StatefulWidget {
  const FeaturePage(
      {super.key,
      required this.name,
      required this.me,
      required this.api,
      required this.onChanged,
      this.onLogout});
  final String name;
  final Json me;
  final SantriApi api;
  final Future<void> Function() onChanged;
  final Future<void> Function()? onLogout;
  @override
  State<FeaturePage> createState() => _Page();
}

class _Page extends State<FeaturePage> {
  List<LatLng> route = [];
  final map = MapController();
  dynamic data;
  Json extra = {};
  String? error, period;
  bool loading = true, working = false;
  Timer? timer;
  late Json profile;
  http.Client? live;
  String? liveId;
  Future<void> subscribeVotes(String id) async {
    if (id == liveId) return;
    live?.close();
    final client = http.Client();
    live = client;
    liveId = id;
    try {
      final req = http.Request(
          'GET',
          api.origin.resolve(
              '/api/santri/$election/stream?sesiId=${Uri.encodeQueryComponent(id)}'))
        ..followRedirects = false;
      req.headers.addAll({
        'Accept': 'text/event-stream',
        'Cookie': 'santri-session=${api.session}'
      });
      final res = await client.send(req);
      if (res.statusCode != 200) return;
      await for (final line in res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!mounted || live != client) break;
        if (!line.startsWith('data:')) continue;
        final d = obj(jsonDecode(line.substring(5)));
        if (obj(data?['sesi'])['id'] != id) continue;
        setState(() {
          final counts = obj(d['suara']);
          for (final p in (data['paslon'] as List? ?? [])) {
            if (counts.containsKey(p['id'])) p['suara'] = counts[p['id']];
          }
          if (d['status'] != null) data['sesi']['status'] = d['status'];
          if (d['status'] == 'TUTUP') data['bolehMemilih'] = false;
        });
      }
    } catch (_) {
      /* Periodic refresh continues if the stream is unavailable. */
    } finally {
      client.close();
      if (live == client) {
        live = null;
        liveId = null;
      }
    }
  }

  String get name => widget.name;
  Json get user => obj(profile['santri']);
  List<Json> get history => rows(profile['riwayat']);
  SantriApi get api => widget.api;
  String get election => obj(profile['menu'])['isTurats'] == true
      ? 'pemilihan-osim'
      : 'pemilihan-lajnah';
  String get endpoint =>
      {
        'Hasil Tes': '/api/mobile/hasil-tes',
        'QR Saya': 'qr-saya',
        'Daftar ulang': 'me/daftar-ulang',
        'WhatsApp AI': 'me/no-wa',
        'Pemilihan': election,
        'Tasmi’': 'tasmi',
        'Nadi Hufadz': 'nadi-hufadz',
        'Galeri': 'arsip-galeri',
        'Denah Sakan': 'denah-lokasi',
        'Berita Acara': 'me/berita-acara',
        'Lapor Mukholif': 'mukholif',
        'Eksekusi Iqob': 'eksekusi-mukholif',
        'Check out': 'checkout',
        'Ujian': 'ujian',
        'Tauzi’ Fushul': 'me/tauzi',
        'Akun': 'me/status'
      }[name] ??
      'me';
  Future<dynamic> get(String p, {Json? body, String? method}) =>
      api.call(p.startsWith('/') ? p : '/api/santri/$p',
          method: method ?? (body == null ? 'GET' : 'POST'), body: body);
  @override
  void initState() {
    super.initState();
    profile = widget.me;
    load();
    if (name == 'QR Saya' || name == 'Pemilihan')
      timer = Timer.periodic(const Duration(seconds: 6), (_) async {
        if (!mounted ||
            loading ||
            working ||
            ModalRoute.of(context)?.isCurrent != true) return;
        try {
          if (name == 'QR Saya') {
            final d = await get('qr-saya/status');
            if (mounted) setState(() => extra = obj(d));
          } else {
            final d = await get(endpoint);
            if (mounted) setState(() => data = d);
          }
        } catch (_) {}
      });
  }

  @override
  void dispose() {
    live?.close();
    timer?.cancel();
    map.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await get(endpoint +
          (name == 'Galeri' && period != null
              ? '?dufahNama=${Uri.encodeQueryComponent(period!)}'
              : ''));
      if (name == 'Pemilihan' && mounted && obj(d['sesi'])['id'] != null) {
        unawaited(subscribeVotes(val(d['sesi']['id'])));
      }
      Json x = {};
      if (name == 'Daftar ulang' && obj(d['data'])['pending'] == null)
        x = obj(await get('me/status'));
      if (name == 'QR Saya') x = obj(await get('qr-saya/status'));
      if (mounted)
        setState(() {
          data = d;
          extra = x;
          if (endpoint == 'me') profile = obj(d);
        });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> run(Future<void> Function() fn) async {
    if (working || !mounted) return;
    setState(() => working = true);
    try {
      await fn();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> send(String p, Json body, {String method = 'POST'}) async {
    try {
      await get(p, body: body, method: method);
    } on PortalError catch (e) {
      if (e.code == 0 || e.code == 409) {
        await load();
      }
      rethrow;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersimpan di SIAKAD.')));
    await load();
  }

  Future<bool> confirm(String title, String msg) async =>
      await showDialog<bool>(
          context: context,
          builder: (c) =>
              AlertDialog(title: Text(title), content: Text(msg), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Lanjutkan'))
              ])) ??
      false;
  Future<String?> ask(String title,
      {String hint = '', String initial = ''}) async {
    String answer = initial;
    return showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(title),
                content: TextFormField(
                    initialValue: initial,
                    autofocus: true,
                    decoration: InputDecoration(hintText: hint),
                    onChanged: (v) => answer = v),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () {
                        if (answer.trim().isNotEmpty)
                          Navigator.pop(c, answer.trim());
                      },
                      child: const Text('Lanjutkan'))
                ]));
  }

  Future<String?> choose(String title, List<(String, String)> options) async =>
      showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (c) => SafeArea(
                  child: ListView(shrinkWrap: true, children: [
                ListTile(
                    title:
                        Text(title, style: Theme.of(c).textTheme.titleLarge)),
                for (final e in options)
                  ListTile(
                      title: Text(e.$2), onTap: () => Navigator.pop(c, e.$1))
              ])));
  Widget action(String title, Future<void> Function() fn,
          {IconData icon = Icons.chevron_right}) =>
      OutlinedButton.icon(
          onPressed: working ? null : () => run(fn),
          icon: Icon(icon),
          label: Text(title));
  Widget tile(dynamic title, [dynamic sub, dynamic end]) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(val(title)),
      subtitle: sub == null ? null : Text(val(sub)),
      trailing: end == null ? null : Text(val(end)));
  String fields(Json m, List<String> keys) => keys
      .where((k) => m[k] != null && m[k] != '')
      .map((k) => val(m[k]))
      .join(' · ');
  String date(dynamic v) => v == null ? '—' : v.toString().split('T').first;
  Widget group(String title, List<Widget> cs) => ExpansionTile(
      tilePadding: EdgeInsets.zero, title: Text(title), children: cs);
  Future<void> document(String kind, dynamic id) async {
    final d = obj(
        await get('/api/mobile/dokumen/$kind/${Uri.encodeComponent(val(id))}'));
    final format = PdfPageFormat((d['width'] as num) * PdfPageFormat.mm,
        (d['height'] as num) * PdfPageFormat.mm);
    final bytes = await Printing.convertHtml(
        html: d['html'], baseUrl: api.origin.toString(), format: format);
    if (!mounted) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SantriFileView(
                title: kind == 'transkrip' ? 'Transkrip nilai' : 'Syahadah',
                bytes: bytes,
                type: 'application/pdf',
                filename: '$kind.pdf',
                exportPng: kind == 'nadi')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = loading
        ? <Widget>[const Center(child: CircularProgressIndicator())]
        : error != null
            ? <Widget>[
                Text(error!),
                action('Coba lagi', load),
                if (name == 'Akun')
                  action('Keluar akun', () async {
                    await widget.onLogout?.call();
                  })
              ]
            : content();
    return RefreshIndicator(
        onRefresh: load,
        child: ListView(
            padding: const EdgeInsets.all(18),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (working) const LinearProgressIndicator(),
              if (cs.isEmpty) const Text('Belum ada data.') else ...cs
            ]));
  }

  List<Widget> content() {
    switch (name) {
      case 'Nilai':
      case 'Riwayat':
      case 'Absensi':
        return [
          for (final h in history)
            group(
                fields(h, ['dufahNama', 'programNama', 'kelasNama']),
                name == 'Absensi'
                    ? [
                        for (final k in [
                          'Kelas',
                          'Sakan',
                          'Kegiatan',
                          'Tabirot'
                        ])
                          group('Absensi $k', [
                            tile('Kehadiran',
                                "${obj(h['rekapAbsen$k'])['hadir']} dari ${obj(h['rekapAbsen$k'])['total']}"),
                            for (final a in rows(h['absen$k']))
                              tile(
                                  date(a['tanggal']),
                                  fields(a, [
                                    'sesi',
                                    'namaKegiatan',
                                    'namaKelompok',
                                    'keterangan'
                                  ]),
                                  a['status'])
                          ])
                      ]
                    : [
                        tile('Rata-rata', h['statusKelulusan'], h['average']),
                        for (final n in rows(h['nilaiRows']))
                          tile(
                              n['namaIndo'],
                              "Usbu 1: ${val(n['nilaiUsbu1'])} · Usbu 2: ${val(n['nilaiUsbu2'])} · Nihai: ${val(n['nilaiNihai'])}",
                              n['skor'] ?? '—'),
                        if (h['transkripGabungan'] != null)
                          group('Transkrip gabungan', [
                            for (final n
                                in rows(h['transkripGabungan']['nilaiRows']))
                              tile(n['namaIndo'], null, n['skor'])
                          ]),
                        action('Lihat transkrip nilai',
                            () => document('transkrip', h['id']),
                            icon: Icons.description_outlined),
                        if (h['canDownloadSyahadah'] == true)
                          action('Lihat syahadah',
                              () => document('syahadah', h['id']),
                              icon: Icons.download_outlined)
                      ])
        ];
      case 'Hasil Tes':
        return [
          tile('Periode', data['active_dufah']),
          for (final k in rows(data['data']))
            for (final s in rows(k['santri'])) ...[
              for (final u in rows(s['rata_rata_per_usbu']))
                tile(u['label'], null, u['rata_rata_nilai'] ?? '—'),
              for (final n in rows(s['nilai_per_mapel']))
                tile(
                    n['mapel'],
                    'Usbu 1: ${val(n['nilai_usbu_1'])} · Usbu 2: ${val(n['nilai_usbu_2'])}',
                    n['nilai_nihai'] ?? '—')
            ]
        ];
      case 'QR Saya':
        return [
          tile(user['nama'], 'Tunjukkan QR ini kepada petugas absensi.'),
          Center(
              child: QrImageView(
                  data: data['payload'],
                  size: 240,
                  backgroundColor: Colors.white)),
          action('Mode scan', () async {
            final status = await get('qr-saya/status');
            if (!mounted) return;
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ScanMode(
                        api: api,
                        payload: data['payload'],
                        initial: rows(status['hadir'])
                            .map((r) => val(r['kategoriId']))
                            .toSet())));
            if (mounted) await load();
          }, icon: Icons.qr_code_scanner),
          for (final a in rows(extra['hadir'])) tile(a['kategoriNama'], 'Hadir')
        ];
      case 'Akun':
        return [
          tile(user['nama'], 'NIS ${user['id']}'),
          tile('Sakan dan kamar', fields(user, ['sakan', 'kamar'])),
          tile('Nomor lemari', user['nomorLemari']),
          tile('Tempat dan tanggal lahir',
              fields(user, ['tempatLahir', 'tanggalLahir'])),
          tile('Alamat', user['alamat']),
          tile('Status', user['isAktif'] == true ? 'Aktif' : 'Tidak aktif'),
          tile(
              'Masa belajar',
              fields(obj(obj(data['data'])['masaAktif']),
                  ['berakhirPadaDufahNama'])),
          action('Ubah bulan belajar', () async {
            final v = await ask('Bulan ke-', initial: val(user['bulanKe']));
            if (v != null && int.tryParse(v) != null) {
              await send('me/update-bulan', {'bulanKe': int.parse(v)});
              await widget.onChanged();
              if (mounted) setState(() => profile = widget.me);
            }
          }),
          action('Kartu santri', () async {
            // The PPDB file provider must never receive the SIAKAD session cookie.
            final r = await http
                .get(Uri.https(
                    'ppdb.markazarabiyah.site',
                    '/api/digital-card/siakad/${user['id']}',
                    {'download': '1'}))
                .timeout(const Duration(seconds: 25));
            if (r.statusCode != 200)
              throw const PortalError('Kartu santri belum tersedia.');
            final b = r.bodyBytes;
            final mime = b.length > 4 &&
                    b[0] == 0x25 &&
                    b[1] == 0x50 &&
                    b[2] == 0x44 &&
                    b[3] == 0x46
                ? 'application/pdf'
                : b.length > 4 && b[0] == 0x89 && b[1] == 0x50
                    ? 'image/png'
                    : b.length > 3 && b[0] == 0xff && b[1] == 0xd8
                        ? 'image/jpeg'
                        : null;
            if (mime == null)
              throw const PortalError('Format kartu santri tidak didukung.');
            if (mounted)
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SantriFileView(
                          title: 'Kartu santri',
                          bytes: b,
                          type: mime,
                          filename:
                              'kartu-santri.${mime == 'image/jpeg' ? 'jpg' : mime.split('/').last}')));
          }),
          action('Keluar akun', () async {
            if (await confirm(
                'Keluar akun?', 'Sesi SIAKAD di perangkat ini akan dihapus.'))
              await widget.onLogout?.call();
          })
        ];
      case 'Ujian':
        return [
          for (final u in rows(data))
            group(val(u['nama']), [
              tile(val(u['status']),
                  "${u['jumlahSoal']} soal · ${u['durasiMenit']} menit"),
              if (['BELUM_MULAI', 'MENGERJAKAN'].contains(u['status']))
                action('Buka ujian', () async {
                  final kode = await ask('Kode akses ujian');
                  if (kode != null) {
                    final d = await get('ujian/start',
                        body: {'paketId': u['id'], 'kodeAkses': kode});
                    await exam(obj(d), false);
                  }
                }),
              for (final m in rows(u['mapelScores']))
                tile(m['mapelName'], null, m['score'] ?? '—'),
              if (u['showReview'] == true && u['sesiId'] != null)
                action('Review jawaban', () async {
                  final d = await get('ujian/review?sesiId=${u['sesiId']}');
                  if (mounted) await review(obj(d));
                })
            ])
        ];
      default:
        return services();
    }
  }

  Future<void> exam(Json d, bool tauzi) async {
    if (!mounted) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ExamPage(
                api: api, data: d, tauzi: tauzi, owner: val(user['id']))));
    if (mounted) await load();
  }

  Future<void> review(Json d) async {
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (c) => SafeArea(
                child: ListView(padding: const EdgeInsets.all(20), children: [
              tile(d['paketNama']),
              for (final m in rows(d['mapels']))
                group(val(m['namaMapel'] ?? m['mapelNama']), [
                  for (final g in rows(m['groups']))
                    for (final q in rows(g['soalList']))
                      ListTile(
                          title: Html(data: q['pertanyaan']),
                          subtitle: Text(q['statusEssay']?.toString() ??
                              (q['isCorrect'] == true
                                  ? 'Benar'
                                  : q['isCorrect'] == false
                                      ? 'Salah'
                                      : 'Belum dinilai')))
                ])
            ])));
  }

  Future<void> external(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication))
      throw const PortalError('Tautan tidak dapat dibuka.');
  }
}
