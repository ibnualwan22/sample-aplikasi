import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/siakad/exam/answer_journal.dart';

void main() {
  test('write-ahead journal survives restart and late acknowledgements',
      () async {
    final disk = <String, String>{};
    AnswerJournal make() => AnswerJournal(
        key: 'exam',
        read: (k) async => disk[k],
        write: (k, v) async {
          disk[k] = v;
        });
    final j = make();
    await j.restore({}, {'sesiId': 'one'});
    await j.edit('q', {'jawabanTeks': 'أ'});
    final sent = j.snapshot();
    await j.edit('q', {'jawabanTeks': 'أَ'});
    await j.acknowledge(sent['revision'], finalized: false);
    expect(j.pending, isTrue);
    final restored = make();
    await restored.restore({}, {});
    expect(restored.answers['q']['jawabanTeks'], 'أَ');
    expect(restored.clientId, j.clientId);
    await restored.seal('TIME_UP');
    expect(
        () => restored.edit('q', {'jawabanTeks': 'changed'}), throwsStateError);
    final sealed = make();
    await sealed.restore({}, {});
    expect(sealed.sealed, isTrue);
    expect(sealed.pending, isTrue);
    await sealed.acknowledge(sealed.revision, finalized: true, review: true);
    expect(sealed.pending, isFalse);
    expect(sealed.needsReview, isTrue);
    expect(jsonDecode(disk['exam']!)['answers']['q']['jawabanTeks'], 'أَ');
  });
  test(
      'rapid edits persist in order; failed disk write is visible and retryable',
      () async {
    String? data;
    var fail = false;
    final j = AnswerJournal(
        key: 'x',
        read: (_) async => data,
        write: (_, v) async {
          if (fail) throw StateError('disk full');
          data = v;
        });
    await j.restore({}, {});
    await Future.wait([
      j.edit('q', {'jawabanTeks': 'ا'}),
      j.edit('q', {'jawabanTeks': 'اب'}),
      j.edit('q', {'jawabanTeks': 'ابت'})
    ]);
    expect(jsonDecode(data!)['answers']['q']['jawabanTeks'], 'ابت');
    fail = true;
    await expectLater(j.edit('q', {'jawabanTeks': ''}), throwsStateError);
    expect(j.persistenceError, isNotNull);
    fail = false;
    await j.persist();
    expect(j.persistenceError, isNull);
    expect(jsonDecode(data!)['answers']['q']['jawabanTeks'], '');
  });
  test('owner/origin scope and corrupt draft protection', () async {
    expect(AnswerJournal.storageKey('https://a', '1', 'x'),
        isNot(AnswerJournal.storageKey('https://b', '1', 'x')));
    final j = AnswerJournal(
        key: 'x',
        read: (_) async => 'bad-json',
        write: (_, __) async => fail('must not overwrite'));
    await expectLater(j.restore({}, {}), throwsFormatException);
  });
}
