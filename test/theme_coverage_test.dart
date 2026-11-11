import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sample_aplikasi/siakad/api.dart';
import 'package:sample_aplikasi/siakad/catalog.dart';
import 'package:sample_aplikasi/siakad/features.dart';
import 'package:sample_aplikasi/siakad/exam.dart';
import 'package:sample_aplikasi/siakad/service_forms.dart';
import 'package:sample_aplikasi/siakad/tata_tertib_perizinan.dart';
import 'package:sample_aplikasi/screens/quran_screen.dart';
import 'package:sample_aplikasi/screens/calendar_screen.dart';
import 'package:sample_aplikasi/screens/siakad_portal_screen.dart';
import 'theme_flow_test.dart' show app;
import 'widget_test.dart' show DemoApi;

class CoverageApi extends DemoApi {
  bool fail = false;
  @override
  Future<dynamic> call(String path, {String method = 'GET', Json? body}) async {
    if (fail) throw const PortalError('Tidak dapat terhubung.');
    if (path == '/api/santri/qr-saya') return {'payload': 'TEST-ONLY'};
    if (path == '/api/santri/me') return fixture;
    return <String, dynamic>{};
  }
}

const fixture = <String, dynamic>{
  'santri': {'id': '001', 'nama': 'Santri contoh pengujian', 'isAktif': true},
  'riwayat': [
    {
      'id': 'r1',
      'dufahNama': 'Periode uji',
      'programNama': 'Program uji',
      'kelasNama': 'Kelas uji',
      'average': 84,
      'statusKelulusan': 'Lulus',
      'nilaiRows': [
        {
          'namaIndo': 'Nahwu',
          'nilaiUsbu1': 80,
          'nilaiUsbu2': 82,
          'nilaiNihai': 86,
          'skor': 83
        }
      ],
      'rekapAbsenKelas': {
        'hadir': 18,
        'izin': 1,
        'sakit': 0,
        'alpha': 1,
        'total': 20
      },
      'absenKelas': [
        {'tanggal': '2026-11-07', 'sesi': 'Pagi', 'status': 'HADIR'}
      ],
      'rekapAbsenSakan': {
        'hadir': 20,
        'izin': 0,
        'sakit': 0,
        'alpha': 0,
        'total': 20
      },
      'absenSakan': [],
      'rekapAbsenKegiatan': {
        'hadir': 9,
        'izin': 1,
        'sakit': 0,
        'alpha': 0,
        'total': 10
      },
      'absenKegiatan': [],
      'rekapAbsenTabirot': {
        'hadir': 8,
        'izin': 0,
        'sakit': 1,
        'alpha': 1,
        'total': 10
      },
      'absenTabirot': [],
      'rekapAbsenUbudiyah': {
        'tepatWaktu': 12,
        'masbuq': 2,
        'ghoib': 1,
        'total': 15
      },
      'absenUbudiyah': [
        {
          'tanggal': '2026-11-11',
          'kegiatan': 'SUBUH',
          'status': 'TEPAT_WAKTU',
          'keterangan': null
        },
        {
          'tanggal': '2026-11-11',
          'kegiatan': 'MAGHRIB',
          'status': 'MASBUQ_1',
          'keterangan': 'Terlambat bangun'
        },
      ],
    }
  ],
  'menu': {
    'isHufadz': true,
    'isKetuaKelas': true,
    'isJasus': true,
    'isLajnah': true
  }
};

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID');
    dotenv.testLoad(fileInput: '');
  });
  testWidgets(
      'All 20 catalog features and account render at 320dp / 200%, with error recovery',
      (t) async {
    t.view.physicalSize = const Size(320, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = CoverageApi();
    for (final name in [...features.map((f) => f.title), 'Akun']) {
      await t.pumpWidget(app(
          Scaffold(
              appBar: AppBar(title: Text(name)),
              body: FeaturePage(
                  key: ValueKey(name),
                  name: name,
                  me: fixture,
                  api: api,
                  onChanged: () async {})),
          scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: name);
      await t.pumpWidget(const SizedBox());
    }
    api.fail = true;
    await t.pumpWidget(app(Scaffold(
        body: FeaturePage(
            name: 'Nilai', me: fixture, api: api, onChanged: () async {}))));
    await t.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    api.fail = false;
    await t.tap(find.text('Coba lagi'));
    await t.pumpAndSettle();
    expect(find.text('Nilai belum dapat dimuat'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('SIAKAD home and catalog at 320dp / 200%', (t) async {
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = CoverageApi()..exists = true;
    await t.pumpWidget(app(SiakadPortalScreen(api: api), scale: 2));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.scrollUntilVisible(find.text('Semua fitur'), 250,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Semua fitur'));
    await t.pumpAndSettle();
    await t.tap(find.text('Semua fitur'));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'Public calendar and Quran recover from unavailable network at large text',
      (t) async {
    t.view.physicalSize = const Size(320, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final page in [const CalendarScreen(), const QuranScreen()]) {
      await t.pumpWidget(app(page, scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: page.runtimeType.toString());
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'Group member picker survives keyboard and 200% text and retains selection',
      (t) async {
    t.view.physicalSize = const Size(320, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    // Gerbang persetujuan sudah dilewati (diuji terpisah di
    // perizinan_agreement_test.dart) agar tes ini fokus pada picker
    // anggota kelompok.
    SharedPreferences.setMockInitialValues({perizinanAgreedKey: true});
    await t.pumpWidget(app(
        ServiceRequestForm(
            permit: true,
            ownerId: '001',
            searchPeople: (_) async => [
                  {
                    'riwayatId': 'r1',
                    'nama': 'Santri uji',
                    'sakan': 'Sakan uji'
                  }
                ],
            onSubmit: (_) async {}),
        scale: 2));
    await t.pumpAndSettle();
    // Saklar berada di bawah lipatan form (teks besar) dan ListView
    // membangun anaknya secara malas — scroll dulu sampai ter-build.
    await t.scrollUntilVisible(find.byType(SwitchListTile), 300);
    await t.pumpAndSettle();
    await t.tap(find.byType(SwitchListTile));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Pilih santri (0)'));
    await t.tap(find.text('Pilih santri (0)'));
    await t.pumpAndSettle();
    t.view.viewInsets = const FakeViewPadding(bottom: 280);
    await t.pump();
    expect(t.takeException(), isNull);
    t.view.resetViewInsets();
    await t.pump();
    await t.tap(find.byType(CheckboxListTile));
    await t.pumpAndSettle();
    await t.tap(find.text('Gunakan 1 santri'));
    await t.pumpAndSettle();
    expect(find.text('Santri uji'), findsOneWidget);
  });

  testWidgets('Exam types keep usable controls on narrow screen and large text',
      (t) async {
    FlutterSecureStorage.setMockInitialValues({});
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = CoverageApi();
    final questions = <Json>[
      {
        'tipeSoal': 'PG',
        'opsiList': [
          {'id': 'a', 'teks': 'Jawaban A'},
          {'id': 'b', 'teks': 'Jawaban B'}
        ]
      },
      {
        'tipeSoal': 'PG_MULTI',
        'opsiList': [
          {'id': 'a', 'teks': 'Jawaban A'}
        ]
      },
      {
        'tipeSoal': 'MENJODOHKAN',
        'dataTambahan': {
          'lefts': ['Kiri'],
          'rights': ['Kanan']
        }
      },
      {
        'tipeSoal': 'DRAG_KATEGORI',
        'dataTambahan': {
          'items': [
            {'text': 'Kata'}
          ],
          'categories': ['Kategori']
        }
      },
      {
        'tipeSoal': 'MENGURUTKAN',
        'dataTambahan': {
          'items': ['Satu', 'Dua']
        }
      },
      {
        'tipeSoal': 'SUSUN_HURUF',
        'dataTambahan': {
          'hurufAcak': ['ب', 'ا']
        }
      },
      {
        'tipeSoal': 'DRAG_TO_BLANK',
        'dataTambahan': {
          'blanks': [
            {'index': 1}
          ],
          'wordBank': ['Kata']
        }
      },
      {
        'tipeSoal': 'PARAGRAF_RUMPANG',
        'dataTambahan': {
          'blanks': [
            {'index': 1}
          ]
        }
      },
      {
        'tipeSoal': 'TABEL_TASRIF',
        'dataTambahan': {
          'rows': [
            {
              'label': 'هو',
              'cells': [
                {'isBlank': true}
              ]
            }
          ],
          'headers': ['فعل']
        }
      },
      {
        'tipeSoal': 'IDENTIFIKASI_KESALAHAN',
        'dataTambahan': {
          'words': ['Kata'],
          'categories': ['Kategori']
        }
      },
      {
        'tipeSoal': 'STABILO_SYNTAX',
        'dataTambahan': {
          'words': ['Kata'],
          'categories': ['Kategori']
        }
      },
      {
        'tipeSoal': 'JARING_RELASI',
        'dataTambahan': {
          'leftItems': ['Kiri'],
          'rightItems': ['Kanan']
        }
      },
      {'tipeSoal': 'ESSAY'},
    ];
    for (final q in questions) {
      await t.pumpWidget(app(
          ExamPage(
              key: ValueKey(q['tipeSoal']),
              api: api,
              owner: '001',
              tauzi: false,
              data: {
                'sesiId': 'test',
                'sisaWaktuDetik': 900,
                'soal': [
                  {'soalId': 'q1', 'pertanyaan': '<p>Soal uji</p>', ...q}
                ]
              }),
          scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: q['tipeSoal'].toString());
      await t.pumpWidget(const SizedBox());
    }
  });
}
