import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample_aplikasi/siakad/features.dart';
import 'package:sample_aplikasi/siakad/api.dart';
import 'theme_flow_test.dart' show app, screenshot;

final previewHistory = <Json>[
  {
    'id': 'preview95',
    'dufahNama': 'Duf’ah 95',
    'programNama': 'I’dad Tsani',
    'kelasNama': 'Akbarnas B',
    'average': 84,
    'statusKelulusan': 'LULUS',
    'canDownloadSyahadah': true,
    'nilaiRows': [
      for (final (name, score) in [
        ('Nahwu', 78),
        ('Shorof', 85),
        ('Muhadatsah', 88),
        ('Kitabah', 85)
      ])
        {
          'namaIndo': name,
          'nilaiUsbu1': score - 2,
          'nilaiUsbu2': score,
          'nilaiNihai': score + 2,
          'skor': score
        }
    ],
    for (final type in ['Kelas', 'Sakan', 'Kegiatan', 'Tabirot'])
      'rekapAbsen$type': {
        'hadir': 34,
        'alpha': 3,
        'izin': 2,
        'sakit': 1,
        'total': 40
      },
    for (final type in ['Kelas', 'Sakan', 'Kegiatan', 'Tabirot'])
      'absen$type': [
        for (var i = 0; i < 40; i++)
          {
            'tanggal': '2026-10-${(20 - i ~/ 2).toString().padLeft(2, '0')}',
            'sesi': i.isEven ? 'SESI_2' : 'SESI_1',
            'status': i < 3
                ? 'ALPHA'
                : i < 5
                    ? 'IZIN'
                    : i == 5
                        ? 'SAKIT'
                        : 'HADIR'
          }
      ],
    'perizinan': [
      {
        'id': 'permit1',
        'tipeIzin': 'KELUAR_PARE',
        'statusIzin': 'AKTIF',
        'alasan': 'Keperluan keluarga',
        'tanggalMulai': '2026-11-08',
        'nomorTasrih': 'CONTOH/001',
        'selfieAt': '2026-11-08'
      },
      {
        'id': 'permit2',
        'tipeIzin': 'HARIAN',
        'statusIzin': 'SELESAI',
        'alasan': 'Pemeriksaan kesehatan',
        'tanggalMulai': '2026-11-01',
        'nomorTasrih': 'CONTOH/002'
      }
    ]
  },
  {
    'id': 'preview94',
    'dufahNama': 'Duf’ah 94',
    'programNama': 'Takhassus Awal',
    'kelasNama': 'Kelas A',
    'average': 82,
    'statusKelulusan': 'LULUS',
    'nilaiRows': [],
    'rekapAbsenKelas': {
      'hadir': 19,
      'alpha': 1,
      'izin': 0,
      'sakit': 0,
      'total': 20
    }
  }
];
final previewMe = <String, dynamic>{
  'santri': {
    'id': '001234',
    'nama': 'Santri Contoh',
    'isAktif': true,
    'sakan': 'Sakan A',
    'kamar': '12',
    'nomorLemari': '5',
    'tempatLahir': 'Bandung',
    'tanggalLahir': '2004-03-09T00:00:00+07:00',
    'alamat':
        'Jalan Pendidikan Nomor 12, Kecamatan Sukamaju, Kabupaten Bandung',
    'bulanKe': 3
  },
  'riwayat': previewHistory,
  'menu': {'isHufadz': true, 'isKetuaKelas': true, 'isLajnah': true}
};

