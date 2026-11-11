import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/markaz_theme.dart';

/// Kunci persetujuan tata tertib perizinan (disimpan sekali per perangkat).
const perizinanAgreedKey = 'perizinan_agreed_v1';

/// 6 pasal Tata Tertib Perizinan Santri — salinan teks modal web
/// (src/components/public/tata-tertib-modal.tsx). Penekanan tebal di web
/// ditulis polos di sini; isi dan angkanya sama persis.
class _Pasal {
  const _Pasal(this.nomor, this.judul, this.paragraf, this.poin);
  final int nomor;
  final String judul;
  final String? paragraf;
  final List<String> poin;
}

const _pasal = [
  _Pasal(1, 'Jenis Perizinan', null, [
    'Perizinan keluar wilayah Pare',
    'Perizinan dalam wilayah Pare pada jam aktif',
    'Perizinan jam malam',
    'Perizinan tidak mengikuti agenda wajib Markaz Arabiyah dan Markaz Turats',
    'Perizinan Check Out pertengahan duf’ah atau marhalah',
  ]),
  _Pasal(
      2,
      'Prosedur Perizinan Keluar Wilayah Pare dan Dalam Wilayah Pare (Jam Aktif)',
      null,
      [
        'Santri datang langsung ke Maktab dan menemui General Manager atau Kepala Bagian Kedisiplinan dan Keamanan pada jam 11.30–13.00 WIB dan 16.30–17.00 WIB (Senin–Kamis), serta pukul 09.00–10.00 WIB atau 10.00–11.00 WIB (Jumat).',
        'Santri mengisi formulir perizinan yang telah disediakan.',
        'Santri wajib melakukan konfirmasi setelah kembali dan tiba di area Markaz Arabiyah dan Markaz Turats.',
        'Keterlambatan dalam melakukan konfirmasi akan dihitung sebagai pelanggaran dan dikenai sanksi kedisiplinan.',
      ]),
  _Pasal(
      3,
      'Perizinan Jam Malam dan Tidak Mengikuti Agenda Wajib',
      'Perizinan ini hanya diberikan jika terdapat udzur syar’i yang dibuktikan dengan dokumen pendukung. Santri dapat menghubungi Kepala Bagian Kedisiplinan dan Keamanan melalui WhatsApp di nomor 087730079154.',
      []),
  _Pasal(
      4,
      'Pelanggaran Berat',
      'Keluar wilayah Pare dan tidak mengikuti kegiatan wajib Markaz Arabiyah dan Markaz Turats tanpa keterangan atau tanpa mengikuti prosedur perizinan yang berlaku dianggap sebagai pelanggaran berat.',
      []),
  _Pasal(5, 'Perizinan Check Out Pertengahan Duf’ah atau Marhalah', null, [
    'Santri harus mengambil surat check out di kantor maktab Markaz.',
    'Santri wajib mendapatkan semua tanda tangan yang tercantum dalam surat check out.',
    'Surat check out diambil dua hari sebelum waktu keberangkatan.',
    'Santri yang keluar tanpa mengikuti prosedur check out akan langsung mendapatkan SP 3 dan masuk daftar blacklist.',
    'Setelah memenuhi prosedur perizinan, santri diberi waktu 1×24 jam untuk keluar dari sakan.',
  ]),
  _Pasal(
      6,
      'Larangan Perizinan Rihlah Sebelum Haflah',
      'Santri dilarang mengajukan perizinan untuk kegiatan rihlah sebelum pelaksanaan haflah.',
      []),
];

/// Tampilkan tata tertib perizinan.
///
/// [requireAgreement]: gerbang persetujuan pertama kali — wajib scroll
/// sampai bawah, centang persetujuan, baru tombol aktif. Persetujuan
/// tersimpan di perangkat. Mengembalikan true bila disetujui atau ditutup
/// dari tombol; null bila sheet ditutup lewat tombol kembali perangkat.
Future<bool?> showTataTertibPerizinan(BuildContext context,
        {bool requireAgreement = false}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: !requireAgreement,
      enableDrag: !requireAgreement,
      builder: (c) => _TataTertibSheet(requireAgreement: requireAgreement),
    );

