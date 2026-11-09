import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/services/push_service.dart';

void main() {
  test('judul notifikasi = pengirim, judul pengumuman tebal di isi', () {
    final content = buildPengumumanNotification({
      'pengirim': 'Admin Markaz',
      'judul': 'Testing',
      'isi': 'Liburt',
      'url': '/santri/pengumuman',
      'pengumumanId': 'cm123abc',
    });
    expect(content.title, 'Admin Markaz');
    expect(content.body, '<b>Testing</b><br>Liburt');
    final payload = jsonDecode(content.payload) as Map<String, dynamic>;
    expect(payload['pengumumanId'], 'cm123abc');
    expect(payload['url'], '/santri/pengumuman');
  });

  test('tanpa pengirim memakai judul Pengumuman', () {
    final content = buildPengumumanNotification({
      'pengirim': '',
      'judul': 'Info',
      'isi': 'Isi info',
      'url': '/santri/pengumuman',
      'pengumumanId': '',
    });
    expect(content.title, 'Pengumuman');
    expect(content.body, '<b>Info</b><br>Isi info');
  });

  test('tanpa judul, isi saja tanpa baris tebal', () {
    final content = buildPengumumanNotification({
      'pengirim': 'Admin',
      'judul': '',
      'isi': 'Hanya isi',
      'url': '/santri/pengumuman',
      'pengumumanId': '',
    });
    expect(content.body, 'Hanya isi');
  });

  test('karakter HTML di judul dan isi di-escape', () {
    final content = buildPengumumanNotification({
      'pengirim': 'Admin',
      'judul': 'A <b> & B',
      'isi': 'x < y',
      'url': '/santri/pengumuman',
      'pengumumanId': '',
    });
    expect(content.body, '<b>A &lt;b&gt; &amp; B</b><br>x &lt; y');
  });

  test('payload ketukan membawa pengumumanId untuk deep link', () {
    final content = buildPengumumanNotification({
      'pengirim': 'Admin',
      'judul': 'Judul',
      'isi': 'Isi',
      'url': '/santri/pengumuman',
      'pengumumanId': 'cm999',
    });
    final link =
        resolvePengumumanDeepLink(jsonDecode(content.payload) as Map<String, dynamic>);
    expect(link.pengumumanId, 'cm999');
  });
}
