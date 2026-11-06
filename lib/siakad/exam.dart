import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'api.dart';

class ExamPage extends StatefulWidget {
  const ExamPage(
      {super.key,
      required this.api,
      required this.data,
      required this.owner,
      required this.tauzi});
  final SantriApi api;
  final Json data;
  final bool tauzi;
  final String owner;
  @override
  State<ExamPage> createState() => _Exam();
}

class _Exam extends State<ExamPage> with WidgetsBindingObserver {
  List<Json> get qs => rows(widget.data[widget.tauzi ? 'soalList' : 'soal']);
  String id(Json q) => val(q[widget.tauzi ? 'id' : 'soalId']);
  String get session => val(widget.data[widget.tauzi ? 'attemptId' : 'sesiId']);
  String get cache => 'siakad.exam.${widget.owner}.$session';
  final Json changes = {}, answers = {};
  int index = 0, remaining = 0;
  bool ready = false,
      sending = false,
      done = false,
      submitting = false,
      checking = false;
  DateTime? deadline, hidden;
  String? problem;
  Timer? tick, delay;
  Future<void> disk = Future.value();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  Future<void> init() async {
    try {
      final d = widget.data;
      for (final q in qs) {
        answers[id(q)] = widget.tauzi
            ? obj(obj(d['savedResponses'])[id(q)])
            : {
                'opsiId': q['opsiTerpilih'],
                'rpiId': q['rpiId'],
                'jawabanTeks': q['jawabanTeks'],
                'jawabanData': q['jawabanData'] is String
                    ? jsonDecode(q['jawabanData'])
                    : q['jawabanData']
              };
      }
      final raw = await widget.api.vault.read(key: cache);
      if (raw != null) {
        changes.addAll(obj(jsonDecode(raw)));
        answers.addAll(changes);
      }
      if (!mounted) return;
      remaining = (d['sisaWaktuDetik'] as num?)?.toInt() ?? 0;
      deadline = DateTime.now().add(Duration(seconds: remaining));
      setState(() => ready = true);
      tick = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || done) return;
        if (!widget.tauzi) {
          setState(() => remaining =
              (deadline!.difference(DateTime.now()).inMilliseconds / 1000)
                  .ceil()
                  .clamp(0, 1 << 30));
          if (remaining == 0) {
            finish('TIME_UP');
            return;
          }
          if (t.tick % 15 == 0) syncTime();
        }
        if (t.tick % 5 == 0 && changes.isNotEmpty) flush();
      });
      await flush();
    } catch (e) {
      if (mounted) setState(() => problem = e.toString());
    }
  }

  Future<void> syncTime() async {
    if (checking || submitting || !mounted) return;
    checking = true;
    try {
      final d = await widget.api.call(
          '/api/santri/ujian/status?sesiId=$session&unsaved=${changes.length}');
      if (!mounted) return;
      if (d['status'] != 'MENGERJAKAN') {
        done = true;
        await disk;
        await widget.api.vault.delete(key: cache);
        if (mounted) Navigator.pop(context);
        return;
      }
      if (d['sisaWaktuDetik'] is int)
        deadline = DateTime.now().add(Duration(seconds: d['sisaWaktuDetik']));
    } catch (e) {
      if (mounted) setState(() => problem = e.toString());
    } finally {
      checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ready || done || widget.tauzi) return;
    if (state == AppLifecycleState.paused) {
      hidden = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (hidden != null && DateTime.now().difference(hidden!).inSeconds >= 5) {
        finish('TAB_CLOSE');
      } else {
        syncTime();
      }
      hidden = null;
    }
  }

  void persist() {
    final snapshot = jsonEncode(changes);
    disk = disk
        .catchError((_) {})
        .then((_) => widget.api.vault.write(key: cache, value: snapshot));
  }

  void edit(Json q, Json diff) {
    if (!ready || submitting || done) return;
    final k = id(q);
    setState(() {
      answers[k] = {...obj(answers[k]), ...diff};
      changes[k] = answers[k];
      problem = null;
    });
    persist();
    delay?.cancel();
    delay = Timer(const Duration(milliseconds: 550), flush);
  }

  Future<bool> flush() async {
    if (sending || done) return false;
    sending = true;
    try {
      await disk;
      while (changes.isNotEmpty && mounted) {
        final k = changes.keys.first;
        final v = changes[k];
        await widget.api.call(
            widget.tauzi ? '/api/tauzi/autosave' : '/api/santri/ujian/jawab',
            method: 'POST',
            body: widget.tauzi
                ? {
                    'jawaban': {k: v}
                  }
                : {'sesiId': session, 'soalId': k, ...obj(v)});
        if (identical(v, changes[k])) changes.remove(k);
        persist();
        await disk;
      }
      if (mounted) setState(() => problem = null);
      return changes.isEmpty;
    } catch (e) {
      if (mounted) setState(() => problem = e.toString());
      return false;
    } finally {
      sending = false;
    }
  }

  Future<void> finish(String reason) async {
    if (done || submitting || !ready) return;
    if (sending) {
      delay?.cancel();
      delay = Timer(const Duration(milliseconds: 300), () {
        if (mounted) finish(reason);
      });
      return;
    }
    setState(() => submitting = true);
    try {
      if (!await flush()) return;
      if (!mounted) return;
      await widget.api.call(
          widget.tauzi ? '/api/tauzi/submit' : '/api/santri/ujian/submit',
          method: 'POST',
          body: widget.tauzi
              ? {'jawaban': answers}
              : {'sesiId': session, 'reason': reason});
      done = true;
      await disk;
      await widget.api.vault.delete(key: cache);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => problem = e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> confirm() async {
    if (widget.tauzi &&
        qs.any((q) =>
            obj(answers[id(q)])['jawabanId'] == null ||
            obj(answers[id(q)])['ragu'] == true)) {
      setState(() => problem =
          'Lengkapi jawaban dan hapus tanda ragu-ragu sebelum mengirim.');
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Kirim ujian?'),
                content: Text(
                    'Periksa jawaban untuk ${qs.length} soal. Setelah dikirim, jawaban tidak dapat diubah.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Periksa lagi')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Kirim ujian'))
                ]));
    if (ok == true) await finish('MANUAL');
  }

  @override
  void dispose() {
    tick?.cancel();
    delay?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget rich(dynamic v) => Html(data: v?.toString() ?? '');
  List<Widget> controls(Json q) {
    final a = obj(answers[id(q)]),
        dt = obj(q['dataTambahan']),
        j = obj(a['jawabanData']);
    final type = val(q['tipeSoal']);
    void save(Json v) => edit(q, {
          'jawabanData': {...j, ...v}
        });
    final opts = rows(q[widget.tauzi ? 'jawabanList' : 'opsiList']);
    Widget input(String label, String initial, void Function(String) fn) =>
        TextFormField(
            key: ValueKey('${id(q)}:$label'),
            initialValue: initial,
            enableInteractiveSelection: false,
            decoration: InputDecoration(labelText: label),
            minLines: 1,
            maxLines: 5,
            onChanged: fn);
    Widget pick(dynamic label, dynamic current, List opts,
            void Function(dynamic) fn) =>
        DropdownButtonFormField<dynamic>(
            key: ValueKey('${id(q)}:$label'),
            isExpanded: true,
            decoration: InputDecoration(labelText: val(label)),
            initialValue: opts.contains(current) ? current : null,
            items: [
              for (final o in opts.toSet())
                DropdownMenuItem(value: o, child: Text(val(o)))
            ],
            onChanged: fn);
    if (opts.isNotEmpty)
      return [
        for (final o in opts)
          CheckboxListTile(
              value: type == 'PG_MULTI'
                  ? (j['selectedIds'] ?? []).contains(o['id'])
                  : a[widget.tauzi ? 'jawabanId' : 'opsiId'] == o['id'],
              title: rich(o['teks']),
              subtitle: o['gambarUrl'] == null
                  ? null
                  : Image.network(
                      widget.api.origin.resolve(o['gambarUrl']).toString()),
              onChanged: (on) {
                if (type == 'PG_MULTI') {
                  final ids = Set.of(j['selectedIds'] as List? ?? []);
                  on == true ? ids.add(o['id']) : ids.remove(o['id']);
                  save({'selectedIds': ids.toList()});
                } else {
                  edit(q, {widget.tauzi ? 'jawabanId' : 'opsiId': o['id']});
                }
              })
      ];
    if (type == 'MENJODOHKAN' || type == 'DRAG_KATEGORI') {
      final match = type == 'MENJODOHKAN',
          k = match ? 'pairs' : 'items',
          l = match ? 'left' : 'text',
          r = match ? 'right' : 'category';
      final entries = rows(j[k]);
      return [
        for (final item in (match
                ? dt['lefts']
                : rows(dt['items']).map((i) => i['text'])) ??
            [])
          pick(
              item,
              entries.where((e) => e[l] == item).firstOrNull?[r],
              List.of(dt[match ? 'rights' : 'categories'] ?? []),
              (v) => save({
                    k: [
                      ...entries.where((e) => e[l] != item),
                      {l: item, r: v}
                    ]
                  }))
      ];
    }
    if (type == 'MENGURUTKAN' || type == 'SUSUN_HURUF') {
      final letters = type == 'SUSUN_HURUF';
      final original = List.of(dt[letters ? 'hurufAcak' : 'items'] ?? []);
      final k = letters ? 'susunanIndices' : 'items';
      final order = List.of(j[k] ??
          (letters ? List.generate(original.length, (i) => i) : original));
      return [
        for (var i = 0; i < order.length; i++)
          ListTile(
              leading: Text('${i + 1}'),
              title: Text(val(letters ? original[order[i]] : order[i])),
              trailing: Wrap(children: [
                for (final delta in [-1, 1])
                  IconButton(
                      icon: Icon(delta < 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                      onPressed: i + delta < 0 || i + delta >= order.length
                          ? null
                          : () {
                              final v = order.removeAt(i);
                              order.insert(i + delta, v);
                              save({k: order});
                            })
              ])),
        TextButton(
            onPressed: () => save({k: order}),
            child: const Text('Simpan urutan'))
      ];
    }
    if (type == 'DRAG_TO_BLANK' || type == 'PARAGRAF_RUMPANG') {
      final a = obj(j['answers']);
      return [
        rich(dt['paragraf']),
        for (final b in rows(dt['blanks']))
          if (type == 'DRAG_TO_BLANK')
            pick(
                'Isian ${b['index']}',
                a['${b['index']}'],
                List.of(dt['wordBank'] ?? []),
                (v) => save({
                      'answers': {...a, '${b['index']}': v}
                    }))
          else
            input(
                'Isian ${b['index']}',
                a['${b['index']}'] ?? '',
                (v) => save({
                      'answers': {...a, '${b['index']}': v}
                    }))
      ];
    }
    if (type == 'TABEL_TASRIF') {
      final cells = obj(j['cells']);
      return [
        for (final (i, r) in rows(dt['rows']).indexed) ...[
          rich(r['label']),
          for (final (k, c) in rows(r['cells']).indexed)
            if (c['isBlank'] == true)
              input(
                  '${r['label']} · ${(dt['headers'] as List?)?.elementAtOrNull(k) ?? k + 1}',
                  cells['$i-$k'] ?? '',
                  (v) => save({
                        'cells': {...cells, '$i-$k': v}
                      }))
            else
              rich(c['value'])
        ]
      ];
    }
    if (type == 'IDENTIFIKASI_KESALAHAN') {
      final words = (dt['words'] as List?) ??
          rows(dt['segments']).map((s) => s['text']).toList();
      final multi = dt['words'] == null;
      final indices = List.of(j['selectedIndices'] ?? []);
      return [
        for (final (i, w) in words.indexed)
          CheckboxListTile(
              title: Text(val(w)),
              value: multi ? indices.contains(i) : j['selectedIndex'] == i,
              onChanged: (v) {
                if (multi) {
                  v == true ? indices.add(i) : indices.remove(i);
                  save({'selectedIndices': indices});
                } else {
                  save({'selectedIndex': i});
                }
              })
      ];
    }
    if (type == 'STABILO_SYNTAX') {
      final assigns = obj(j['assignments']);
      return [
        for (final (i, w) in List.of(dt['words'] ?? []).indexed)
          pick(
              '${w is Map ? w['text'] : w} (${i + 1})',
              assigns['$i'],
              [
                for (final cat in dt['categories'] ?? [])
                  cat is Map ? cat['name'] : cat
              ],
              (v) => save({
                    'assignments': {...assigns, '$i': v}
                  }))
      ];
    }
    if (type == 'JARING_RELASI') {
      final conn = rows(j['connections']);
      return [
        for (final (i, w) in List.of(dt['leftItems'] ?? []).indexed)
          ExpansionTile(title: Text(val(w)), children: [
            for (final (k, v) in List.of(dt['rightItems'] ?? []).indexed)
              Builder(builder: (_) {
                final sel = List.of(
                    conn.where((c) => c['left'] == i).firstOrNull?['right'] ??
                        []);
                return CheckboxListTile(
                    title: Text(val(v)),
                    value: sel.contains(k),
                    onChanged: (b) {
                      b == true ? sel.add(k) : sel.remove(k);
                      save({
                        'connections': [
                          ...conn.where((c) => c['left'] != i),
                          {'left': i, 'right': sel}
                        ]
                      });
                    });
              })
          ])
      ];
    }
    return [
      if (dt['huruf'] is List) rich((dt['huruf'] as List).join(' · ')),
      input('Jawaban Anda', a['jawabanTeks'] ?? '',
          (v) => edit(q, {'jawabanTeks': v}))
    ];
  }

  @override
  Widget build(BuildContext context) {
    final q = qs.elementAtOrNull(index);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.tauzi ? 'Tauzi’ Fushul' : 'Ujian akademik'),
            actions: [
              if (!widget.tauzi)
                Center(
                    child: Text(
                        '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}  '))
            ]),
        body: !ready || q == null
            ? Center(
                child: Text(problem ??
                    (q == null ? 'Belum ada soal.' : 'Memuat jawaban…')))
            : ListView(padding: const EdgeInsets.all(16), children: [
                Text('Soal ${index + 1} dari ${qs.length}'),
                if (q['perintah'] != null) rich(q['perintah']),
                rich(q['pertanyaan']),
                if (q['gambarUrl'] != null)
                  Image.network(
                      widget.api.origin.resolve(q['gambarUrl']).toString()),
                AbsorbPointer(
                    absorbing: submitting,
                    child: Column(children: controls(q))),
                CheckboxListTile(
                    title: const Text('Ragu-ragu'),
                    value: widget.tauzi
                        ? answers[id(q)]['ragu'] == true
                        : answers[id(q)]['rpiId'] != null,
                    onChanged: (v) => edit(
                        q,
                        widget.tauzi
                            ? {'ragu': v}
                            : {'rpiId': v == true ? 'RAGU' : null})),
                Text(problem ??
                    (changes.isEmpty ? 'Tersimpan' : 'Menunggu penyimpanan')),
                if (problem != null)
                  TextButton(
                      onPressed: flush, child: const Text('Coba simpan lagi')),
                Wrap(alignment: WrapAlignment.spaceBetween, children: [
                  TextButton(
                      onPressed:
                          index == 0 ? null : () => setState(() => index--),
                      child: const Text('Sebelumnya')),
                  FilledButton(
                      onPressed: submitting
                          ? null
                          : index < qs.length - 1
                              ? () => setState(() => index++)
                              : confirm,
                      child: Text(index < qs.length - 1
                          ? 'Selanjutnya'
                          : 'Selesaikan ujian'))
                ])
              ]));
  }
}
