import '../widgets/markaz_components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/markaz_theme.dart';
import 'api.dart';

/// A single draft survives nested pickers and recoverable submission failures.
class ServiceRequestForm extends StatefulWidget {
  const ServiceRequestForm(
      {super.key,
      required this.permit,
      required this.ownerId,
      required this.searchPeople,
      required this.onSubmit,
      this.canChooseReporter = false});
  final bool permit, canChooseReporter;
  final String ownerId;
  final Future<List<Json>> Function(String query) searchPeople;
  final Future<void> Function(Json body) onSubmit;
  @override
  State<ServiceRequestForm> createState() => _RequestForm();
}

class _RequestForm extends State<ServiceRequestForm> {
  final form = GlobalKey<FormState>();
  final reason = TextEditingController(), place = TextEditingController();
  String type = 'HARIAN';
  bool group = false, busy = false;
  String? error;
  DateTime start = DateTime.now();
  DateTime? end;
  TimeOfDay time = TimeOfDay.now();
  Map<String, Json> people = {};
  Json? reporter;
  static const types = {
    'HARIAN': 'Harian',
    'BERHARI_HARI': 'Berhari-hari',
    'KELUAR_PARE': 'Keluar Pare',
    'TABIROT': 'Tabirot'
  };
  String date(DateTime d) => DateFormat('dd MMM yyyy', 'id_ID').format(d);
  String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  @override
  void dispose() {
    reason.dispose();
    place.dispose();
    super.dispose();
  }

