import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sample_aplikasi/theme/markaz_theme.dart';
import 'package:sample_aplikasi/widgets/coming_soon_dialog.dart';
import 'package:sample_aplikasi/screens/main_layout.dart';
import 'package:sample_aplikasi/screens/siakad_portal_screen.dart';
import 'package:sample_aplikasi/siakad/features.dart';
import 'package:sample_aplikasi/siakad/service_forms.dart';
import 'package:sample_aplikasi/siakad/api.dart';
import 'widget_test.dart' show DemoApi;

Widget app(Widget page, {double scale = 1}) => RepaintBoundary(child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: markazTheme(),
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    home: page));

Future<void> screenshot(WidgetTester t, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_THEME')) return;
  // Refresh retained layers before offscreen capture across several scenes.
  for (final render in t.allRenderObjects) {
    render.markNeedsPaint();
  }
  await t.pump();
  await t.runAsync(() async {
    final boundary = t.firstRenderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/theme-verification/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    for (final (family, file) in [
      ('Roboto', 'Roboto-Regular.ttf'),
      ('STIXTwoText', 'STIXTwoText.ttf'),
      ('Amiri', 'Amiri-Regular.ttf')
    ]) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$file'));
      await loader.load();
    }
  });
  testWidgets(
      'Home actual renders on narrow phone and large text; named menus remain reachable',
      (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    for (final width in [390.0, 320.0, 430.0]) {
      t.view.physicalSize = Size(width, 900);
      await t.pumpWidget(app(const RepaintBoundary(child: MainLayout())));
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Selamat datang di portal Markaz Arabiyah'),
          findsOneWidget);
      if (width == 390) await screenshot(t, 'beranda');
    }
    await t
        .pumpWidget(app(const RepaintBoundary(child: MainLayout()), scale: 2));
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Portal login and service menu fit phone, theme and mascot',
      (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 900);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final api = DemoApi();
    await t
        .pumpWidget(app(RepaintBoundary(child: SiakadPortalScreen(api: api))));
    await t.pumpAndSettle();
    await screenshot(t, 'login');
    await t.enterText(find.byType(TextField), '001');
    await t.ensureVisible(find.text('Masuk'));
    await t.tap(find.text('Masuk'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await screenshot(t, 'siakad');
    await t.tap(find.text('Layanan'));
    await t.pumpAndSettle();
    await screenshot(t, 'layanan');
    expect(find.text('Perizinan'), findsOneWidget);
  });

  testWidgets(
      'Permit draft retained after failed submit, sends only reviewed body',
      (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 900);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    Json? submitted;
    await t.pumpWidget(app(RepaintBoundary(
        child: ServiceRequestForm(
            permit: true,
            ownerId: '001',
            searchPeople: (_) async => [],
            onSubmit: (body) async {
              submitted = body;
              throw const PortalError('Koneksi terputus');
            }))));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), 'Keperluan keluarga');
    await screenshot(t, 'perizinan-form');
    await t.ensureVisible(find.text('Tinjau pengajuan'));
    await t.tap(find.text('Tinjau pengajuan'));
    await t.pumpAndSettle();
    expect(submitted, isNull);
    await screenshot(t, 'perizinan-konfirmasi');
    await t.tap(find.text('Kirim pengajuan'));
    await t.pumpAndSettle();
    expect(submitted?['riwayatIds'], ['001']);
    expect(submitted?['alasan'], 'Keperluan keluarga');
    expect(find.text('Keperluan keluarga'), findsOneWidget);
    expect(find.text('Koneksi terputus'), findsOneWidget);
  });

  testWidgets(
      'Permission history empty has action and mascot, modal fits 320dp / 200%',
      (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 800);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(app(Scaffold(
        body: FeaturePage(
            name: 'Perizinan',
            me: const {
              'riwayat': [
                {'id': '001'}
              ]
            },
            api: DemoApi(),
            onChanged: () async {}))));
    await t.pumpAndSettle();
    expect(find.text('Belum ada riwayat izin'), findsOneWidget);
    await screenshot(t, 'perizinan-kosong');
    await t.pumpWidget(app(
        Scaffold(
            body: Builder(
                builder: (context) => Center(
                    child: FilledButton(
                        onPressed: () =>
                            showComingSoonDialog(context, 'Notifikasi'),
                        child: const Text('Buka'))))),
        scale: 2));
    await t.tap(find.text('Buka'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.ensureVisible(find.text('Tutup'));
    await t.tap(find.text('Tutup'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
