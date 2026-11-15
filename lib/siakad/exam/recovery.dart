import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../exam.dart';
import 'answer_journal.dart';

class ExamRecovery extends StatefulWidget {
  const ExamRecovery({super.key, required this.api, required this.owner});
  final SantriApi api;
  final String owner;
  @override
  State<ExamRecovery> createState() => _Recovery();
}

class _Recovery extends State<ExamRecovery> {
  late Future<List<Json>> pending = load();
  Timer? retry;
  bool syncing = false;
  @override
  void initState() {
    super.initState();
    retry = Timer.periodic(const Duration(seconds: 15), (_) => syncPending());
    WidgetsBinding.instance.addPostFrameCallback((_) => syncPending());
  }

  @override
  void dispose() {
    retry?.cancel();
    super.dispose();
  }

  Future<void> syncPending() async {
    if (syncing || !mounted || ModalRoute.of(context)?.isCurrent != true)
      return;
    setState(() => syncing = true);
    try {
      final drafts = await load();
      for (final saved in drafts) {
        // Only sealed attempts: an active exam is owned by ExamPage.
        if (saved['reason'] == null || obj(saved['exam'])['tauzi'] == true)
          continue;
        final exam = obj(saved['exam']);
        final journal = AnswerJournal(
            key: AnswerJournal.storageKey(widget.api.origin.toString(),
                widget.owner, val(exam['sesiId'])),
            read: (k) => widget.api.vault.read(key: k),
            write: (k, v) => widget.api.vault.write(key: k, value: v));
        await journal.restore({}, exam);
        final snapshot = journal.snapshot();
        final response = await widget.api.call('/api/santri/ujian/mobile-sync',
            method: 'POST', body: {'sesiId': exam['sesiId'], ...snapshot});
        if (response['success'] == true &&
            response['revision'] == snapshot['revision']) {
          await journal.acknowledge(snapshot['revision'],
              finalized: response['finalized'] == true,
              review: response['needsReview'] == true);
        }
      }
    } catch (_) {
      /* Durable draft remains; retry while this menu is open. */
    } finally {
      syncing = false;
      if (mounted) setState(() => pending = load());
    }
  }

  Future<List<Json>> load() async {
    final prefix = AnswerJournal.storageKey(
        widget.api.origin.toString(), widget.owner, '');
    final stored = await widget.api.vault.readAll();
    final result = <Json>[];
    for (final entry in stored.entries.where((e) => e.key.startsWith(prefix))) {
      try {
        final d = obj(jsonDecode(entry.value));
        if (d['schema'] == 2 && d['confirmed'] != true) result.add(d);
      } catch (_) {/* Never delete an unreadable journal. */}
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Json>>(
      future: pending,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Text(
              'Draf lokal belum dapat dibaca. Coba buka kembali daftar ujian.');
        return Column(children: [
          for (final d in snapshot.data ?? <Json>[])
            Card(
                child: ListTile(
              enabled: !syncing,
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(d['reason'] != null
                  ? 'Jawaban menunggu sinkronisasi'
                  : 'Lanjutkan draf ujian di perangkat'),
              subtitle: Text(
                  'Sesi ${val(obj(d['exam'])['sesiId'] ?? obj(d['exam'])['attemptId'])}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                if (syncing) return;
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ExamPage(
                            api: widget.api,
                            data: obj(d['exam']),
                            owner: widget.owner,
                            tauzi: obj(d['exam'])['tauzi'] == true)));
                if (mounted) setState(() => pending = load());
              },
            ))
        ]);
      });
}
