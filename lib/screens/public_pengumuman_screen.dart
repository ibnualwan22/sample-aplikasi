import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../siakad/api.dart';
import '../theme/markaz_theme.dart';
import '../widgets/markaz_components.dart';

/// Daftar pengumuman GLOBAL untuk tamu (belum login) — butir 4 batch 1.0.6+7.
/// Memakai endpoint publik baru Siakad GET /api/pengumuman/publik (tanpa
/// sesi); tanpa status dibaca dan tanpa tombol tandai dibaca.
class PublicPengumumanScreen extends StatefulWidget {
  const PublicPengumumanScreen({super.key});

  @override
  State<PublicPengumumanScreen> createState() => _PublicPengumumanState();
}

class _PublicPengumumanState extends State<PublicPengumumanScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = SantriApi();
      final d = obj(await api.call('/api/pengumuman/publik'));
      if (!mounted) return;
      setState(() {
        _items = rows(d['items']);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  String _tanggal(dynamic v) {
    final dt = v is String ? DateTime.tryParse(v) : null;
    if (dt == null) return '';
    return DateFormat('d MMM yyyy', 'id_ID').format(dt);
  }

  Future<void> _open(Json p) async {
    final tautan = val(p['tautan']);
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(val(p['judul'])),
        content: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${val(p['pengirimLabel'])} · ${_tanggal(p['dibuatAt'])}',
                  style: const TextStyle(
                      color: MarkazColors.muted, fontSize: 13)),
              const SizedBox(height: 12),
              Text(val(p['isi'])),
            ])),
        actions: [
          if (tautan.startsWith('https://'))
            TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  launchUrl(Uri.parse(tautan),
                      mode: LaunchMode.externalApplication);
                },
                child: const Text('Buka tautan')),
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _failed || _items.isEmpty
                ? const MarkazState(
                    title: 'Belum ada pengumuman',
                    message:
                        'Pengumuman dari pengurus dan admin akan tampil di sini.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final p = _items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(val(p['judul']),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${val(p['pengirimLabel'])} · ${_tanggal(p['dibuatAt'])}',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _open(p),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
