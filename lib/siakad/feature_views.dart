part of 'features.dart';

extension _FeatureViews on _Page {
  Widget section(String title, {String? subtitle}) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        if (subtitle != null)
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ]));

  Widget panel(String title, List<Widget> children,
          {String? subtitle, Widget? badge, bool tinted = false}) =>
      Card(
          color: tinted ? MarkazColors.tint : null,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(subtitle,
                              style: Theme.of(context).textTheme.bodySmall)),
                    if (badge != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                              alignment: Alignment.centerLeft, child: badge)),
                    if (children.isNotEmpty) const SizedBox(height: 12),
                    ...children,
                  ])));

  String readable(dynamic value) =>
      {
        'ALPHA': 'Alpa',
        'HADIR': 'Hadir',
        'IZIN': 'Izin',
        'SAKIT': 'Sakit'
      }[val(value)] ??
      val(value).replaceAll('_', ' ');
  Widget badge(dynamic value) {
    final raw = val(value).toUpperCase();
    final color = ['DITOLAK', 'ALPHA', 'ALPA', 'TIDAK LULUS'].contains(raw)
        ? MarkazColors.danger
        : ['HADIR', 'LULUS', 'SELESAI', 'SUDAH_KEMBALI', 'DISETUJUI']
                .contains(raw)
            ? MarkazColors.success
            : MarkazColors.ink;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(8)),
        child: Text(readable(value),
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)));
  }

  Widget statistics(List<(String, dynamic)> values, {bool tappable = false}) =>
      LayoutBuilder(builder: (context, box) {
        final columns = MediaQuery.textScalerOf(context).scale(14) > 20 ||
                box.maxWidth < 250
            ? 1
            : 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final item in values)
            SizedBox(
                width: (box.maxWidth - (columns - 1) * 8) / columns,
                child: Material(
                    color: MarkazColors.ivory,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: recordFilter == item.$1 && tappable
                                ? MarkazColors.ink
                                : MarkazColors.line)),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: tappable
                            ? () => updateView(() => recordFilter =
                                recordFilter == item.$1 ? 'Semua' : item.$1)
                            : null,
                        child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(val(item.$2),
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(item.$1,
                                      style: const TextStyle(
                                          color: MarkazColors.muted,
                                          fontSize: 13)),
                                  if (tappable)
                                    const Text('Lihat catatan',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: MarkazColors.muted)),
                                ]))))),
        ]);
      });

  Widget filters(List<String> labels) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(spacing: 8, runSpacing: 4, children: [
        for (final label in labels)
          ChoiceChip(
              label: Text(label),
              selected: recordFilter == label,
              onSelected: (_) => updateView(() => recordFilter = label))
      ]));

  Widget primary(String title, Future<void> Function() fn,
          {IconData icon = Icons.arrow_forward}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: FilledButton.icon(
              onPressed: working ? null : () => run(fn),
              icon: Icon(icon, size: 20),
              label: Text(title)));

  Json get currentPeriod {
    final matches = history.where((h) => val(h['id']) == selectedPeriod);
    return matches.isNotEmpty
        ? matches.first
        : history.isEmpty
            ? {}
            : history.first;
  }

  Widget periodPicker() => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
              fields(currentPeriod, ['dufahNama', 'programNama', 'kelasNama'])),
          onPressed: history.length < 2
              ? null
              : () async {
                  final choice = await choose('Pilih periode', [
                    for (final h in history)
                      (
                        val(h['id']),
                        fields(h, ['dufahNama', 'programNama', 'kelasNama'])
                      )
                  ]);
                  if (choice != null && mounted)
                    updateView(() {
                      selectedPeriod = choice;
                      recordFilter = 'Semua';
                    });
                }));

  List<Widget> emptyRecords(String title, String message) =>
      [MarkazState(title: title, message: message)];

  List<Widget> attendanceView() {
    if (history.isEmpty)
      return emptyRecords(
          'Belum ada data absensi', 'Rekap tampil setelah absensi dicatat.');
    final h = currentPeriod;
    final summary = obj(h['rekapAbsen$attendanceCategory']);
    final entries = rows(h['absen$attendanceCategory'])
      ..sort((a, b) => val(b['tanggal']).compareTo(val(a['tanggal'])));
    String status(Json a) =>
        {
          'HADIR': 'Hadir',
          'IZIN': 'Izin',
          'SAKIT': 'Sakit',
          'ALPHA': 'Alpa',
          'ALPA': 'Alpa'
        }[val(a['status']).toUpperCase()] ??
        'Belum diketahui';
    final filtered = entries
        .where((a) => recordFilter == 'Semua' || status(a) == recordFilter)
        .toList();
    return [
      periodPicker(),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final label in ['Kelas', 'Sakan', 'Kegiatan', 'Tabirot'])
          ChoiceChip(
              label: Text(label == 'Tabirot' ? 'Ta’birot' : label),
              selected: attendanceCategory == label,
              onSelected: (_) => updateView(() {
                    attendanceCategory = label;
                    recordFilter = 'Semua';
                  }))
      ]),
      section('Kehadiran tercatat',
          subtitle:
              '${val(summary['hadir'])} hadir dari ${val(summary['total'])} sesi'),
      statistics([
        ('Hadir', summary['hadir']),
        ('Alpa', summary['alpha'] ?? summary['alpa']),
        ('Izin', summary['izin']),
        ('Sakit', summary['sakit'])
      ], tappable: true),
      section(
          recordFilter == 'Semua'
              ? 'Catatan absensi'
              : 'Catatan ${recordFilter.toLowerCase()}',
          subtitle: '${filtered.length} catatan tersedia'),
      if (recordFilter != 'Semua')
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed: () => updateView(() => recordFilter = 'Semua'),
                child: const Text('Tampilkan semua status'))),
      if (filtered.isEmpty)
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tidak ada catatan untuk pilihan ini.')),
      for (final a in filtered) ...[
        tile(
            date(a['tanggal']),
            fields(a, ['sesi', 'namaKegiatan', 'namaKelompok', 'keterangan'])
                .replaceAll('SESI_', 'Sesi '),
            readable(a['status'])),
        const Divider(height: 1),
      ],
    ];
  }

  List<Widget> gradeRows(Json h) => [
        if (rows(h['nilaiRows']).isEmpty)
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nilai belum diterbitkan.')),
        for (final n in rows(h['nilaiRows']))
          panel(
              val(n['namaIndo']),
              [
                Wrap(spacing: 16, runSpacing: 8, children: [
                  Text('Usbu 1: ${val(n['nilaiUsbu1'])}'),
                  Text('Usbu 2: ${val(n['nilaiUsbu2'])}'),
                  Text('Nihai: ${val(n['nilaiNihai'])}')
                ]),
                if (obj(n['predikat']).isNotEmpty)
                  Text(val(obj(n['predikat'])['indo']),
                      style: const TextStyle(color: MarkazColors.muted)),
              ],
              badge: badge('Skor ${val(n['skor'])}')),
      ];
  List<Widget> documents(Json h) => [
        if (h['transkripGabungan'] != null)
          group('Transkrip gabungan', [
            for (final n in rows(obj(h['transkripGabungan'])['nilaiRows']))
              tile(n['namaIndo'], null, n['skor']),
          ]),
        action('Lihat transkrip nilai', () => document('transkrip', h['id']),
            icon: Icons.description_outlined),
        if (h['canDownloadSyahadah'] == true)
          action('Lihat syahadah', () => document('syahadah', h['id']),
              icon: Icons.workspace_premium_outlined),
      ];
  List<Widget> gradesView() {
    if (history.isEmpty)
      return emptyRecords(
          'Belum ada data nilai', 'Nilai tampil setelah diterbitkan.');
    final h = currentPeriod;
    return [
      periodPicker(),
      panel(
          'Hasil belajar',
          [
            statistics([
              ('Rata-rata', h['average']),
              ('Mata pelajaran', rows(h['nilaiRows']).length)
            ]),
          ],
          badge: badge(h['statusKelulusan']),
          tinted: true),
      section('Nilai per mata pelajaran'),
      ...gradeRows(h),
      section('Dokumen akademik'),
      ...documents(h)
    ];
  }

  Future<void> detailSheet(String title, List<Widget> children) =>
      showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
          builder: (context) => SafeArea(
              top: false,
              child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    MarkazDialogTitle(title, icon: Icons.article_outlined),
                    const SizedBox(height: 16),
                    ...children,
                  ])));

  List<Widget> historyView() {
    if (history.isEmpty)
      return emptyRecords('Belum ada riwayat akademik',
          'Periode belajar Anda akan tampil di sini.');
    return [
      section('Perjalanan belajar',
          subtitle: '${history.length} periode tercatat'),
      for (final h in history)
        Container(
            padding: const EdgeInsets.only(left: 16, bottom: 24),
            decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(color: MarkazColors.gold, width: 3))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(val(h['dufahNama']),
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(val(h['programNama']),
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(val(h['kelasNama']),
                      style: const TextStyle(color: MarkazColors.muted)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    badge(h['statusKelulusan']),
                    Text('Rata-rata ${val(h['average'])}')
                  ]),
                  action(
                      'Detail periode',
                      () => detailSheet(val(h['dufahNama']),
                          [...gradeRows(h), ...documents(h)])),
                ])),
    ];
  }
}