  Future<void> pickDate(bool last) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
        context: context,
        helpText: last
            ? 'Sampai tanggal'
            : widget.permit
                ? 'Tanggal mulai'
                : 'Tanggal kejadian',
        initialDate: last ? end ?? start : start,
        firstDate: last ? start : DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2));
    if (!mounted || selected == null) return;
    setState(() {
      if (last) {
        end = selected;
      } else {
        start = selected;
        if (end?.isBefore(start) == true) end = null;
      }
    });
  }

  Future<void> pickPeople({bool asReporter = false}) async {
    final selected = await showModalBottomSheet<Map<String, Json>>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (c) => PeoplePicker(
            search: widget.searchPeople,
            single: asReporter,
            initial: asReporter
                ? {if (reporter != null) val(reporter!['id']): reporter!}
                : people,
            idKey: widget.permit ? 'riwayatId' : 'id'));
    if (!mounted || selected == null) return;
    setState(() {
      if (asReporter) {
        reporter = selected.values.firstOrNull;
      } else {
        people = selected;
      }
    });
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if ((!widget.permit || group) && people.isEmpty) {
      setState(() => error = 'Pilih minimal satu santri.');
      return;
    }
    if (widget.permit && type == 'BERHARI_HARI' && end == null) {
      setState(() => error = 'Pilih tanggal selesai izin.');
      return;
    }
    final summary = <(String, String)>[
      if (widget.permit) ('Jenis izin', types[type]!),
      (
        'Pemohon',
        widget.permit && !group
            ? 'Saya sendiri'
            : people.values.map((p) => val(p['nama'])).join(', ')
      ),
      if (reporter != null) ('Pelapor', val(reporter!['nama'])),
      (
        'Tanggal',
        '${date(start)}${widget.permit ? end != null && type == 'BERHARI_HARI' ? ' – ${date(end!)}' : '' : ' · ${time.format(context)}'}'
      ),
      if (!widget.permit) ('Tempat', place.text.trim()),
      (
        widget.permit ? 'Alasan' : 'Perkataan yang diucapkan',
        reason.text.trim()
      ),
    ];
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                scrollable: true,
                title: MarkazDialogTitle(
                    widget.permit ? 'Tinjau pengajuan izin' : 'Tinjau laporan'),
                content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final row in summary)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.$1,
                                      style: const TextStyle(
                                          color: MarkazColors.muted,
                                          fontSize: 12)),
                                  Text(row.$2)
                                ]))
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Periksa lagi')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(
                          widget.permit ? 'Kirim pengajuan' : 'Kirim laporan'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final body = widget.permit
          ? <String, dynamic>{
              'tipeIzin': type,
              'alasan': reason.text.trim(),
              'tanggalMulai': iso(start),
              'tanggalSelesai': type == 'BERHARI_HARI' ? iso(end!) : null,
              'riwayatIds': group ? people.keys.toList() : [widget.ownerId],
            }
          : <String, dynamic>{
              'laporan': [
                {
                  'pelanggarIds': people.keys.toList(),
                  'tempatMelanggar': place.text.trim(),
                  'perkataanYgDiucapkan': reason.text.trim(),
                  'waktuMelanggar': DateTime(start.year, start.month, start.day,
                          time.hour, time.minute)
                      .toUtc()
                      .toIso8601String(),
                  if (reporter != null) 'pelaporKustomId': reporter!['id'],
                  if (reporter != null) 'pelaporKustomNama': reporter!['nama'],
                }
              ]
            };
      await widget.onSubmit(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: Scaffold(
          appBar: AppBar(
              title: Text(widget.permit ? 'Ajukan izin' : 'Buat laporan')),
          body: SafeArea(
              child: Form(
                  key: form,
                  child: AbsorbPointer(
                      absorbing: busy,
                      child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text(
                                widget.permit
                                    ? 'Lengkapi kebutuhan izin Anda'
                                    : 'Catat kejadian dengan lengkap',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            const Text(
                                'Periksa kembali rincian sebelum mengirim.',
                                style: TextStyle(color: MarkazColors.muted)),
                            const SizedBox(height: 24),
                            if (widget.permit) ...[
                              DropdownButtonFormField<String>(
                                  initialValue: type,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Jenis izin'),
                                  items: [
                                    for (final t in types.entries)
                                      DropdownMenuItem(
                                          value: t.key, child: Text(t.value))
                                  ],
                                  onChanged: (v) => setState(() => type = v!)),
                              const SizedBox(height: 16),
                              SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Izin kelompok'),
                                  subtitle: const Text(
                                      'Ajukan untuk beberapa santri'),
                                  value: group,
                                  onChanged: (v) => setState(() => group = v)),
                            ],
                            if (!widget.permit || group) ...[
                              OutlinedButton.icon(
                                  onPressed: pickPeople,
                                  icon: const Icon(Icons.group_outlined),
                                  label:
                                      Text('Pilih santri (${people.length})')),
                              for (final p in people.values)
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(val(p['nama'])),
                                    trailing: IconButton(
                                        tooltip: 'Hapus ${val(p['nama'])}',
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(() =>
                                            people.remove(val(p[widget.permit
                                                ? 'riwayatId'
                                                : 'id']))))),
                            ],
                            if (!widget.permit && widget.canChooseReporter) ...[
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Pelapor'),
                                  subtitle: Text(reporter == null
                                      ? 'Saya sendiri'
                                      : val(reporter!['nama'])),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => pickPeople(asReporter: true)),
                              if (reporter != null)
                                TextButton(
                                    onPressed: () =>
                                        setState(() => reporter = null),
                                    child: const Text(
                                        'Gunakan saya sebagai pelapor')),
                            ],
                            const SizedBox(height: 16),
                            ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: MarkazColors.outline)),
                                leading:
                                    const Icon(Icons.calendar_month_outlined),
                                title: Text(widget.permit
                                    ? 'Tanggal mulai'
                                    : 'Tanggal kejadian'),
                                subtitle: Text(date(start)),
                                trailing: const Icon(Icons.expand_more),
                                onTap: () => pickDate(false)),
                            if (widget.permit && type == 'BERHARI_HARI') ...[
                              const SizedBox(height: 12),
                              ListTile(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                          color: MarkazColors.outline)),
                                  title: const Text('Sampai tanggal'),
                                  subtitle: Text(end == null
                                      ? 'Pilih tanggal selesai'
                                      : date(end!)),
                                  trailing:
                                      const Icon(Icons.calendar_month_outlined),
                                  onTap: () => pickDate(true))
                            ],
                            if (!widget.permit) ...[
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Waktu kejadian'),
                                  subtitle: Text(time.format(context)),
                                  trailing: const Icon(Icons.schedule),
                                  onTap: () async {
                                    final selected = await showTimePicker(
                                        context: context, initialTime: time);
                                    if (selected != null && mounted)
                                      setState(() => time = selected);
                                  }),
                              TextFormField(
                                  controller: place,
                                  decoration: const InputDecoration(
                                      labelText: 'Tempat kejadian'),
                                  validator: requiredText),
                            ],
                            const SizedBox(height: 20),
                            TextFormField(
                                controller: reason,
                                minLines: 3,
                                maxLines: 6,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                    labelText: widget.permit
                                        ? 'Alasan izin'
                                        : 'Perkataan yang diucapkan',
                                    alignLabelWithHint: true),
                                validator: requiredText),
                            if (error != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(error!,
                                      style: const TextStyle(
                                          color: MarkazColors.danger))),
                            const SizedBox(height: 24),
                            FilledButton(
                                onPressed: busy ? null : submit,
                                child: Text(busy
                                    ? 'Mengirim…'
                                    : widget.permit
                                        ? 'Tinjau pengajuan'
                                        : 'Tinjau laporan')),
                            if (busy)
                              const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: LinearProgressIndicator()),
                          ]))))));

  String? requiredText(String? v) =>
      v == null || v.trim().isEmpty ? 'Bagian ini perlu diisi.' : null;
}

