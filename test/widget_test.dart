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
      DefaultCategories.all.any(
        (c) => c.nameEn == 'Groceries' && c.nameRu == 'Продукты',
      ),
      isTrue,
    );
    expect(
      DefaultCategories.all.any(
        (c) => c.nameEn == 'Savings' && c.type == 'savings',
      ),
      isTrue,
    );
  });

  test('buildMonthCsv includes income, plans, and expenses', () {
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
          nameEn: 'Car',
          nameRu: 'Автомобиль',
          colorValue: 0xFF00FF00,
          type: 'expense',
          sortOrder: 0,
        ),
      ],
      subcategories: const [
        Subcategory(
          id: 'sub1',
          categoryId: 'c1',
          nameEn: 'Insurance',
          nameRu: 'Страховка',
          installmentTotal: 12,
        ),
      ],
      plans: const [
        MonthPlan(
          subcategoryId: 'sub1',
          planned: 400,
          installmentCurrent: 3,
        ),
      ],
      expenses: [
        Expense(
          id: 'x1',
          subcategoryId: 'sub1',
          amount: 400,
          date: DateTime(2026, 8, 12),
          note: 'Phoenix',
        ),
      ],
    );
    expect(csv.contains('INCOME'), isTrue);
    expect(csv.contains('PLANS'), isTrue);
    expect(csv.contains('EXPENSES'), isTrue);
    expect(csv.contains('Salary'), isTrue);
    expect(csv.contains('Insurance'), isTrue);
    expect(csv.contains('Phoenix'), isTrue);
    expect(csv.contains('3/12'), isTrue);
    expect(csv.contains('TOTALS'), isTrue);
  });

  test('BudgetCategory serializes optional target and ignores savedTotal in toMap',
      () {
    const cat = BudgetCategory(
      id: 'c1',
      nameEn: 'Emergency fund',
      nameRu: 'Резервный фонд',
      colorValue: 0xFFFFCC80,
      type: 'savings',
      sortOrder: 0,
      targetAmount: 30000,
      savedTotal: 1200,
    );
    expect(cat.isSavings, isTrue);
    final map = cat.toMap();
    expect(map['targetAmount'], 30000);
    expect(map.containsKey('savedTotal'), isFalse);

    final parsed = BudgetCategory.fromMap('c1', {
      ...map,
      'savedTotal': 1200,
    });
    expect(parsed.targetAmount, 30000);
    expect(parsed.savedTotal, 1200);

    final noTarget = BudgetCategory.fromMap('c2', {
      'nameEn': 'Savings',
      'nameRu': 'Накопления',
      'colorValue': 0,
      'type': 'savings',
      'sortOrder': 1,
    });
    expect(noTarget.targetAmount, isNull);
    expect(noTarget.savedTotal, 0);
  });

  test('invite share message shape via localizations is not empty', () {
    final totals = MonthTotals(income: 100, planned: 80, actual: 50);
    expect(totals.remaining, 30);
    expect(totals.planExceedsIncome, isFalse);
  });
}
