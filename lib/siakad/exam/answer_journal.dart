import 'dart:convert';
import 'dart:math';
import '../api.dart';

/// Durable, ordered snapshots. Acknowledgements never erase a newer revision.
class AnswerJournal {
  AnswerJournal({required this.key, required this.read, required this.write});
  final String key;
  final Future<String?> Function(String) read;
  final Future<void> Function(String, String) write;
  Json answers = {}, exam = {};
  String clientId = List.generate(24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
  int revision = 0, acknowledged = -1;
  String? reason;
  bool confirmed = false;
  bool needsReview = false;
  String? persistenceError;
  Future<void> _tail = Future.value();
  bool get sealed => reason != null;
  bool get pending => revision > acknowledged || (sealed && !confirmed);

  static String storageKey(String origin, String owner, String session) =>
      'siakad.exam.v2.${Uri.encodeComponent(origin)}.${Uri.encodeComponent(owner)}.${Uri.encodeComponent(session)}';
  Future<void> restore(Json initialAnswers, Json initialExam) async {
    final raw = await read(key);
    if (raw == null) {
      answers = obj(jsonDecode(jsonEncode(initialAnswers)));
      exam = initialExam;
      await persist();
      return;
    }
    final saved = obj(jsonDecode(raw));
    if (saved['schema'] != 2 || saved['answers'] is! Map) {
      throw const FormatException(
          'Draf lokal tidak dapat dibaca. Jangan hapus data aplikasi; hubungi pengawas.');
    }
    clientId = saved['clientId'] as String;
    answers = obj(saved['answers']);
    exam = obj(saved['exam']);
    revision = saved['revision'] as int;
    acknowledged = saved['acknowledged'] as int;
    reason = saved['reason'] as String?;
    confirmed = saved['confirmed'] == true;
    needsReview = saved['needsReview'] == true;
  }

  Future<void> edit(String question, Json change) {
    if (sealed) throw StateError('Jawaban sudah dikunci.');
    answers[question] = {...obj(answers[question]), ...change};
    revision++;
    return persist();
  }

  Future<void> seal(String why) {
    if (!sealed) {
      reason = why;
      revision++;
    }
    return persist();
  }

  Json snapshot() => obj(jsonDecode(jsonEncode({
        'clientId': clientId,
        'revision': revision,
        'answers': answers,
        'reason': reason,
      })));
  Future<void> acknowledge(int sentRevision,
      {required bool finalized, bool review = false}) async {
    if (sentRevision > revision)
      throw StateError('Konfirmasi revisi tidak valid.');
    if (sentRevision > acknowledged) acknowledged = sentRevision;
    if (finalized && sentRevision == revision && sealed) confirmed = true;
    needsReview = needsReview || review;
    await persist();
  }

  Future<void> persist() {
    final payload = jsonEncode({
      'schema': 2,
      'answers': answers,
      'exam': exam,
      'clientId': clientId,
      'revision': revision,
      'acknowledged': acknowledged,
      'reason': reason,
      'confirmed': confirmed,
      'needsReview': needsReview
    });
    final operation = _tail.catchError((_) {}).then((_) => write(key, payload));
    _tail = operation;
    // Attach a handler immediately; callers still receive the failure.
    return operation.then((_) {
      persistenceError = null;
    }, onError: (Object e) {
      persistenceError =
          'Penyimpanan perangkat gagal. Coba simpan lagi sebelum melanjutkan.';
      throw e;
    });
  }

  Future<void> get settled => _tail;
}
