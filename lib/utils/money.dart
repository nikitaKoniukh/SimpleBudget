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
