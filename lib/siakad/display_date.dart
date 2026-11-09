/// Display calendar dates without moving a date of birth across time zones.
/// Transport values sent to the API remain unchanged.
String siakadDisplayDate(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|[T ])').firstMatch(raw);
  if (match == null) return '—';
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return '—';
  return '${match[3]}-${match[2]}-${match[1]}';
}
