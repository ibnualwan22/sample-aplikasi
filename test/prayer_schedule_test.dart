import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sample_aplikasi/widgets/prayer_schedule_sheet.dart';
import 'theme_flow_test.dart' show app, screenshot;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    for (final (family, path) in [
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('STIXTwoText', 'assets/fonts/STIXTwoText.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });
  final times = PrayerTimes(
      Coordinates(-7.7613, 112.1818),
      DateComponents(2026, 11, 7),
      CalculationMethod.singapore.getParameters()..madhab = Madhab.shafi);
  final midday = times.dhuhr.subtract(const Duration(minutes: 90));
  Widget launcher({double scale = 1, DateTime? current}) => app(
      Scaffold(
          body: Builder(
              builder: (context) => Center(
                  child: FilledButton(
                      onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          useSafeArea: true,
                          isScrollControlled: true,
                          constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * .92,
                              maxWidth: 560),
                          builder: (_) => PrayerScheduleSheet(
                              latitude: -7.7613,
                              longitude: 112.1818,
                              location: 'Tulungrejo, Pare',
                              now: () => current ?? midday)),
                      child: const Text('Buka jadwal'))))),
      scale: scale);

  testWidgets(
      'Prayer sheet changes date, opens calendar, resets today and expands supporting times',
      (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 900);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(launcher());
    await t.tap(find.text('Buka jadwal'));
    await t.pumpAndSettle();
    expect(find.text('1 jam 30 menit lagi'), findsOneWidget);
    expect(find.text('Berikutnya'), findsOneWidget);
    await screenshot(t, 'jadwal-salat');
    await t.tap(find.byTooltip('Hari berikutnya'));
    await t.pumpAndSettle();
    expect(find.text('8 Nov 2026'), findsOneWidget);
    expect(find.text('SALAT BERIKUTNYA'), findsNothing);
    await t.tap(find.text('Kembali ke hari ini'));
    await t.pumpAndSettle();
    expect(find.text('7 Nov 2026'), findsOneWidget);
    await t.tap(find.text('7 Nov 2026'));
    await t.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await t.tap(find.text('Batal'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Waktu pendukung'), 180,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Waktu pendukung'));
    await t.pumpAndSettle();
    expect(find.text('Imsak'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Prayer sheet fits 320dp at 200% text, and after Isya points to tomorrow',
      (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 800);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(launcher(
        scale: 2, current: times.isha.add(const Duration(minutes: 1))));
    await t.tap(find.text('Buka jadwal'));
    await t.pumpAndSettle();
    expect(find.text('Subuh · besok'), findsOneWidget);
    expect(find.text('Berikutnya'), findsNothing);
    expect(t.takeException(), isNull);
    await t.tap(find.byTooltip('Tutup jadwal'));
    await t.pumpAndSettle();
    expect(find.byType(PrayerScheduleSheet), findsNothing);
  });
}