class PreviewApi extends SantriApi {
  PreviewApi() : super(origin: Uri.parse('https://example.invalid'));
  Json? lastBody;
  bool failSave = false;
  @override
  Future<dynamic> call(String path, {String method = 'GET', Json? body}) async {
    if (method != 'GET') {
      lastBody = body;
      if (failSave)
        throw const PortalError('Koneksi terputus. Coba simpan lagi.');
      return {};
    }
    return switch (path) {
      '/api/santri/me' => previewMe,
      '/api/santri/qr-saya' => {'payload': 'DATA-CONTOH'},
      '/api/santri/qr-saya/status' => {
          'hadir': [
            {'kategoriNama': 'Absensi kelas', 'kategoriId': '1'}
          ]
        },
      '/api/santri/tasmi' => {
          'total': 3,
          'terakhir': {'juz': 2},
          'items': [
            {
              'juz': 2,
              'tanggal': '2026-11-07',
              'surahNama': 'Al-Baqarah',
              'ayatDari': 142,
              'ayatSampai': 145,
              'nilaiTahfidz': 90,
              'nilaiTahsin': 88,
              'nilaiTartil': 90,
              'nilaiAdab': 95,
              'rataRata': 90.75,
              'catatan': 'Pertahankan kelancaran bacaan.'
            }
          ]
        },
      '/api/santri/me/berita-acara' => {
          'data': {
            'kelas': 'Akbarnas B',
            'absenList': [
              {
                'id': 'ba1',
                'tanggal': '2026-11-08',
                'sesi': 'SESI_1',
                'materi': 'Jumlah ismiyyah',
                'user': {'nama': 'Pengajar Contoh'},
                'beritaAcara': null
              },
              {
                'id': 'ba2',
                'tanggal': '2026-11-07',
                'sesi': 'SESI_2',
                'materi': 'Latihan percakapan',
                'user': {'nama': 'Pengajar Contoh'},
                'beritaAcara': {
                  'konfirmasiHadir': true,
                  'catatan': 'Sesi selesai.'
                }
              }
            ]
          }
        },
      '/api/santri/arsip-galeri' => {
          'dufahNama': 'Duf’ah 95',
          'dufahList': ['Duf’ah 95', 'Duf’ah 94'],
          'data': [
            {
              'judul': 'Kegiatan belajar bersama',
              'dufahNama': 'Duf’ah 95',
              'createdAt': '2026-11-01',
              'driveUrl': 'https://example.invalid/album'
            }
          ]
        },
      '/api/santri/checkout' => {
          'pengajuan': {
            'status': 'MENUNGGU',
            'alasan': 'Program belajar telah selesai.',
            'approvals': [
              {'role': 'Pengasuh sakan', 'status': 'DISETUJUI'},
              {'role': 'Akademik', 'status': 'MENUNGGU'}
            ]
          }
        },
      '/api/santri/me/daftar-ulang' => {
          'data': {'pending': null}
        },
      '/api/santri/me/status' => {
          'data': {
            'masaAktif': {
              'sisaBulanBerjalan': 2,
              'berakhirPadaDufahNama': "Duf'ah 97"
            },
            'logikaSistem': {'klaimTersedia': true}
          },
          'meta': {
            'programTersedia': [
              {
                'id': 'p1',
                'nama': 'I’dad Tsani',
                'durasiBulanFormatted': '1 bulan',
                'tglProgramFormatted': 'Periode berikutnya'
              }
            ]
          }
        },
      '/api/santri/me/no-wa' => {
          'terhubung': true,
          'noWaMasked': '08•• •••• 1234'
        },
      '/api/santri/nadi-hufadz' => {
          'sudahDaftar': true,
          'dufahAktif': 'Duf’ah 95',
          'riwayat': [
            {
              'id': 'n1',
              'dufahNama': 'Duf’ah 95',
              'kehadiran': '8 sesi',
              'setoran': [
                {
                  'surat': 'Al-Baqarah',
                  'ayat': '1–5',
                  'tanggal': '2026-11-07',
                  'penyimak': 'Pengajar Contoh',
                  'catatan': 'Lancar'
                }
              ]
            }
          ]
        },
      '/api/santri/mukholif' => {
          'laporanList': [
            {
              'tempatMelanggar': 'Lingkungan kelas',
              'waktuMelanggar': '2026-11-07',
              'detailKejadian': 'Contoh catatan laporan untuk pratinjau.'
            }
          ]
        },
      '/api/santri/eksekusi-mukholif' => [
          {
            'id': 'iq1',
            'santriNama': 'Santri Contoh',
            'santriAsrama': 'Sakan A',
            'santriKelas': 'Akbarnas B',
            'laporan': {'waktuMelanggar': '2026-11-07'},
            'iqobSounding': true,
            'iqobSoundingDone': true,
            'iqobPenyetoran': true,
            'iqobPenyetoranDone': false
          }
        ],
      '/api/santri/pemilihan-lajnah' => {
          'sesi': {
            'judul': 'Pemilihan Lajnah',
            'status': 'BUKA',
            'dufahNama': 'Duf’ah 95'
          },
          'paslon': [
            {
              'id': 'paslon1',
              'nomorUrut': 1,
              'santri1': {'nama': 'Kandidat Contoh A'},
              'santri2': {'nama': 'Kandidat Contoh B'},
              'visiMisi': 'Contoh visi dan misi kandidat.',
              'suara': 12
            }
          ],
          'bolehMemilih': true,
          'sudahMemilih': false
        },
      '/api/santri/me/tauzi' => {
          'riwayat': {
            'program': {'nama_indo': 'I’dad Tsani'}
          },
          'programs': [
            {'id': 'p1', 'nama_indo': 'I’dad Tsani'}
          ]
        },
      '/api/santri/ujian' => [
          {
            'id': 'u1',
            'nama': 'Ujian Usbu 1',
            'status': 'BELUM_MULAI',
            'jumlahSoal': 25,
            'durasiMenit': 45
          },
          {
            'id': 'u2',
            'nama': 'Ujian Bahasa Arab',
            'status': 'MENGERJAKAN',
            'jumlahSoal': 30,
            'durasiMenit': 60
          }
        ],
      '/api/mobile/hasil-tes' => {
          'active_dufah': 'Duf’ah 95',
          'data': [
            {
              'santri': [
                {
                  'rata_rata_per_usbu': [
                    {'label': 'Usbu 1', 'rata_rata_nilai': 82},
                    {'label': 'Usbu 2', 'rata_rata_nilai': 86}
                  ],
                  'nilai_per_mapel': [
                    {
                      'mapel': 'Nahwu',
                      'nilai_usbu_1': 80,
                      'nilai_usbu_2': 84,
                      'nilai_nihai': 85
                    }
                  ]
                }
              ]
            }
          ]
        },
      _ => {},
    };
  }
}

