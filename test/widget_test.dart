import 'package:flutter_test/flutter_test.dart';

import 'package:simple_budget/utils/money.dart';

void main() {
  test('month id helpers', () {
    expect(monthIdFromDate(DateTime(2026, 8, 17)), '2026-08');
    expect(nextMonthId('2026-08'), '2026-09');
    expect(previousMonthId('2026-08'), '2026-07');
    expect(nextMonthId('2026-12'), '2027-01');
  });

  test('formatIls includes shekel symbol', () {
    final text = formatIls(4650);
    expect(text.contains('₪'), isTrue);
  });
}
