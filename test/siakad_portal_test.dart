import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/config/siakad_portal.dart';

void main() {
  test(
      'trusted origin excludes lookalike hosts, credentials, schemes and ports',
      () {
    final portal =
        SiakadPortal('https://siakad.markazarabiyah.site/santri?ignore=1#x');
    expect(portal.dashboard.toString(),
        'https://siakad.markazarabiyah.site/santri/dashboard');
    expect(
        portal
            .owns(Uri.parse('https://siakad.markazarabiyah.site/santri/nilai')),
        isTrue);
    for (final url in [
      'https://siakad.markazarabiyah.site.evil.test/santri',
      'http://siakad.markazarabiyah.site/santri',
      'https://siakad.markazarabiyah.site:8443/santri',
      'https://user@siakad.markazarabiyah.site/santri',
    ]) {
      expect(portal.owns(Uri.parse(url)), isFalse);
    }
  });
  test('production rejects cleartext; debug only permits local cleartext', () {
    expect(() => SiakadPortal('http://example.com'), throwsFormatException);
    expect(() => SiakadPortal('http://localhost:3000'), throwsFormatException);
    expect(() => SiakadPortal('http://example.com', allowLocalHttp: true),
        throwsFormatException);
    expect(
        SiakadPortal('http://10.0.2.2:3000', allowLocalHttp: true)
            .dashboard
            .scheme,
        'http');
  });
  test('script and file navigation never launch an external app', () {
    for (final scheme in [
      'javascript:alert(1)',
      'file:///tmp/private',
      'data:text/html,test',
      'intent://example'
    ]) {
      expect(SiakadPortal.canOpenExternally(Uri.parse(scheme)), isFalse);
    }
  });
}
