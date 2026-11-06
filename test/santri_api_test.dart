import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sample_aplikasi/siakad/api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('NIS teks dan cookie akun website; tidak mengirim sesi ke origin lain',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    int requests = 0;
    final api = SantriApi(
        origin: Uri.parse('https://portal.example'),
        client: MockClient((req) async {
          requests++;
          if (req.url.path.endsWith('login')) {
            expect(jsonDecode(req.body)['nis'], '001');
            return http.Response('{}', 200, headers: {
              'set-cookie': 'santri-session=uji; Path=/; HttpOnly; Secure'
            });
          }
          expect(req.headers['cookie'], 'santri-session=uji');
          return http.Response('{"santri":{}}', 200);
        }));
    await api
        .call('/api/santri/auth/login', method: 'POST', body: {'nis': '001'});
    expect(await api.restore(), true);
    await api.call('/api/santri/me');
    await expectLater(api.call('https://outside.example/api/me'),
        throwsA(isA<PortalError>()));
    expect(requests, 2);
  });
  test('Sesi habis menghapus token dan draf tanpa menghapus preferensi umum',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      SantriApi.key: 'lama',
      'siakad.exam.1.1': 'uji',
      'preferensi': 'tetap'
    });
    final api = SantriApi(
        origin: Uri.parse('https://portal.example'),
        client: MockClient((_) async => http.Response('{}', 401)));
    bool expired = false;
    api.onExpired = () {
      expired = true;
    };
    expect(await api.restore(), true);
    await expectLater(api.call('/api/santri/me'), throwsA(isA<PortalError>()));
    expect(expired, true);
    expect(await api.restore(), false);
    expect(await api.vault.readAll(), {'preferensi': 'tetap'});
  });
}
