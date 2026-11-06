import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

class SantriFileView extends StatefulWidget {
  const SantriFileView(
      {super.key,
      required this.title,
      required this.bytes,
      required this.type,
      required this.filename,
      this.exportPng = false});
  final String title, type, filename;
  final Uint8List bytes;
  final bool exportPng;
  @override
  State<SantriFileView> createState() => _FileView();
}

class _FileView extends State<SantriFileView> {
  bool busy = false;
  Future<void> save(bool png) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final bytes = png
          ? await (await Printing.raster(widget.bytes, pages: [0], dpi: 150)
                  .first)
              .toPng()
          : widget.bytes;
      final saved = await const MethodChannel('markaz/documents')
          .invokeMethod<bool>('save', {
        'name':
            png ? '${widget.filename.split('.').first}.png' : widget.filename,
        'mime': png ? 'image/png' : widget.type,
        'bytes': bytes
      });
      if (mounted && saved == true)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Dokumen tersimpan.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal menyimpan dokumen. Coba lagi.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          PopupMenuButton<bool>(
              tooltip: 'Simpan dokumen',
              enabled: !busy,
              onSelected: save,
              icon: const Icon(Icons.download_outlined),
              itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: false, child: Text('Simpan salinan')),
                    if (widget.exportPng)
                      const PopupMenuItem(
                          value: true, child: Text('Simpan sebagai PNG'))
                  ])
      ]),
      body: widget.type == 'application/pdf'
          ? PdfPreview(
              build: (_) => widget.bytes,
              pdfFileName: widget.filename,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false)
          : Center(
              child: InteractiveViewer(child: Image.memory(widget.bytes))));
}