extension _ServiceDetails on _Page {
  String permitStatus(Json p) {
    final original = val(p['statusIzin']);
    final start = DateTime.tryParse(val(p['tanggalMulai']));
    final now = DateTime.now();
    if (['HARIAN', 'TABIROT'].contains(p['tipeIzin']) &&
        ['AKTIF', 'MENUNGGU'].contains(original) &&
        start != null &&
        DateTime(start.year, start.month, start.day)
            .isBefore(DateTime(now.year, now.month, now.day)))
      return 'KADALUARSA';
    return original;
  }

  Future<void> beritaForm(Json record) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
      builder: (_) =>
          _BeritaForm(record: record, submit: (body) => send(endpoint, body)));
}

class _BeritaForm extends StatefulWidget {
  final Json record;
  final Future<void> Function(Json) submit;
  const _BeritaForm({required this.record, required this.submit});
  @override
  State<_BeritaForm> createState() => _BeritaFormState();
}

class _BeritaFormState extends State<_BeritaForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController minutes, note;
  late bool present;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final prior = obj(widget.record['beritaAcara']);
    present = prior['konfirmasiHadir'] != false;
    minutes =
        TextEditingController(text: '${widget.record['terlambatMenit'] ?? 0}');
    note = TextEditingController(text: prior['catatan']?.toString() ?? '');
  }

  @override
  void dispose() {
    minutes.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.submit({
        'absenPengajarId': widget.record['id'],
        'konfirmasiHadir': present,
        'terlambatMenit': present ? int.parse(minutes.text) : 0,
        'catatan': note.text.trim().isEmpty ? null : note.text.trim()
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        setState(() {
          saving = false;
          error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !saving,
      child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24 +
                  MediaQuery.viewInsetsOf(context).bottom +
                  MediaQuery.paddingOf(context).bottom),
          child: Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MarkazDialogTitle('Berita acara',
                        icon: Icons.assignment_outlined),
                    const SizedBox(height: 12),
                    Text(val(obj(widget.record['user'])['nama'])),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<bool>(
                        initialValue: present,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Kehadiran pengajar'),
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Hadir')),
                          DropdownMenuItem(
                              value: false, child: Text('Tidak hadir'))
                        ],
                        onChanged: saving
                            ? null
                            : (value) => setState(() => present = value!)),
                    if (present) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: minutes,
                          enabled: !saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Keterlambatan (menit)',
                              helperText: 'Isi 0 jika tepat waktu.'),
                          validator: (value) =>
                              int.tryParse(value ?? '') == null ||
                                      int.parse(value!) < 0
                                  ? 'Isi menit berupa angka 0 atau lebih.'
                                  : null)
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: note,
                        enabled: !saving,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                            labelText: 'Catatan (opsional)',
                            alignLabelWithHint: true)),
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!,
                              style:
                                  const TextStyle(color: MarkazColors.danger))),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: saving ? null : save,
                        child: Text(
                            saving ? 'Menyimpan…' : 'Simpan berita acara')),
                  ]))));
}
