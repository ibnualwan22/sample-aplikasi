import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/screens/siakad_portal_screen.dart';
import 'package:sample_aplikasi/siakad/api.dart';

class DemoApi extends SantriApi {
  DemoApi({this.exists = false})
      : super(origin: Uri.parse('https://example.invalid'));
  bool exists;
  final paths = <String>[];
  String? submitted;
  @override
  Future<bool> restore() async => exists;
  @override
  Future<dynamic> call(String path, {String method = 'GET', Json? body}) async {
    paths.add(path);
    if (path.endsWith('/auth/login')) {
      submitted = body?['nis'];
      if (submitted == 'salah') throw const PortalError('NIS tidak ditemukan');
      session = 'test';
      exists = true;
      return {};
    }
    if (path == '/api/santri/me')
      return {
        'santri': {'id': '001', 'nama': 'Santri uji', 'isAktif': true},
        'riwayat': [],
        'menu': {'isKetuaKelas': true}
      };
    if (path == '/api/mobile/hasil-tes')
      return {'active_dufah': 'Dufah uji', 'data': []};
    return {};
  }
}

void main() {
  testWidgets(
      'Login mempertahankan nol awal, menawarkan menu sesuai peran dan tombol mode umum',
      (t) async {
    final api = DemoApi();
    bool public = false;
    await t.pumpWidget(MaterialApp(
        home: SiakadPortalScreen(
            api: api,
            onExit: () {
              public = true;
            })));
    await t.pumpAndSettle();
    expect(api.paths, isEmpty);
    await t.enterText(find.byType(TextField), '001');
    await t.tap(find.text('Masuk'));
    await t.pumpAndSettle();
    expect(api.submitted, '001');
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('QR Saya'), findsOneWidget);
    await t.tap(find.text('Semua fitur'));
    await t.pumpAndSettle();
    expect(find.text('Berita Acara'), findsOneWidget);
    expect(find.text('Eksekusi Iqob'), findsNothing);
    await t.tap(find.text('Halaman umum'));
    expect(public, isTrue);
    expect(api.exists, isTrue);
  });
  testWidgets('Pintasan hasil tes melanjutkan ke data akun setelah login',
      (t) async {
    final api = DemoApi();
    await t.pumpWidget(
        MaterialApp(home: SiakadPortalScreen(api: api, resultRequest: 1)));
    await t.pumpAndSettle();
    expect(api.paths, isEmpty);
    await t.enterText(find.byType(TextField), '001');
    await t.tap(find.text('Masuk'));
    await t.pumpAndSettle();
    expect(find.text('Dufah uji'), findsOneWidget);
    expect(api.paths.last, '/api/mobile/hasil-tes');
  });
  testWidgets('NIS salah tetap di login', (t) async {
    final api = DemoApi();
    await t.pumpWidget(MaterialApp(home: SiakadPortalScreen(api: api)));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'salah');
    await t.tap(find.text('Masuk'));
    await t.pumpAndSettle();
    expect(find.text('NIS tidak ditemukan'), findsOneWidget);
    expect(find.text('QR Saya'), findsNothing);
  });
}
