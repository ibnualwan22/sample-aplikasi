import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Membungkus tampilan QR: selama widget ini terpasang, kecerahan layar
/// aplikasi dinaikkan ke maksimum (seperti aplikasi pembayaran saat
/// menampilkan QRIS) supaya QR mudah dipindai; saat ditinggalkan,
/// kecerahan dikembalikan ke pengaturan sistem.
///
/// Di Android kecerahan ini per-jendela (otomatis pulih bila aplikasi
/// dimatikan), tapi di iOS ia sistem-wide — karena itu widget ini juga
/// mengembalikan kecerahan saat aplikasi diminimalkan, supaya tidak
/// tertinggal maksimal bila aplikasi dimatikan dari halaman QR.
///
/// Semua panggilan platform dibungkus try/catch: di perangkat yang tidak
/// mendukung / di tes unit (channel belum siap), widget tetap tampil
/// normal tanpa mengubah kecerahan.
class QrBrightness extends StatefulWidget {
  const QrBrightness({super.key, required this.child});

  final Widget child;

  @override
  State<QrBrightness> createState() => _QrBrightnessState();
}

class _QrBrightnessState extends State<QrBrightness>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_applyMax());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_restore());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_applyMax());
    }
  }

  Future<void> _applyMax() async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
      if (!mounted) {
        // Widget keburu dibuang selagi set berjalan: pulihkan langsung
        // supaya kecerahan tidak tertinggal maksimal.
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
    } catch (_) {
      // Platform tidak mendukung / channel belum siap: abaikan.
    }
  }

  Future<void> _restore() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (_) {
      // Abaikan: tidak ada yang perlu dipulihkan.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_restore());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
