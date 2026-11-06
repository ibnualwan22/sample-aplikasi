import 'package:flutter/material.dart';

typedef Feature = ({String title, IconData icon, int tab, String? role});
const features = <Feature>[
  (title: 'Nilai', icon: Icons.description_outlined, tab: 1, role: null),
  (title: 'Absensi', icon: Icons.event_available_outlined, tab: 1, role: null),
  (title: 'Ujian', icon: Icons.quiz_outlined, tab: 1, role: null),
  (title: 'QR Saya', icon: Icons.qr_code, tab: 2, role: null),
  (title: 'Perizinan', icon: Icons.assignment_outlined, tab: 2, role: null),
  (title: 'Daftar ulang', icon: Icons.autorenew, tab: 2, role: null),
  (title: 'Hasil Tes', icon: Icons.fact_check_outlined, tab: 1, role: null),
  (title: 'Riwayat', icon: Icons.history, tab: 1, role: null),
  (title: 'Tauzi’ Fushul', icon: Icons.edit_note, tab: 1, role: null),
  (title: 'Nadi Hufadz', icon: Icons.menu_book_outlined, tab: 1, role: null),
  (
    title: 'Tasmi’',
    icon: Icons.record_voice_over_outlined,
    tab: 1,
    role: 'isHufadz'
  ),
  (
    title: 'Check out',
    icon: Icons.door_front_door_outlined,
    tab: 2,
    role: null
  ),
  (title: 'WhatsApp AI', icon: Icons.chat_outlined, tab: 2, role: null),
  (title: 'Denah Sakan', icon: Icons.map_outlined, tab: 2, role: null),
  (title: 'Galeri', icon: Icons.photo_library_outlined, tab: 2, role: null),
  (title: 'Pemilihan', icon: Icons.how_to_vote_outlined, tab: 2, role: null),
  (
    title: 'Berita Acara',
    icon: Icons.assignment_turned_in_outlined,
    tab: 2,
    role: 'isKetuaKelas'
  ),
  (
    title: 'Lapor Mukholif',
    icon: Icons.report_outlined,
    tab: 2,
    role: 'pelapor'
  ),
  (title: 'Eksekusi Iqob', icon: Icons.task_alt, tab: 2, role: 'isLajnah'),
];
