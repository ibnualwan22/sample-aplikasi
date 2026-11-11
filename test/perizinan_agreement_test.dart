import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample_aplikasi/siakad/service_forms.dart';
import 'package:sample_aplikasi/siakad/tata_tertib_perizinan.dart';
import 'theme_flow_test.dart' show app;

/// Lewati gerbang persetujuan tata tertib perizinan di form: scroll isi
/// sampai bawah, centang persetujuan, ketuk "Saya Setuju & Lanjutkan".
/// ListView sheet membangun anaknya secara malas; seretan dilakukan manual
/// dengan pumpAndSettle (scrollUntilVisible + pump 50ms membuat seretan
/// berikutnya jatuh di tengah animasi expand sheet/fling list sehingga
/// tombol di ujung bawah tak kunjung ter-build).
/// Target dicari berurutan dari atas ke bawah (checkbox dulu, baru tombol)
/// karena tombol di ujung bawah bisa ter-build saat checkbox di atasnya
/// sudah lewat dari jangkauan cache.
Future<void> dismissAgreementGate(WidgetTester t) async {
  final sheetScrollable = find.descendant(
      of: find.byType(ListView).last, matching: find.byType(Scrollable));
  for (var i = 0; i < 40; i++) {
    if (find.byType(Checkbox).evaluate().isNotEmpty) break;
    await t.drag(sheetScrollable, const Offset(0, -500));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(find.byType(Checkbox).first);
  await t.pumpAndSettle();
  await t.tap(find.byType(Checkbox).first);
  await t.pumpAndSettle();
  for (var i = 0; i < 40; i++) {
    if (find.text('Saya Setuju & Lanjutkan').evaluate().isNotEmpty) break;
    await t.drag(sheetScrollable, const Offset(0, -500));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(find.text('Saya Setuju & Lanjutkan'));
  await t.pumpAndSettle();
  await t.tap(find.text('Saya Setuju & Lanjutkan'));
  await t.pumpAndSettle();
}

Widget permitForm() => ServiceRequestForm(
    permit: true,
    ownerId: '001',
    searchPeople: (_) async => [],
    onSubmit: (_) async {});

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Tombol setuju nonaktif sampai dibaca dan dicentang',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    // Viewport sangat tinggi supaya seluruh isi sheet muat tanpa scroll,
    // sehingga tombol dan checkbox ter-build sejak awal.
    t.view.physicalSize = const Size(390, 12000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(permitForm()));
    await t.pumpAndSettle();
    expect(find.text('Tata Tertib Perizinan Santri'), findsOneWidget);
    final button = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Saya Setuju & Lanjutkan'));
    expect(button.onPressed, isNull);
    await t.tap(find.byType(Checkbox).first);
    await t.pumpAndSettle();
    final enabled = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Saya Setuju & Lanjutkan'));
    expect(enabled.onPressed, isNotNull);
    await t.tap(find.text('Saya Setuju & Lanjutkan'));
    await t.pumpAndSettle();
    expect(find.text('Tata Tertib Perizinan Santri'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(perizinanAgreedKey), isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('Scroll sampai bawah lalu setuju di layar kecil', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(permitForm()));
    await t.pumpAndSettle();
    expect(find.text('Tata Tertib Perizinan Santri'), findsOneWidget);
    await dismissAgreementGate(t);
    expect(find.text('Tata Tertib Perizinan Santri'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(perizinanAgreedKey), isTrue);
    await t.enterText(find.byType(TextFormField).first, 'Keperluan keluarga');
    expect(find.text('Keperluan keluarga'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Gerbang tidak muncul bila sudah pernah setuju', (t) async {
    SharedPreferences.setMockInitialValues({perizinanAgreedKey: true});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(permitForm()));
    await t.pumpAndSettle();
    expect(find.text('Tata Tertib Perizinan Santri'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