class _TataTertibSheet extends StatefulWidget {
  const _TataTertibSheet({required this.requireAgreement});
  final bool requireAgreement;
  @override
  State<_TataTertibSheet> createState() => _TataTertibSheetState();
}

class _TataTertibSheetState extends State<_TataTertibSheet> {
  bool _readToBottom = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    // Bila isi muat tanpa scroll, langsung dianggap sudah dibaca seluruhnya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = PrimaryScrollController.of(context);
      if (controller.hasClients &&
          controller.position.maxScrollExtent <= 24) {
        setState(() => _readToBottom = true);
      }
    });
  }

  bool _onScroll(ScrollNotification n) {
    // ListView memakai controller sheet (PrimaryScrollController) agar
    // seretan sheet dan scroll isi terkoordinasi — controller sendiri
    // membuat sheet menelan seretan (terbukti di tes: offset macet).
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      final m = n.metrics;
      if (!_readToBottom && m.pixels >= m.maxScrollExtent - 24) {
        setState(() => _readToBottom = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Tinggi sheet dibatasi (85% layar). Seluruh isi — judul, pasal,
    // centang, dan tombol — berada dalam satu ListView supaya tidak ada
    // bagian berukuran tetap yang overflow pada layar kecil/teks besar
    // (judul + centang saja bisa setinggi ~1300px pada 320dp/200%).
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
        top: false,
        child: SizedBox(
            height: height,
            child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    const Icon(Icons.menu_book_rounded, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Tata Tertib Perizinan Santri',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          Text('Markaz Arabiyah & Markaz Turats',
                              style: TextStyle(
                                  color: MarkazColors.muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ])),
                    if (!widget.requireAgreement)
                      IconButton(
                          tooltip: 'Tutup',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                  ])),
              const SizedBox(height: 12),
              Expanded(
                  child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      children: [
                        for (final p in _pasal) ...[
                          _PasalCard(pasal: p),
                          const SizedBox(height: 12),
                        ],
                        const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 12),
                            child: Text(
                                'الإذن الذي يتم التعامل معه بشكل صحيح يعكس أخلاق وآداب الطالب الحقيقي',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontStyle: FontStyle.italic))),
                        if (widget.requireAgreement) ...[
                          if (!_readToBottom)
                            const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text('Scroll ke bawah untuk membaca',
                                    style: TextStyle(
                                        color: MarkazColors.muted,
                                        fontSize: 12))),
                          CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              value: _agreed,
                              onChanged: _readToBottom
                                  ? (v) =>
                                      setState(() => _agreed = v ?? false)
                                  : null,
                              title: const Text.rich(TextSpan(children: [
                                TextSpan(
                                    text:
                                        'Saya sudah membaca, memahami, dan '),
                                TextSpan(
                                    text: 'siap menaati',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                                TextSpan(
                                    text:
                                        ' seluruh peraturan perizinan di Markaz Arabiyah & Markaz Turats.'),
                              ]))),
                          const SizedBox(height: 12),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                  onPressed: _agreed
                                      ? () async {
                                          final prefs =
                                              await SharedPreferences
                                                  .getInstance();
                                          await prefs.setBool(
                                              perizinanAgreedKey, true);
                                          if (!mounted) return;
                                          Navigator.pop(context, true);
                                        }
                                      : null,
                                  child: const Text(
                                      'Saya Setuju & Lanjutkan'))),
                        ] else
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonal(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'))),
                      ]))),
            ]))));
  }
}

class _PasalCard extends StatelessWidget {
  const _PasalCard({required this.pasal});
  final _Pasal pasal;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: MarkazColors.ivory,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MarkazColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: MarkazColors.gold, shape: BoxShape.circle),
              child: Text('${pasal.nomor}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800))),
          const SizedBox(width: 8),
          Expanded(
              child: Text(pasal.judul,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        if (pasal.paragraf != null) Text(pasal.paragraf!),
        if (pasal.poin.isNotEmpty)
          for (final poin in pasal.poin)
            Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4, top: 2),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(poin)),
                    ])),
      ]));
}