class PeoplePicker extends StatefulWidget {
  const PeoplePicker(
      {super.key,
      required this.search,
      required this.initial,
      required this.idKey,
      this.single = false});
  final Future<List<Json>> Function(String) search;
  final Map<String, Json> initial;
  final String idKey;
  final bool single;
  @override
  State<PeoplePicker> createState() => _PeoplePicker();
}

class _PeoplePicker extends State<PeoplePicker> {
  late final selected = Map<String, Json>.of(widget.initial);
  final query = TextEditingController();
  List<Json> options = [];
  bool loading = false;
  String? error;
  int request = 0;
  @override
  void initState() {
    super.initState();
    if (widget.idKey == 'riwayatId') search();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final current = ++request;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await widget.search(query.text.trim());
      if (mounted && current == request) setState(() => options = results);
    } catch (e) {
      if (mounted && current == request) setState(() => error = '$e');
    } finally {
      if (mounted && current == request) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(children: [
                Text(widget.single ? 'Pilih pelapor' : 'Pilih santri',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => search(),
                    decoration: InputDecoration(
                        labelText: 'Cari nama atau sakan',
                        suffixIcon: IconButton(
                            tooltip: 'Cari',
                            onPressed: search,
                            icon: const Icon(Icons.search)))),
                if (loading) const LinearProgressIndicator(),
                if (error != null)
                  TextButton(
                      onPressed: search, child: Text('$error · Coba lagi')),
                Expanded(
                    child: options.isEmpty
                        ? const Center(
                            child:
                                Text('Cari santri untuk menampilkan pilihan.'))
                        : ListView(children: [
                            for (final p in options)
                              CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(val(p['nama'])),
                                  subtitle: Text(val(p['sakan'] ??
                                      p['kelas'] ??
                                      p['kelasNama'])),
                                  value: selected
                                      .containsKey(val(p[widget.idKey])),
                                  onChanged: (v) => setState(() {
                                        final id = val(p[widget.idKey]);
                                        if (v == true) {
                                          if (widget.single) selected.clear();
                                          selected[id] = p;
                                        } else {
                                          selected.remove(id);
                                        }
                                      }))
                          ])),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.pop(context, selected),
                        child: Text('Gunakan ${selected.length} santri'))),
              ]))));
}
