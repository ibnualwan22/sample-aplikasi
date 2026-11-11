import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/screens/about_screen.dart';
import 'package:sample_aplikasi/screens/references_screen.dart';
import 'package:sample_aplikasi/screens/settings_screen.dart';
import 'theme_flow_test.dart' show app;

void main() {
  testWidgets('Setelan menampilkan menu Referensi dan Tentang Aplikasi',
      (t) async {
    await t.pumpWidget(app(const SettingsScreen()));
    await t.pumpAndSettle();
    expect(find.text('Referensi'), findsOneWidget);
    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Ketuk menu Tentang Aplikasi membuka halamannya', (t) async {
    await t.pumpWidget(app(const SettingsScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Tentang Aplikasi'));
    await t.pumpAndSettle();
    expect(find.text('Markaz Arabiyah Tech'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Tentang Aplikasi: foto, versi, dan 18 anggota bernomor',
      (t) async {
    await t.pumpWidget(app(const AboutScreen()));
    await t.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Versi 1.0.7+10'), findsOneWidget);
    expect(find.text('Aplikasi ini dikembangkan oleh Aksara X KSU Batch 10.'),
        findsOneWidget);
    // 18 lingkaran bernomor = 18 anggota.
    expect(find.byType(CircleAvatar), findsNWidgets(18));
    expect(find.text('Evita Desi Safitri, S.F.U., S.H.'), findsOneWidget);
    expect(find.text("Syti Qoirunisa' Nurdiniyah, S.Pd"), findsOneWidget);
    expect(find.text('Ahmad Ibnu Alwan, S.Ag.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Referensi menampilkan empat sumber data', (t) async {
    await t.pumpWidget(app(const ReferencesScreen()));
    await t.pumpAndSettle();
    expect(find.text('Waktu Salat'), findsOneWidget);
    expect(find.text("Al-Qur'an"), findsOneWidget);
    expect(find.text('Tafsir'), findsOneWidget);
    expect(find.text('Arah Kiblat'), findsOneWidget);
    expect(find.textContaining('api.myquran.com'), findsOneWidget);
    expect(find.textContaining('equran.id'), findsWidgets);
    expect(find.textContaining('api.quran.com'), findsOneWidget);
    expect(find.textContaining('flutter_qiblah'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
