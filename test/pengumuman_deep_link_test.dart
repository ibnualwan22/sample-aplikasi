import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/services/push_service.dart';

void main() {
  test('pengumumanId membuka satu pengumuman', () {
    final link = resolvePengumumanDeepLink({
      'url': '/santri/pengumuman',
      'pengumumanId': 'cm123abc',
    });
    expect(link.pengumumanId, 'cm123abc');
    expect(link.externalUrl, isNull);
  });

  test('tautan relatif membuka inbox', () {
    final link = resolvePengumumanDeepLink({
      'url': '/santri/pengumuman',
      'pengumumanId': '',
    });
    expect(link.pengumumanId, isNull);
    expect(link.externalUrl, isNull);
    expect(link.openInbox, isTrue);
  });

  test('tautan eksternal dibuka di luar aplikasi', () {
    final link = resolvePengumumanDeepLink({
      'url': 'https://forms.example/isi',
      'pengumumanId': '',
    });
    expect(link.externalUrl, 'https://forms.example/isi');
    expect(link.openInbox, isFalse);
  });

  test('tanpa data tetap membuka inbox', () {
    final link = resolvePengumumanDeepLink({});
    expect(link.openInbox, isTrue);
    expect(link.isEmpty, isFalse);
  });
}
