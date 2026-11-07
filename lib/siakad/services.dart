part of 'features.dart';

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
            tile('Jumlah transfer', 'Rp ${p['totalTagihan']}'),
            tile('Tujuan pembayaran',
                'BANK BRI a.n Markaz Arabiyah · 0555-01-001108-569'),
            action('Batalkan tagihan', () async {
              if (await confirm('Batalkan tagihan?', val(p['noKwitansi'])))
                await send(endpoint, {}, method: 'DELETE');
            })
          ];
        final programs = rows(obj(extra['meta'])['programTersedia']);
        return [
          if (programs.isEmpty)
            const MarkazState(
                title: 'Belum ada program tersedia',
                message:
                    'Pilihan daftar ulang akan tampil saat pendaftaran dibuka.'),
          for (final p in programs)
            group(val(p['nama']), [
              tile(p['hargaFormatted'],
                  fields(p, ['durasiBulanFormatted', 'tglProgramFormatted'])),
              action('Pilih program', () async {
                final claim =
                    obj(obj(extra['data'])['logikaSistem'])['klaimTersedia'] ==
                        true;
                final attr = claim
                    ? '0'
                    : await choose('Atribut', [
                        ('0', 'Tanpa tambahan atribut'),
                        ('1', 'Beli atribut')
                      ]);
                if (attr != null &&
                    await confirm('Konfirmasi daftar ulang',
                        fields(p, ['nama', 'hargaFormatted'])))
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
