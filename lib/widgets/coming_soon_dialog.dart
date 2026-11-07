import 'package:flutter/material.dart';
import 'markaz_components.dart';

void showComingSoonDialog(BuildContext context, String featureName) {
  showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
              scrollable: true,
              contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              content: MarkazState(
                  title: '$featureName belum tersedia',
                  message:
                      'Layanan ini sedang disiapkan. Anda tetap dapat menggunakan layanan lainnya.',
                  pose: MascotPose.unavailable),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Tutup'))
              ]));
}
