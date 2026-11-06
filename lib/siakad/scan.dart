import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'api.dart';

/// Private socket for immediate feedback; the status endpoint remains usable
/// when the campus network blocks WebSockets.
class ScanMode extends StatefulWidget {
  const ScanMode(
      {super.key,
      required this.api,
      required this.payload,
      required this.initial});
  final SantriApi api;
  final String payload;
  final Set<String> initial;
  @override
  State<ScanMode> createState() => _Scan();
}

class _Scan extends State<ScanMode> {
  Timer? timer;
  WebSocket? socket;
  String? result;
  bool checking = false;
  @override
  void initState() {
    super.initState();
    connect();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => check());
  }

  void success(String name) {
    if (!mounted || result != null) return;
    setState(() => result = name);
    timer?.cancel();
    socket?.close();
  }

  Future<void> check() async {
    if (checking || !mounted) return;
    checking = true;
    try {
      final d = await widget.api.call('/api/santri/qr-saya/status');
      for (final r in rows(d['hadir'])) {
        if (!widget.initial.contains(val(r['kategoriId']))) {
          success(val(r['kategoriNama']));
          break;
        }
      }
    } catch (_) {/* Retry while scan mode is open. */} finally {
      checking = false;
    }
  }

  Future<void> connect() async {
    try {
      final d = obj(await widget.api.call('/api/santri/qr-saya/pusher-config'));
      if (!mounted || result != null || d['configured'] != true) return;
      final cluster = val(d['cluster']);
      if (!RegExp(r'^[a-z0-9-]+$').hasMatch(cluster)) return;
      final ws = await WebSocket.connect(Uri(
          scheme: 'wss',
          host: 'ws-$cluster.pusher.com',
          pathSegments: [
            'app',
            val(d['key'])
          ],
          queryParameters: {
            'protocol': '7',
            'client': 'flutter',
            'version': '1.0'
          }).toString());
      if (!mounted || result != null) {
        await ws.close();
        return;
      }
      socket = ws;
      await for (final raw in ws) {
        if (!mounted || result != null) break;
        final event = obj(jsonDecode(raw as String));
        final type = event['event'];
        if (type == 'pusher:connection_established') {
          final socketId = obj(jsonDecode(event['data']))['socket_id'];
          final auth = await widget.api.call('/api/santri/qr-saya/pusher-auth',
              method: 'POST',
              body: {'socket_id': socketId, 'channel_name': d['channel']});
          if (mounted && result == null)
            ws.add(jsonEncode({
              'event': 'pusher:subscribe',
              'data': {'channel': d['channel'], 'auth': auth['auth']}
            }));
        } else if (type == 'pusher:ping') {
          ws.add('{"event":"pusher:pong","data":{}}');
        } else if (type == 'scan-berhasil' &&
            event['channel'] == d['channel']) {
          final payload = event['data'];
          success(val(obj(payload is String ? jsonDecode(payload) : payload)[
              'kategoriNama']));
        }
      }
    } catch (_) {/* Polling is independent of push configuration. */}
  }

  @override
  void dispose() {
    timer?.cancel();
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(result == null ? 'Mode scan' : 'Absensi tercatat')),
      body: SafeArea(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: result == null
                          ? [
                              Flexible(
                                  child: AspectRatio(
                                      aspectRatio: 1,
                                      child: QrImageView(
                                          data: widget.payload,
                                          backgroundColor: Colors.white))),
                              const SizedBox(height: 20),
                              const Text(
                                  'Tunjukkan QR kepada petugas dan tunggu konfirmasi.')
                            ]
                          : [
                              const Icon(Icons.check_circle_outline, size: 56),
                              Text(result!),
                              const Text('Kehadiran sudah tercatat.'),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Selesai'))
                            ])))));
}
