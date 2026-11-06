import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/siakad_portal.dart';

typedef Json = Map<String, dynamic>;
Json obj(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : {};
List<Json> rows(dynamic v) =>
    v is List ? v.whereType<Map>().map(obj).toList() : [];
String val(dynamic v) => v == null || v == '' ? '—' : v.toString();

class PortalError implements Exception {
  final String message;
  final int code;
  const PortalError(this.message, [this.code = 0]);
  @override
  String toString() => message;
}

class SantriApi {
  SantriApi({http.Client? client, Uri? origin})
      : _client = client ?? http.Client(),
        origin = origin ??
            SiakadPortal(AppConfig.siakadPortalUrl, allowLocalHttp: kDebugMode)
                .origin;
  final http.Client _client;
  final Uri origin;
  final vault = const FlutterSecureStorage();
  static const key = 'siakad.session.v1';
  String? session, tauzi;
  VoidCallback? onExpired;
  Future<bool> restore() async {
    session = await vault.read(key: key);
    return session != null;
  }

  Future<void> clear() async {
    session = null;
    tauzi = null;
    await vault.delete(key: key);
    for (final k in (await vault.readAll())
        .keys
        .where((k) => k.startsWith("siakad.exam."))
        .toList()) {
      await vault.delete(key: k);
    }
  }

  Future<dynamic> call(String path, {String method = 'GET', Json? body}) async {
    final uri = origin.resolve(path);
    if (uri.origin != origin.origin || !uri.path.startsWith('/api/'))
      throw const PortalError('Alamat layanan tidak valid.');
    final token = session;
    final request = http.Request(method, uri)..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    final secondary = uri.path.startsWith('/api/tauzi/');
    final cookies = [
      if (token != null) 'santri-session=$token',
      if (secondary && tauzi != null) 'tauzi-session=$tauzi'
    ];
    if (cookies.isNotEmpty) request.headers['Cookie'] = cookies.join('; ');
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response r;
    try {
      r = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const PortalError(
          'Koneksi terputus. Periksa status sebelum mencoba lagi.');
    }
    final dynamic data;
    try {
      data = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw const PortalError('Respons server tidak dapat dibaca.');
    }
    if (r.statusCode == 401 &&
        token != null &&
        token == session &&
        !secondary) {
      await clear();
      onExpired?.call();
    }
    if (token != session && token != null)
      throw const PortalError('Sesi telah berakhir.');
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw PortalError(
          obj(data)['error']?.toString() ??
              obj(data)['message']?.toString() ??
              'Layanan tidak tersedia.',
          r.statusCode);
    if (path == '/api/santri/auth/login' || path == '/api/tauzi/auth/login') {
      final name = secondary ? 'tauzi-session' : 'santri-session';
      final value = RegExp('(?:^|, *)$name=([^;, ]+)')
          .firstMatch(r.headers['set-cookie'] ?? '')
          ?.group(1);
      if (value == null)
        throw const PortalError('Server tidak mengirim sesi login.');
      if (secondary) {
        tauzi = value;
      } else {
        await vault.write(key: key, value: value);
        session = value;
      }
    }
    return data;
  }

  Future<void> logout() async {
    try {
      await call('/api/santri/auth/logout', method: 'POST');
    } finally {
      await clear();
    }
  }

  void dispose() => _client.close();
}
