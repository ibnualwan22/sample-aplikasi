part of 'features.dart';

/// Format angka ke Rupiah, mis. "Rp 1.250.000".
String _rp(dynamic v) {
  final n = v is num ? v : (v == null ? null : num.tryParse(v.toString()));
  if (n == null) return '—';
  return 'Rp ${NumberFormat('id-ID').format(n)}';
}

/// Harga program (angka) dari `programTersedia`, null bila tak ada.
int? _hargaProgram(Json p) {
  final h = p['harga'];
  final n = h is num ? h : (h == null ? null : num.tryParse(h.toString()));
  return n?.round();
}

/// Harga yang dibayar tanpa atribut: harga − Rp 100.000 (min. 0),
/// mengikuti halaman daftar-ulang website (fix 32add8e).
int? _hargaDiskon(Json p) {
  final h = _hargaProgram(p);
  if (h == null) return null;
  final d = h - 100000;
  return d < 0 ? 0 : d;
}

/// Nama dufah ala website: angka pertama < 80 ditambah 80
/// (PPDB "Duf'ah 15" → tampil "Duf'ah 95").
String adjustDufahName(String name) {
  if (name.isEmpty || name == 'Belum Ditentukan') return name;
  return name.replaceFirstMapped(RegExp(r'\d+'), (m) {
    final n = int.tryParse(m.group(0)!);
    if (n == null) return m.group(0)!;
    return (n < 80 ? n + 80 : n).toString();
  });
}

/// Lembaga santri dari Program.kategori (mengikuti Siakad src/lib/lembaga.ts):
/// TURATS → Markaz Turats, HUFADZ → Markaz Hufadz, lainnya (REGULER/null)
/// → Markaz Arabiyah.
String lembagaLabel(String? kategori) {
  if (kategori == 'TURATS') return 'Markaz Turats';
  if (kategori == 'HUFADZ') return 'Markaz Hufadz';
  return 'Markaz Arabiyah';
}

/// Nama periode dalam istilah lembaganya. Nomor berjalan mengikuti Duf'ah:
/// Marhalah = Duf'ah − 89, Nukhbah = Duf'ah − 93 (acuan Bawwabah 94/5/1;
/// ketiga lembaga naik bersama, jadi selisihnya tetap).
String lembagaPeriodeLabel(String? kategori, int dufahNum) {
  if (kategori == 'TURATS') return 'Marhalah ${dufahNum - 89}';
  if (kategori == 'HUFADZ') return 'Nukhbah ${dufahNum - 93}';
  return "Duf'ah $dufahNum";
}

/// Angka pertama dari nama periode ("Duf'ah 95" → 95), null bila tak ada.
int? dufahNum(String? name) {
  if (name == null) return null;
  final m = RegExp(r'\d+').firstMatch(name);
  return m == null ? null : int.tryParse(m.group(0)!);
}

