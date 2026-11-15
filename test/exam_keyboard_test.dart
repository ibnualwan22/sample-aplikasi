import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/siakad/exam/keyboard.dart';

void main() {
  test('Arabic layout and variants match SIAKAD', () {
    expect(arabicRows.map((r) => r.length), [11, 11, 10]);
    expect(arabicRows[2], ['ذ', 'ء', 'ؤ', 'ر', 'ى', 'ة', 'و', 'ز', 'ظ', 'د']);
    expect(keyVariants['ل'], ['ل', 'لا', 'لأ', 'لإ', 'لآ']);
  });
  test('Harakat removed before base letter, Unicode replacement and cursor',
      () {
    var v = const TextEditingValue(
        text: 'بَ', selection: TextSelection.collapsed(offset: 2));
    expect(deleteExamText(v).text, 'ب');
    v = const TextEditingValue(
        text: 'ا😀ب', selection: TextSelection.collapsed(offset: 3));
    expect(deleteExamText(v).text, 'اب');
    v = const TextEditingValue(
        text: 'abc', selection: TextSelection(baseOffset: 0, extentOffset: 2));
    expect(insertExamText(v, 'لا').text, 'لاc');
  });
}