Widget preview(String name, PreviewApi api, {double scale = 1}) => app(
    Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Column(children: [
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('DATA CONTOH • PRATINJAU',
                  style: TextStyle(fontSize: 11))),
          Expanded(
              child: FeaturePage(
                  key: ValueKey(name),
                  name: name,
                  me: previewMe,
                  api: api,
                  onChanged: () async {})),
        ])),
    scale: scale);
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: '');
    await initializeDateFormatting('id_ID');
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    for (final (family, file) in [
      ('Roboto', 'Roboto-Regular.ttf'),
      ('STIXTwoText', 'STIXTwoText.ttf'),
      ('Amiri', 'Amiri-Regular.ttf')
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file')))
          .load();
    }
  });
  const pages = [
    'Absensi',
    'Nilai',
    'Riwayat',
    'Perizinan',
    'Ujian',
    'Tasmi’',
    'Berita Acara',
    'Daftar ulang',
    'Check out',
    'Galeri',
    'QR Saya',
    'Nadi Hufadz',
    'Lapor Mukholif',
    'Eksekusi Iqob',
    'Pemilihan',
    'Tauzi’ Fushul',
    'Hasil Tes',
    'Akun',
    'WhatsApp AI'
  ];
  for (final name in pages) {
    testWidgets('Render native screenshot: $name', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(390, 844);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final api = PreviewApi();
      addTearDown(api.dispose);
      await t.pumpWidget(preview(name, api));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: name);
      await screenshot(t,
          'siakad-${name.toLowerCase().replaceAll('’', '').replaceAll(' ', '-')}');
      await t.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'Profile shows calendar birth date, empty photo and edit validation',
      (t) async {
    final api = PreviewApi();
    addTearDown(api.dispose);
    await t.pumpWidget(preview('Akun', api));
    await t.pumpAndSettle();
    expect(find.text('NIS 001234'), findsOneWidget);
    expect(find.text('09-03-2004'), findsOneWidget);
    expect(find.textContaining('T00:00'), findsNothing);
    final photo = t.widget<Container>(
        find.byKey(const ValueKey('profile-photo-placeholder')));
    expect(photo.child, isNull);
    await t.scrollUntilVisible(find.text('Ubah bulan belajar'), 250);
    await t.tap(find.text('Ubah bulan belajar'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), '0');
    await t.tap(find.text('Simpan'));
    await t.pumpAndSettle();
    expect(find.text('Masukkan angka bulan mulai dari 1.'), findsOneWidget);
    await t.enterText(find.byType(TextFormField), '4');
    api.failSave = true;
    await t.tap(find.text('Simpan'));
    await t.pumpAndSettle();
    expect(find.text('Koneksi terputus. Coba simpan lagi.'), findsOneWidget);
    expect(
        t.widget<TextFormField>(find.byType(TextFormField)).initialValue, '4');
    await screenshot(t, 'siakad-profil-dialog');
    api.failSave = false;
    await t.tap(find.text('Simpan'));
    await t.pumpAndSettle();
    expect(api.lastBody, {'bulanKe': 4});
    expect(find.byType(AlertDialog), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Populated pages adapt to 320dp and 200% text', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 800);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = PreviewApi();
    addTearDown(api.dispose);
    for (final name in pages) {
      await t.pumpWidget(preview(name, api, scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: name);
      await t.pumpWidget(const SizedBox());
    }
  });
  testWidgets(
      'Attendance status drills into correct records and period changes reset filter',
      (t) async {
    final api = PreviewApi();
    addTearDown(api.dispose);
    await t.pumpWidget(preview('Absensi', api));
    await t.pumpAndSettle();
    await t.tap(find.text('Alpa').first);
    await t.pumpAndSettle();
    expect(find.text('3 catatan tersedia'), findsOneWidget);
    await t.tap(find.byType(OutlinedButton).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Duf’ah 94 · Takhassus Awal · Kelas A'));
    await t.pumpAndSettle();
    expect(find.text('19 hadir dari 20 sesi'), findsOneWidget);
    expect(find.text('Catatan alpa'), findsNothing);
  });
  testWidgets('Berita acara keeps draft on failed save and validates delay',
      (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 844);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = PreviewApi()..failSave = true;
    addTearDown(api.dispose);
    await t.pumpWidget(preview('Berita Acara', api));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Isi berita acara'));
    await t.tap(find.text('Isi berita acara'));
    await t.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await t.enterText(fields.first, '-1');
    await t.ensureVisible(find.text('Simpan berita acara'));
    await t.tap(find.text('Simpan berita acara'));
    await t.pumpAndSettle();
    expect(api.lastBody, isNull);
    await t.enterText(fields.first, '5');
    await t.enterText(fields.last, 'Catatan tetap tersimpan');
    await t.ensureVisible(find.text('Simpan berita acara'));
    await t.tap(find.text('Simpan berita acara'));
    await t.pumpAndSettle();
    expect(find.text('Catatan tetap tersimpan'), findsOneWidget);
    expect(api.lastBody?['terlambatMenit'], 5);
    await screenshot(t, 'siakad-berita-acara-modal');
  });
}