extension _Services on _Page {
  Future<void> permit() async {
    if (history.isEmpty) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ServiceRequestForm(
                  permit: true,
                  ownerId: val(history.first['id']),
                  searchPeople: (query) async =>
                      rows(await get('/api/public/perizinan'))
                          .where((s) => fields(s, ['nama', 'sakan'])
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                          .toList(),
                  onSubmit: (body) => send('me/perizinan', body),
                )));
  }

  Future<void> selfie(Json p) async {
    final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 75,
        maxWidth: 1100);
    if (photo == null) return;
    await send('me/perizinan/selfie', {
      'perizinanId': p['id'],
      'image':
          'data:image/jpeg;base64,${base64Encode(await photo.readAsBytes())}'
    });
  }

  Future<void> vote(Json s, Json p) async {
    if (await confirm('Kirim suara?',
        'Paslon ${p['nomorUrut']} · Pilihan yang terkirim tidak dapat diganti.'))
      await send('$election/vote', {'sesiId': s['id'], 'paslonId': p['id']});
  }

  List<Widget> services() {
    switch (name) {
      case 'Perizinan':
        return [
          if (history.isNotEmpty)
            action('Ajukan izin', permit, icon: Icons.add),
          if (history.every((h) => rows(h['perizinan']).isEmpty))
            const MarkazState(
                title: 'Belum ada riwayat izin',
                message: 'Pengajuan dan status izin Anda akan tampil di sini.'),
          for (final h in history)
            for (final p in rows(h['perizinan']))
              group(fields(p, ['tipeIzin', 'statusIzin']), [
                tile(p['alasan'], date(p['tanggalMulai'])),
                tile('Nomor tasrih', p['nomorTasrih']),
                if (p['grupTasrihId'] != null)
                  action('Lihat tasrih', () async {
                    final d = await get(
                        '/api/public/perizinan/tasrih/${p['grupTasrihId']}');
                    if (mounted)
                      await showModalBottomSheet(
                          context: context,
                          useSafeArea: true,
                          isScrollControlled: true,
                          constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * .85),
                          builder: (c) => ListView(
                                  padding: const EdgeInsets.all(18),
                                  children: [
                                    tile(
                                        d['nomorTasrih'],
                                        fields(obj(d),
                                            ['tipeIzin', 'statusIzin'])),
                                    tile(d['alasan'], date(d['tanggalMulai'])),
                                    for (final r in rows(d['records']))
                                      tile(
                                          obj(obj(r['riwayat'])['santri'])[
                                              'nama'],
                                          r['sakan'])
                                  ]));
                  }),
                if (p['tanggalKembali'] != null)
                  tile('Kembali', date(p['tanggalKembali'])),
                if (p['statusIzin'] == 'AKTIF' &&
                    ['KELUAR_PARE', 'BERHARI_HARI'].contains(p['tipeIzin']) &&
                    p['selfieAt'] == null)
                  action('Konfirmasi kembali dengan selfie', () => selfie(p),
                      icon: Icons.camera_alt_outlined)
              ])
        ];
      case 'Check out':
        final p = obj(data['pengajuan']);
        return [
          if (p.isNotEmpty) tile(p['status'], p['alasan']),
          for (final a in rows(p['approvals']))
            tile(a['role'] ?? obj(a['user'])['nama'],
                fields(a, ['status', 'catatan'])),
          if (p.isEmpty || p['status'] == 'DIBATALKAN')
            action('Ajukan check out', () async {
              final v = await ask('Alasan check out');
              if (v != null && await confirm('Ajukan check out?', v))
                await send(endpoint, {'alasan': v});
            })
        ];
      case 'WhatsApp AI':
        return [
          tile(
              data['terhubung'] == true
                  ? 'Nomor terhubung'
                  : 'Nomor belum terhubung',
              data['noWaMasked']),
          action('Verifikasi nomor WhatsApp', () async {
            final n = await ask('Nomor WhatsApp', hint: '08…');
            if (n == null) return;
            final d = await get('me/no-wa/request', body: {'noWa': n});
            final code = await ask(val(d['message']), hint: 'Kode enam digit');
            if (code != null)
              await send('me/no-wa/verify', {'noWa': n, 'otp': code});
          })
        ];
      case 'Daftar ulang':
        final p = obj(obj(data['data'])['pending']);
        if (p.isNotEmpty)
          return [
            tile('Menunggu verifikasi', p['noKwitansi']),
            tile('Program', obj(p['program'])['nama']),
            if (obj(p['dufah']).isNotEmpty)
              tile('Dufah', obj(p['dufah'])['nama']),
            tile('Jumlah transfer', _rp(p['totalTagihan'])),
            if (p['kodeUnik'] != null) ...[
              tile('Kode unik', '+${p['kodeUnik']}'),
              tile('Catatan',
                  'Transfer tepat hingga 3 digit terakhir agar otomatis terbaca oleh admin.'),
            ],
            tile('Tujuan pembayaran',
                'BANK BRI a.n Markaz Arabiyah · 0555-01-001108-569'),
            action('Salin No. Kwitansi', () async {
              await Clipboard.setData(
                  ClipboardData(text: val(p['noKwitansi'])));
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No. Kwitansi disalin.')));
            }, icon: Icons.copy_rounded),
            action('Salin No. Rekening', () async {
              await Clipboard.setData(
                  const ClipboardData(text: '055501001108569'));
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No. Rekening disalin.')));
            }, icon: Icons.copy_rounded),
            action(
                'Konfirmasi via WhatsApp Admin',
                () => external(
                    'https://wa.me/6281212887788?text=Assalamualaikum%20Admin,%20saya%20sudah%20transfer%20daftar%20ulang.'),
                icon: Icons.chat_rounded),
            action('Batalkan tagihan', () async {
              if (await confirm('Batalkan tagihan?', val(p['noKwitansi'])))
                await send(endpoint, {}, method: 'DELETE');
            })
          ];
        final programs = rows(obj(extra['meta'])['programTersedia']);
        final masa = obj(obj(extra['data'])['masaAktif']);
        final logika = obj(obj(extra['data'])['logikaSistem']);
        final klaim = logika['klaimTersedia'] == true;
        final num? sisaRaw =
            masa['sisaBulanBerjalan'] ?? masa['sisaKoutaBulan'];
        final int? sisaBulan = sisaRaw?.round();
        final berakhir =
            adjustDufahName(val(masa['berakhirPadaDufahNama']));
        final berjalan = adjustDufahName(
            val(obj(masa['dufahSekarangSistem'])['nama']));
        final berakhirTampil =
            berakhir != '—' && berakhir != 'Belum Ditentukan';
        final berjalanTampil =
            berjalan != '—' && berjalan != 'Belum Ditentukan';
        final wajib = logika['butuhDaftarUlang'] == true;
        return [
          Card(
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
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              const Flexible(
                                  child: Text('bulan tersisa',
                                      style: TextStyle(
                                          color: MarkazColors.muted))),
                            ]),
                        if (berakhirTampil) ...[
                          const SizedBox(height: 8),
                          Text('Berakhir pada: $berakhir',
                              style: const TextStyle(
                                  color: MarkazColors.muted)),
                        ],
                        if (berjalanTampil) ...[
                          const SizedBox(height: 4),
                          Text('Sedang berjalan: $berjalan',
                              style: const TextStyle(
                                  color: MarkazColors.muted)),
                        ],
                        if (sisaBulan != null) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                              value: (sisaBulan / 12).clamp(0.0, 1.0)),
                        ],
                        if (wajib) ...[
                          const SizedBox(height: 12),
                          const Text(
                              'Sistem menandakan Anda wajib mendaftar ulang pada periode ini.',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: MarkazColors.danger)),
                        ],
                      ]))),
          if (klaim)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daftar Ulang — Tinggal Pilih Program',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              'Anda memiliki sisa kuota ${sisaBulan ?? '—'} bulan${berakhirTampil ? ' (berakhir $berakhir)' : ''}. Pilih program untuk periode berikutnya di bawah ini.',
                              style: const TextStyle(
                                  color: MarkazColors.muted)),
                        ]))),
          Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                  klaim ? 'Pilih Program Anda' : 'Memilih Program Pendaftaran',
                  style: Theme.of(context).textTheme.titleLarge)),
          if (programs.isEmpty)
            const MarkazState(
                title: 'Belum ada program tersedia',
                message:
                    'Pilihan daftar ulang akan tampil saat pendaftaran dibuka.'),
          for (final p in programs)
            group(val(p['nama']), [
              if (klaim)
                tile(
                    'Rp 0',
                    fields(p, [
                      'durasiBulanFormatted',
                      'tglProgramFormatted'
                    ]))
              else if (_hargaDiskon(p) != null) ...[
                tile(_rp(_hargaDiskon(p)),
                    fields(p, ['durasiBulanFormatted', 'tglProgramFormatted'])),
                tile('Harga normal',
                    '${val(p['hargaFormatted'])} — sudah dikurangi Rp 100.000 (tanpa atribut)'),
              ] else
                tile(p['hargaFormatted'],
                    fields(p, ['durasiBulanFormatted', 'tglProgramFormatted'])),
              action('Pilih program', () async {
                final attr = klaim
                    ? '0'
                    : await choose('Atribut', [
                        ('0', 'Tanpa atribut — nominal dikurangi Rp 100.000'),
                        ('1', 'Beli atribut (+Rp 100.000)')
                      ]);
                if (attr == null) return;
                final bayar = klaim
                    ? 0
                    : attr == '1'
                        ? _hargaProgram(p)
                        : _hargaDiskon(p);
                final hargaTeks = klaim
                    ? 'Rp 0 (Klaim gratis — aktif seketika tanpa pembayaran)'
                    : bayar == null
                        ? val(p['hargaFormatted'])
                        : '${_rp(bayar)}${attr == '1' ? '' : ' (sudah dikurangi Rp 100.000)'}';
                if (await confirm(
                    klaim
                        ? 'Konfirmasi klaim program'
                        : 'Konfirmasi daftar ulang',
                    '${val(p['nama'])} — $hargaTeks${klaim ? '' : '\n\nBiaya yang sudah dibayarkan tidak dapat direfund atau dialihkan.'}'))
                  await send(endpoint,
                      {'programId': p['id'], 'isBeliAtribut': attr == '1'});
              })
            ])
        ];
      case 'Pemilihan':
        final s = obj(data['sesi']);
        if (s.isEmpty)
          return [
            const MarkazState(
                title: 'Belum ada sesi pemilihan',
                message:
                    'Sesi dan kandidat akan tampil ketika pemilihan dibuka.')
          ];
        return [
          tile(s['judul'], fields(s, ['dufahNama', 'status'])),
          if (data['sudahMemilih'] == true) tile('Suara Anda sudah tercatat.'),
          for (final p in rows(data['paslon']))
            group(
                'Paslon ${p['nomorUrut']} · ${val(obj(p['santri1'])['nama'])}',
                [
                  tile(obj(p['santri2'])['nama'], p['visiMisi']),
                  tile('Suara', p['suara']),
                  if (data['bolehMemilih'] == true &&
                      data['sudahMemilih'] != true)
                    action('Pilih paslon ini', () => vote(s, p))
                ])
        ];
      case 'Galeri':
        return [
          action('Periode: ${val(data['dufahNama'])}', () async {
            final v = await choose('Periode',
                [for (final d in data['dufahList'] ?? []) ('$d', '$d')]);
            if (v != null) {
              period = v;
              await load();
            }
          }),
          if (rows(data['data']).isEmpty)
            const MarkazState(
                title: 'Belum ada album',
                message: 'Coba pilih periode lainnya.'),
          for (final g in rows(data['data']))
            ListTile(
                title: Text(val(g['judul'])),
                subtitle: Text(date(g['createdAt'])),
                trailing: const Icon(Icons.photo_library_outlined),
                onTap: () => run(() => external(g['driveUrl'])))
        ];
      case 'Denah Sakan':
        final places = rows(data['data']);
        if (places.isEmpty) return [];
        LatLng point(Json p) => LatLng((p['latitude'] as num).toDouble(),
            (p['longitude'] as num).toDouble());
        return [
          SizedBox(
              height: 320,
              child: FlutterMap(
                  mapController: map,
                  options: MapOptions(
                      initialCenter: point(places.first), initialZoom: 15),
                  children: [
                    TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'site.markazarabiyah.siakad'),
                    MarkerLayer(markers: [
                      for (final p in places)
                        Marker(
                            point: point(p),
                            child: Tooltip(
                                message: val(p['nama']),
                                child: const Icon(Icons.location_on,
                                    color: MarkazColors.ink)))
                    ]),
                    if (route.isNotEmpty)
                      PolylineLayer(polylines: [
                        Polyline(
                            points: route,
                            color: MarkazColors.ink,
                            strokeWidth: 4)
                      ]),
                    const SimpleAttributionWidget(
                        source: Text('OpenStreetMap contributors'))
                  ])),
          for (final p in places)
            ListTile(
                title: Text(val(p['nama'])),
                subtitle: Text(val(p['deskripsi'])),
                trailing: const Icon(Icons.directions_walk),
                onTap: () => run(() async {
                      var perm = await Geolocator.checkPermission();
                      if (perm == LocationPermission.denied)
                        perm = await Geolocator.requestPermission();
                      if (perm == LocationPermission.denied ||
                          perm == LocationPermission.deniedForever)
                        throw const PortalError(
                            'Izinkan lokasi untuk melihat rute.');
                      final pos = await Geolocator.getCurrentPosition();
                      final dst = point(p);
                      final uri = Uri.https(
                          'router.project-osrm.org',
                          '/route/v1/foot/${pos.longitude},${pos.latitude};${dst.longitude},${dst.latitude}',
                          {'overview': 'full', 'geometries': 'geojson'});
                      final response = await http
                          .get(uri)
                          .timeout(const Duration(seconds: 15));
                      final routes = rows(jsonDecode(response.body)['routes']);
                      if (routes.isEmpty)
                        throw const PortalError('Rute belum tersedia.');
                      final points = [
                        for (final pt in routes.first['geometry']
                            ['coordinates'])
                          LatLng((pt[1] as num).toDouble(),
                              (pt[0] as num).toDouble())
                      ];
                      if (mounted && points.isNotEmpty) {
                        updateRoute(points);
                        map.fitCamera(CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(points),
                            padding: const EdgeInsets.all(30)));
                      }
                    }))
        ];
      case 'Tasmi’':
        return [
          for (final t in rows(data['items']))
            group('Juz ${t['juz']} · ${date(t['tanggal'])}', [
              tile(
                  fields(t, [
                    'surahNama',
                    'ayatDari',
                    'surahSampaiNama',
                    'ayatSampai'
                  ]),
                  t['catatan']),
              for (final k in [
                'nilaiTahfidz',
                'nilaiTahsin',
                'nilaiTartil',
                'nilaiAdab',
                'rataRata'
              ])
                tile(k, null, t[k])
            ])
        ];
      case 'Nadi Hufadz':
        return [
          tile(
              data['sudahDaftar'] == true
                  ? 'Sudah terdaftar'
                  : data['pendaftaranDibuka'] == true
                      ? 'Pendaftaran dibuka'
                      : 'Pendaftaran ditutup',
              data['dufahAktif']),
          if (data['sudahDaftar'] != true && data['pendaftaranDibuka'] == true)
            action('Daftar Nadi Hufadz', () async {
              if (await confirm('Daftar Nadi Hufadz?', val(data['dufahAktif'])))
                await send(endpoint, {});
            }),
          for (final r in rows(data['riwayat']))
            group(val(r['dufahNama']), [
              tile('Kehadiran', r['kehadiran']),
              for (final t in rows(r['setoran']))
                tile(fields(t, ['surat', 'ayat']),
                    fields(t, ['tanggal', 'penyimak', 'catatan'])),
              if (r['tasmi'] != null)
                action('Lihat syahadah', () => document('nadi', r['id'])),
              if (r['tasmi'] != null)
                tile('Hasil Tasmi’',
                    fields(obj(r['tasmi']), ['juzTeks', 'predikat', 'penguji']))
            ])
        ];
      case 'Berita Acara':
        return [
          for (final a in rows(obj(data['data'])['absenList']))
            group(val(obj(a['user'])['nama']), [
              tile(date(a['tanggal']), a['materi']),
              action('Isi berita acara', () async {
                final st = await choose('Kehadiran pengajar',
                    [('1', 'Hadir'), ('0', 'Tidak hadir')]);
                if (st == null) return;
                final mins = st == '1'
                    ? await ask('Menit terlambat', initial: '0')
                    : '0';
                if (mins == null || int.tryParse(mins) == null) return;
                final note = await ask('Catatan berita acara');
                if (note != null)
                  await send(endpoint, {
                    'absenPengajarId': a['id'],
                    'konfirmasiHadir': st == '1',
                    'catatan': note,
                    'terlambatMenit': int.parse(mins)
                  });
              })
            ])
        ];
      case 'Lapor Mukholif':
        return [
          action('Buat laporan', () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ServiceRequestForm(
                          permit: false,
                          ownerId: val(user['id']),
                          canChooseReporter: data['isLajnah'] == true,
                          searchPeople: (query) async => rows(await get(
                                  'mukholif/search-santri?q=${Uri.encodeQueryComponent(query)}'))
                              .where((s) => s['id'] != user['id'])
                              .toList(),
                          onSubmit: (body) => send(endpoint, body),
                        )));
          }),
          if (rows(data['laporanList']).isEmpty)
            const MarkazState(
                title: 'Belum ada laporan',
                message: 'Laporan yang sudah dikirim akan tampil di sini.'),
          for (final r in rows(data['laporanList']))
            tile(r['tempatMelanggar'],
                fields(r, ['perkataanYgDiucapkan', 'detailKejadian']))
        ];
      case 'Eksekusi Iqob':
        return [
          for (final p in rows(data))
            group(val(p['santriNama']), [
              for (final k in ['Sounding', 'Jawal', 'Penyetoran'])
                if (p['iqob$k'] == true && p['iqob${k}Done'] != true)
                  action('Selesaikan $k', () async {
                    if (await confirm('Konfirmasi $k', val(p['santriNama'])))
                      await send(endpoint, {
                        'pelanggarId': p['id'],
                        'iqobType': k.toUpperCase()
                      });
                  })
            ])
        ];
      case 'Tauzi’ Fushul':
        return [
          tile('Program tujuan',
              obj(obj(data['riwayat'])['program'])['nama_indo']),
          action('Pilih program tujuan', () async {
            final v = await choose('Program', [
              for (final p in rows(data['programs']))
                (val(p['id']), val(p['nama_indo']))
            ]);
            if (v != null) await send(endpoint, {'programId': v});
          }),
          action('Kerjakan tes penempatan', () async {
            await get('/api/tauzi/auth/login', body: {'nis': user['id']});
            final d = await get('/api/tauzi/soal');
            await exam(obj(d), true);
          }),
          action('Hasil tes penempatan', () async {
            await get('/api/tauzi/auth/login', body: {'nis': user['id']});
            final d = await get('/api/tauzi/hasil');
            if (mounted)
              await showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  builder: (_) =>
                      ListView(padding: const EdgeInsets.all(18), children: [
                        tile('Nilai tahriri', d['nilaiTahriri']),
                        for (final q in rows(d['breakdown']))
                          tile(q['pertanyaan'],
                              q['isCorrect'] == true ? 'Benar' : 'Salah')
                      ]));
          })
        ];
      default:
        return [];
    }
  }
}
