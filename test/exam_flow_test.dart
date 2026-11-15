import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sample_aplikasi/siakad/api.dart';
import 'package:sample_aplikasi/siakad/exam.dart';
import 'package:sample_aplikasi/siakad/exam/answer_journal.dart';
import 'theme_flow_test.dart' show app;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

Future<void> screenshot(WidgetTester t, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_THEME')) return;
  await t.runAsync(() async {
    final root = t.firstRenderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    final image = await root.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/theme-verification/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class SyncApi extends SantriApi {
  SyncApi() : super(origin: Uri.parse('https://example.invalid'));
  bool offline = false;
  int sends = 0;
  Json? last;
  @override
  Future<dynamic> call(String path, {String method = 'GET', Json? body}) async {
    if (path.contains('/status'))
      return {'status': 'MENGERJAKAN', 'sisaWaktuDetik': 900};
    sends++;
    if (offline) throw const PortalError('Offline');
    last = body;
    return {
      'success': true,
      'revision': body?['revision'],
      'finalized': body?['reason'] != null
    };
  }
}

const data = {
  'sesiId': 'flow',
  'sisaWaktuDetik': 900,
  'soal': [
    {'soalId': 'q', 'tipeSoal': 'ESSAY_ARAB', 'pertanyaan': 'اكتب الجواب'}
  ]
};
void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    for (final (family, file) in [
      ('Roboto', 'Roboto-Regular.ttf'),
      ('Amiri', 'Amiri-Regular.ttf')
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file')))
          .load();
    }
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('markaz/exam'),
            (call) async => call.method == 'end' ? null : true);
  });
  testWidgets('Strict lock failure does not expose questions', (t) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('markaz/exam'),
            (call) async => throw PlatformException(
                code: 'denied', message: 'Not managed'));
    final api = SyncApi();
    addTearDown(api.dispose);
    await t.pumpWidget(
        app(ExamPage(api: api, data: data, owner: '1', tauzi: false)));
    await t.pumpAndSettle();
    expect(find.text('Not managed'), findsOneWidget);
    expect(find.text('Soal 1 dari 1'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'Offline submission stays sealed, survives remount and uploads exact snapshot',
      (t) async {
    final api = SyncApi();
    addTearDown(api.dispose);
    final key = AnswerJournal.storageKey(api.origin.toString(), '1', 'flow');
    final j = AnswerJournal(
        key: key,
        read: (k) => api.vault.read(key: k),
        write: (k, v) => api.vault.write(key: k, value: v));
    await j.restore({}, {
      ...data,
      'localDeadline':
          DateTime.now().add(const Duration(minutes: 15)).toIso8601String()
    });
    await j.edit('q', {'jawabanTeks': 'بِسْمِ اللَّهِ'});
    await j.seal('TIME_UP');
    api.offline = true;
    await t.pumpWidget(
        app(ExamPage(api: api, data: data, owner: '1', tauzi: false)));
    await t.pumpAndSettle();
    expect(find.text('Pengerjaan selesai'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
        jsonDecode((await api.vault.read(key: key))!)['answers']['q']
            ['jawabanTeks'],
        'بِسْمِ اللَّهِ');
    await t.pumpWidget(const SizedBox());
    api.offline = false;
    await t.pumpWidget(
        app(ExamPage(api: api, data: data, owner: '1', tauzi: false)));
    await t.pumpAndSettle();
    expect(find.text('Jawaban diterima server'), findsOneWidget);
    expect(api.last?['answers']['q']['jawabanTeks'], 'بِسْمِ اللَّهِ');
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'Interrupted running exam is sealed on recovery even without lifecycle notification',
      (t) async {
    final api = SyncApi();
    addTearDown(api.dispose);
    final key = AnswerJournal.storageKey(api.origin.toString(), '1', 'flow');
    final j = AnswerJournal(
        key: key,
        read: (k) => api.vault.read(key: k),
        write: (k, v) => api.vault.write(key: k, value: v));
    await j.restore({}, {
      ...data,
      'running': true,
      'localDeadline':
          DateTime.now().add(const Duration(minutes: 15)).toIso8601String()
    });
    await t.pumpWidget(
        app(ExamPage(api: api, data: data, owner: '1', tauzi: false)));
    await t.pumpAndSettle();
    expect(api.last?['reason'], 'LOCK_LOST');
    expect(find.text('Soal 1 dari 1'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Render Arabic keyboard and tasrif with actual exam widgets',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = SyncApi();
    addTearDown(api.dispose);
    await t.pumpWidget(
        app(ExamPage(api: api, data: data, owner: '1', tauzi: false)));
    await t.pumpAndSettle();
    await t.tap(find.byType(TextField));
    await t.pumpAndSettle();
    await t.tap(find.text('ب'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, 'ب');
    await screenshot(t, 'ujian-keyboard-mobile');
    final press = await t.startGesture(t.getCenter(find.text('ل')));
    await t.pump(const Duration(milliseconds: 451));
    await press.up();
    await t.pump();
    await t.tap(find.text('لا'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, 'بلا');
    t.view.physicalSize = const Size(844, 390);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);

    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Render tasrif matrix screenshot', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = SyncApi();
    addTearDown(api.dispose);
    final matrix = {
      'sesiId': 'matrix',
      'sisaWaktuDetik': 900,
      'soal': [
        {
          'soalId': 't',
          'tipeSoal': 'TABEL_TASRIF',
          'pertanyaan': 'أكمل الجدول الآتي',
          'dataTambahan': {
            'headers': ['الماضي', 'المضارع', 'الأمر'],
            'rows': [
              {
                'label': 'هو',
                'cells': [
                  {'value': 'كَتَبَ'},
                  {'isBlank': true},
                  {'isBlank': true}
                ]
              },
              {
                'label': 'أنتَ',
                'cells': [
                  {'isBlank': true},
                  {'isBlank': true},
                  {'value': 'اُكْتُبْ'}
                ]
              }
            ]
          }
        }
      ]
    };
    await t.pumpWidget(
        app(ExamPage(api: api, data: matrix, owner: '1', tauzi: false)));
    await t.pumpAndSettle();
    await screenshot(t, 'ujian-tasrif-mobile');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
