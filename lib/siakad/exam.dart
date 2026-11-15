import '../widgets/markaz_components.dart';
import '../theme/markaz_theme.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'api.dart';
import 'exam/answer_journal.dart';
import 'exam/keyboard.dart';
import 'exam/guard.dart';
part 'exam/question_controls.dart';

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
  final keyboard = ExamKeyboardController();
  late final journal = AnswerJournal(
      key: AnswerJournal.storageKey(
          widget.api.origin.toString(), widget.owner, session),
      read: (k) => widget.api.vault.read(key: k),
      write: (k, v) => widget.api.vault.write(key: k, value: v));
  List<Json> get qs => rows(
      (ready ? journal.exam : widget.data)[widget.tauzi ? 'soalList' : 'soal']);
  String id(Json q) => val(q[widget.tauzi ? 'id' : 'soalId']);
  String get session => val(widget.data[widget.tauzi ? 'attemptId' : 'sesiId']);
  Json get answers => journal.answers;
  int index = 0, remaining = 0, failures = 0;
  bool ready = false,
      sending = false,
      locked = false,
      initializing = true,
      checking = false,
      leaving = false;
  int localWrites = 0;
  bool get localSaving => localWrites > 0;
  bool get editable =>
      ready &&
      !journal.sealed &&
      journal.persistenceError == null &&
      (widget.tauzi || locked);
  String? problem;
  DateTime? deadline, hidden, retryAt;
  Timer? tick, debounce, absence;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> init() async {
    try {
      final initial = <String, dynamic>{
        for (final q in qs)
          id(q): widget.tauzi
              ? obj(obj(widget.data['savedResponses'])[id(q)])
              : {
                  'opsiId': q['opsiTerpilih'],
                  'rpiId': q['rpiId'],
                  'jawabanTeks': q['jawabanTeks'],
                  'jawabanData': q['jawabanData'] is String
                      ? jsonDecode(q['jawabanData'])
                      : q['jawabanData']
                }
      };
      final data = {
        ...widget.data,
        'localDeadline': widget.data['localDeadline'] ??
            DateTime.now()
                .add(Duration(
                    seconds:
                        (widget.data['sisaWaktuDetik'] as num?)?.toInt() ?? 0))
                .toIso8601String(),
        'tauzi': widget.tauzi
      };
      await journal.restore(initial, data);
      // Migrate old unsent drafts without deleting the original copy.
      if (journal.revision == 0 && !journal.sealed) {
        final legacy = await widget.api.vault
            .read(key: 'siakad.exam.${widget.owner}.$session');
        if (legacy != null)
          for (final entry in obj(jsonDecode(legacy)).entries) {
            await journal.edit(entry.key, obj(entry.value));
          }
      }
      deadline = DateTime.parse(journal.exam['localDeadline']);
      if (!widget.tauzi && !journal.sealed && journal.exam['running'] == true) {
        await journal.seal('LOCK_LOST');
      }
      if (!widget.tauzi && !journal.sealed && DateTime.now().isAfter(deadline!))
        await journal.seal('TIME_UP');
      if (!widget.tauzi && !journal.sealed) {
        await ExamGuard.begin();
        locked = true;
        journal.exam['running'] = true;
        await journal.persist();
      }
      if (!widget.tauzi && journal.sealed) {
        try {
          locked = await ExamGuard.active();
          await release();
        } on MissingPluginException {
          locked = false;
        }
      }
      if (!mounted) {
        if (locked) await ExamGuard.end();
        return;
      }
      ready = true;
      initializing = false;
      refresh();
      ExamGuard.channel.setMethodCallHandler((call) async {
        if (call.method == 'interrupted') await finish('LOCK_LOST');
      });
      tick = Timer.periodic(const Duration(seconds: 1), (_) => pulse());
      pulse();
      await flush();
    } catch (e) {
      problem = message(e);
      initializing = false;
      refresh();
    }
  }

  String message(Object e) => e is PlatformException
      ? (e.message ?? 'Mode ujian tidak tersedia.')
      : e.toString();
  void pulse() {
    if (!mounted || !ready) return;
    if (!widget.tauzi && !journal.sealed) {
      remaining =
          deadline!.difference(DateTime.now()).inSeconds.clamp(0, 1 << 30);
      if (remaining == 0) {
        finish('TIME_UP');
        return;
      }
      if (remaining % 15 == 0) syncTime();
    }
    if (journal.pending &&
        !sending &&
        (retryAt == null || DateTime.now().isAfter(retryAt!))) flush();
    refresh();
  }

  Future<void> syncTime() async {
    if (checking || journal.sealed) return;
    checking = true;
    try {
      if (!await ExamGuard.active()) {
        await finish('LOCK_LOST');
        return;
      }
      final d = await widget.api.call(
          '/api/santri/ujian/status?sesiId=${Uri.encodeComponent(session)}&unsaved=${journal.pending ? 1 : 0}');
      if (d['status'] != 'MENGERJAKAN') {
        await finish('SERVER_CLOSED');
        return;
      }
      if (d['sisaWaktuDetik'] is num) {
        deadline = DateTime.now()
            .add(Duration(seconds: (d['sisaWaktuDetik'] as num).toInt()));
        journal.exam['localDeadline'] = deadline!.toIso8601String();
        await journal.persist();
      }
      if (!await ExamGuard.active()) await finish('LOCK_LOST');
    } catch (e) {
      problem = message(e);
    } finally {
      checking = false;
      refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ready || widget.tauzi || journal.sealed) return;
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      hidden ??= DateTime.now();
      absence ??= Timer(const Duration(seconds: 5), () => finish('TAB_CLOSE'));
    }
    if (state == AppLifecycleState.resumed) {
      absence?.cancel();
      absence = null;
      if (hidden != null &&
          DateTime.now().difference(hidden!) >= const Duration(seconds: 5))
        finish('TAB_CLOSE');
      else
        syncTime();
      hidden = null;
    }
  }

  Future<void> edit(Json q, Json diff) async {
    if (!editable) return;
    localWrites++;
    problem = null;
    refresh();
    try {
      await journal.edit(id(q), diff);
    } catch (e) {
      problem = journal.persistenceError ?? message(e);
    } finally {
      localWrites--;
      refresh();
    }
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 550), flush);
  }

  Future<void> retryLocal() async {
    try {
      await journal.persist();
      problem = null;
      if (journal.sealed) await release();
      await flush();
    } catch (e) {
      problem = message(e);
    }
    refresh();
  }

  Future<void> flush() async {
    if (sending ||
        !ready ||
        journal.persistenceError != null ||
        !journal.pending) return;
    sending = true;
    refresh();
    try {
      await journal.settled;
      final snapshot = journal.snapshot();
      await journal
          .settled; // Commit every edit included in this snapshot before network I/O.
      final rev = snapshot['revision'] as int;
      if (widget.tauzi) {
        await widget.api.call('/api/tauzi/autosave',
            method: 'POST', body: {'jawaban': snapshot['answers']});
        if (journal.sealed)
          await widget.api.call('/api/tauzi/submit',
              method: 'POST', body: {'jawaban': snapshot['answers']});
        await journal.acknowledge(rev, finalized: journal.sealed);
      } else {
        final response = await widget.api.call('/api/santri/ujian/mobile-sync',
            method: 'POST', body: {'sesiId': session, ...snapshot});
        if (response['success'] != true || response['revision'] != rev)
          throw const PortalError(
              'Server belum mengonfirmasi revisi jawaban ini. Draf tetap disimpan.');
        await journal.acknowledge(rev,
            finalized: response['finalized'] == true,
            review: response['needsReview'] == true);
        if (response['expired'] == true && !journal.sealed)
          await finish('TIME_UP');
      }
      failures = 0;
      retryAt = DateTime.now().add(const Duration(seconds: 2));
      problem = null;
    } catch (e) {
      failures = (failures + 1).clamp(1, 5);
      retryAt = DateTime.now().add(Duration(seconds: 1 << failures));
      problem = message(e);
    } finally {
      sending = false;
      refresh();
    }
  }

  Future<void> release() async {
    if (widget.tauzi || !locked) return;
    await ExamGuard.end();
    locked = false;
  }

  Future<void> finish(String reason) async {
    if (!ready) return;
    keyboard.close();
    absence?.cancel();
    absence = null;
    // seal() changes the in-memory state synchronously, before any network wait.
    try {
      await journal.seal(reason);
      await release();
      await flush();
    } catch (e) {
      problem = journal.persistenceError ?? message(e);
    }
    refresh();
  }

  Future<void> confirm() async {
    keyboard.close();
    if (widget.tauzi &&
        qs.any((q) =>
            obj(answers[id(q)])['jawabanId'] == null ||
            obj(answers[id(q)])['ragu'] == true)) {
      problem = 'Lengkapi jawaban dan hapus tanda ragu-ragu sebelum mengirim.';
      refresh();
      return;
    }
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                scrollable: true,
                title: const MarkazDialogTitle('Selesaikan ujian?',
                    icon: Icons.task_alt_outlined),
                content: const Text(
                    'Jawaban akan dikunci. Jika jaringan terputus, jawaban tetap disimpan di perangkat dan pengiriman dilanjutkan saat tersambung.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Periksa lagi')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Selesaikan'))
                ]));
    if (yes == true) await finish('MANUAL');
  }

  Future<void> leave() async {
    try {
      if (ready) await journal.persist();
      await release();
      if (mounted) {
        setState(() => leaving = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      problem = message(e);
      refresh();
    }
  }

  @override
  void dispose() {
    tick?.cancel();
    debounce?.cancel();
    absence?.cancel();
    keyboard.dispose();
    ExamGuard.channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    if (locked) ExamGuard.end().catchError((_) {});
    super.dispose();
  }

  String get saveLabel => journal.persistenceError != null
      ? 'Belum tersimpan di perangkat'
      : localSaving
          ? 'Menyimpan di perangkat…'
          : sending
              ? 'Mengirim jawaban…'
              : journal.pending
                  ? 'Tersimpan di perangkat · menunggu sinkronisasi'
                  : 'Tersimpan di server';
  @override
  Widget build(BuildContext context) {
    final q = qs.elementAtOrNull(index);
    return PopScope(
        canPop: leaving || (!initializing && !ready),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            if (ready && journal.sealed)
              leave();
            else if (ready) confirm();
          }
        },
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(widget.tauzi ? 'Tauzi’ Fushul' : 'Ujian Usbu’'),
                actions: [
                  if (ready && !widget.tauzi && !journal.sealed)
                    Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                            child: Text(
                                '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontFeatures: [
                                  FontFeature.tabularFigures()
                                ]))))
                ]),
            bottomNavigationBar: ready && !journal.sealed
                ? ExamKeyboard(controller: keyboard)
                : null,
            body: !ready
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          if (initializing) const CircularProgressIndicator(),
                          Text(problem ??
                              'Menyiapkan penyimpanan dan mode ujian…'),
                          if (!initializing)
                            TextButton(
                                onPressed: leave, child: const Text('Kembali'))
                        ])))
                : journal.sealed
                    ? ListView(padding: const EdgeInsets.all(24), children: [
                        const Icon(Icons.task_alt_outlined, size: 48),
                        const SizedBox(height: 16),
                        Text(
                            journal.confirmed
                                ? 'Jawaban diterima server'
                                : 'Pengerjaan selesai',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        Text(journal.needsReview
                            ? 'Jawaban tersimpan di server dan memerlukan pemeriksaan pengawas karena diterima setelah batas waktu atau sesi ditutup.'
                            : 'Jawaban dikunci dan tidak dapat diubah lagi.'),
                        const SizedBox(height: 16),
                        Text(saveLabel),
                        if (problem != null) Text(problem!),
                        if (!journal.confirmed)
                          FilledButton(
                              onPressed: sending ? null : retryLocal,
                              child: const Text('Coba kirim lagi')),
                        OutlinedButton(
                            onPressed: leave,
                            child: const Text('Kembali ke daftar ujian')),
                      ])
                    : q == null
                        ? const Center(child: Text('Belum ada soal.'))
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                                Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                          'Soal ${index + 1} dari ${qs.length}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      TextButton.icon(
                                          onPressed: () => showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              useSafeArea: true,
                                              builder: (c) =>
                                                  SingleChildScrollView(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      child: Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: [
                                                            for (var i = 0;
                                                                i < qs.length;
                                                                i++)
                                                              OutlinedButton(
                                                                  onPressed:
                                                                      () {
                                                                    keyboard
                                                                        .close();
                                                                    setState(() =>
                                                                        index =
                                                                            i);
                                                                    Navigator
                                                                        .pop(c);
                                                                  },
                                                                  child: Text(
                                                                      '${i + 1}'))
                                                          ]))),
                                          icon: const Icon(
                                              Icons.grid_view_outlined),
                                          label: const Text('Daftar soal'))
                                    ]),
                                Text(saveLabel,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: MarkazColors.muted)),
                                if (problem != null)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Text(problem!,
                                          style: const TextStyle(
                                              color: MarkazColors.danger))),
                                if (journal.persistenceError != null)
                                  FilledButton(
                                      onPressed: retryLocal,
                                      child:
                                          const Text('Coba simpan lokal lagi')),
                                const SizedBox(height: 16),
                                if (q['namaMapel'] != null)
                                  Text(val(q['namaMapel']),
                                      textDirection: TextDirection.rtl),
                                if (q['grupSoalId'] != null)
                                  for (final parent in qs
                                      .where((p) => id(p) == q['grupSoalId']))
                                    Card(
                                        child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: rich(parent['pertanyaan']))),
                                if (q['perintah'] != null) rich(q['perintah']),
                                rich(q['pertanyaan']),
                                if (q['gambarUrl'] != null)
                                  InteractiveViewer(
                                      child: Image.network(
                                          widget.api.origin
                                              .resolve(q['gambarUrl'])
                                              .toString(),
                                          errorBuilder: (_, __, ___) => const Text(
                                              'Gambar belum termuat. Periksa koneksi.'))),
                                const SizedBox(height: 12),
                                AbsorbPointer(
                                    absorbing: !editable,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: controls(q))),
                                CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Ragu-ragu'),
                                    value: widget.tauzi
                                        ? obj(answers[id(q)])['ragu'] == true
                                        : obj(answers[id(q)])['rpiId'] != null,
                                    onChanged: editable
                                        ? (v) => edit(
                                            q,
                                            widget.tauzi
                                                ? {'ragu': v}
                                                : {
                                                    'rpiId': v == true
                                                        ? 'RAGU'
                                                        : null
                                                  })
                                        : null),
                                Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                          onPressed: index == 0
                                              ? null
                                              : () {
                                                  keyboard.close();
                                                  setState(() => index--);
                                                },
                                          child: const Text('Sebelumnya')),
                                      FilledButton(
                                          onPressed: localSaving
                                              ? null
                                              : () {
                                                  keyboard.close();
                                                  if (index < qs.length - 1)
                                                    setState(() => index++);
                                                  else
                                                    confirm();
                                                },
                                          child: Text(index < qs.length - 1
                                              ? 'Selanjutnya'
                                              : 'Selesaikan ujian'))
                                    ]),
                              ])));
  }
}
