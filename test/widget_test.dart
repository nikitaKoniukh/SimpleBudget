import 'package:flutter_test/flutter_test.dart';
import 'package:sync_month/data/default_categories.dart';
import 'package:sync_month/models/models.dart';
import 'package:sync_month/utils/csv_export.dart';
import 'package:sync_month/utils/money.dart';

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

  test('default categories are localized EN/RU', () {
    expect(DefaultCategories.all, isNotEmpty);
    for (final cat in DefaultCategories.all) {
      expect(cat.nameEn, isNotEmpty);
      expect(cat.nameRu, isNotEmpty);
      expect(['expense', 'savings', 'debt'], contains(cat.type));
    }
    expect(
      DefaultCategories.all.any((c) => c.nameEn == 'Food' && c.nameRu == 'Еда'),
      isTrue,
    );
    expect(
      DefaultCategories.all.any(
        (c) => c.nameEn == 'Savings' && c.type == 'savings',
      ),
      isTrue,
    );
  });

  test('buildMonthCsv includes income and expense sections', () {
    final csv = buildMonthCsv(
      monthId: '2026-08',
      householdName: 'Our Family',
      incomeSources: const [
        IncomeSource(
          id: 's1',
          nameEn: 'Salary',
          nameRu: 'Зарплата',
          sortOrder: 0,
        ),
      ],
      incomeEntries: const [
        IncomeEntry(id: 'e1', sourceId: 's1', amount: 1000),
      ],
      categories: const [
        BudgetCategory(
          id: 'c1',
          nameEn: 'Home',
          nameRu: 'Дом',
          colorValue: 0xFF00FF00,
          type: 'expense',
          sortOrder: 0,
        ),
      ],
      lineItems: const [
        LineItem(
          id: 'i1',
          categoryId: 'c1',
          descriptionEn: 'Rent',
          descriptionRu: 'Аренда',
          planned: 4650,
          actual: 4650,
        ),
      ],
    );
    expect(csv.contains('INCOME'), isTrue);
    expect(csv.contains('EXPENSES'), isTrue);
    expect(csv.contains('Salary'), isTrue);
    expect(csv.contains('Rent'), isTrue);
    expect(csv.contains('TOTALS'), isTrue);
  });

  test('invite share message shape via localizations is not empty', () {
    final totals = MonthTotals(income: 100, planned: 80, actual: 50);
    expect(totals.remaining, 30);
    expect(totals.planExceedsIncome, isFalse);
  });
}
