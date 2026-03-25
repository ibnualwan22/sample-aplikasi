import 'package:flutter/material.dart';

void showComingSoonDialog(BuildContext context, String featureName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Coming Soon', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Fitur "$featureName" saat ini sedang dalam tahap pengembangan.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Tutup', style: TextStyle(color: Color(0xFFD4AF37))),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
