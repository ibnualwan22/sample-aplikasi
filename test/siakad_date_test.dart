import 'package:flutter_test/flutter_test.dart';
import 'package:sample_aplikasi/siakad/display_date.dart';

void main() {
  test('Calendar dates use dd-MM-yyyy without timezone day shifts', () {
    expect(siakadDisplayDate('2004-03-09T00:00:00+07:00'), '09-03-2004');
    expect(siakadDisplayDate('2026-11-10'), '10-11-2026');
    expect(siakadDisplayDate('2024-02-29T00:00:00Z'), '29-02-2024');
    for (final value in [null, '', 'invalid', '2026-02-30', '2026-13-01']) {
      expect(siakadDisplayDate(value), '—');
    }
  });
}
