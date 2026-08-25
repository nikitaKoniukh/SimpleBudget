import 'package:intl/intl.dart';

final _ilsFormat = NumberFormat.currency(
  locale: 'he_IL',
  symbol: '₪',
  decimalDigits: 2,
);

String formatIls(double amount) => _ilsFormat.format(amount);

String monthIdFromDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

DateTime dateFromMonthId(String monthId) {
  final parts = monthId.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

/// Keeps the day-of-month from [source], shifted into [monthId].
/// Clamps days that do not exist in the target month (e.g. Jan 31 → Feb 28).
DateTime dateFixedToMonth(DateTime source, String monthId) {
  final target = dateFromMonthId(monthId);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  final day = source.day.clamp(1, lastDay);
  return DateTime(
    target.year,
    target.month,
    day,
    source.hour,
    source.minute,
    source.second,
    source.millisecond,
    source.microsecond,
  );
}

String nextMonthId(String monthId) {
  final date = dateFromMonthId(monthId);
  final next = DateTime(date.year, date.month + 1);
  return monthIdFromDate(next);
}

String previousMonthId(String monthId) {
  final date = dateFromMonthId(monthId);
  final prev = DateTime(date.year, date.month - 1);
  return monthIdFromDate(prev);
}

/// Month to open on app launch: this calendar month if it exists, otherwise
/// the latest month that is not in the future.
String? preferredMonthId(Iterable<String> monthIds) {
  final ids = monthIds.toList();
  if (ids.isEmpty) return null;
  final current = monthIdFromDate(DateTime.now());
  if (ids.contains(current)) return current;
  final pastOrCurrent = ids.where((id) => id.compareTo(current) <= 0).toList()
    ..sort((a, b) => b.compareTo(a));
  if (pastOrCurrent.isNotEmpty) return pastOrCurrent.first;
  ids.sort();
  return ids.first;
}
