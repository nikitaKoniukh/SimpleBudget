import 'package:flutter_test/flutter_test.dart';
import 'package:sync_month/models/models.dart';
import 'package:sync_month/utils/csv_export.dart';
import 'package:sync_month/utils/leftover.dart';
import 'package:sync_month/utils/money.dart';

void main() {
  group('month ids', () {
    test('year boundaries', () {
      expect(previousMonthId('2026-01'), '2025-12');
      expect(nextMonthId('2025-12'), '2026-01');
      expect(monthIdFromDate(DateTime(987, 3)), '0987-03');
    });

    test('dateFixedToMonth clamps missing days and keeps time', () {
      final source = DateTime(2026, 1, 31, 14, 30);
      expect(dateFixedToMonth(source, '2026-02'), DateTime(2026, 2, 28, 14, 30));
      expect(dateFixedToMonth(source, '2028-02'), DateTime(2028, 2, 29, 14, 30));
      expect(dateFixedToMonth(source, '2026-04'), DateTime(2026, 4, 30, 14, 30));
      expect(
        dateFixedToMonth(DateTime(2026, 5, 15), '2026-06'),
        DateTime(2026, 6, 15),
      );
    });
  });

  group('preferredMonthId', () {
    final now = DateTime(2026, 8, 17);

    test('empty list returns null', () {
      expect(preferredMonthId(const [], now: now), isNull);
    });

    test('only future months returns the earliest one', () {
      expect(preferredMonthId(['2026-11', '2026-10'], now: now), '2026-10');
    });

    test('unsorted input picks latest past month', () {
      expect(
        preferredMonthId(['2026-03', '2026-06', '2026-01'], now: now),
        '2026-06',
      );
    });
  });

  group('suggestedNewMonthDate', () {
    final now = DateTime(2026, 8, 17);

    test('no months -> current calendar month', () {
      expect(suggestedNewMonthDate(const [], now: now), DateTime(2026, 8));
    });

    test('slot after the latest existing month', () {
      expect(
        suggestedNewMonthDate(['2026-06', '2026-08', '2026-07'], now: now),
        DateTime(2026, 9),
      );
    });

    test('rolls over the year', () {
      expect(suggestedNewMonthDate(['2026-12'], now: now), DateTime(2027, 1));
    });
  });

  group('leftover', () {
    test('computeMonthCashLeft subtracts every outflow', () {
      expect(
        computeMonthCashLeft(
          leftoverFromPrior: 500,
          incomeTotal: 10000,
          spentTotal: 6000,
          depositTotal: 1500,
          debtPaidTotal: 1000,
        ),
        2000,
      );
    });

    test('leftoverFromPriorCashLeft floors negatives', () {
      expect(leftoverFromPriorCashLeft(-10), 0);
      expect(leftoverFromPriorCashLeft(42.5), 42.5);
    });
  });

  group('MonthTotals', () {
    const totals = MonthTotals(
      income: 10000,
      planned: 9000,
      actual: 5000,
      savedThisMonth: 1000,
      debtPaidThisMonth: 500,
    );

    test('spend remaining includes savings and loan payments', () {
      expect(totals.totalSpent, 6500);
      expect(totals.spendRemaining, 3500);
      expect(totals.spentWithSavings, 6500);
      expect(totals.cashLeft, 3500);
      expect(totals.remaining, 2500);
      expect(totals.unallocated, 1000);
      expect(totals.planExceedsIncome, isFalse);
    });

    test('planExceedsIncome flags over-planning', () {
      const over = MonthTotals(income: 100, planned: 200, actual: 0);
      expect(over.planExceedsIncome, isTrue);
      expect(over.unallocated, -100);
    });
  });

  group('Loan', () {
    Loan installment({int? total, int? paid, double remaining = 1000}) => Loan(
      id: 'l1',
      name: 'Car',
      type: 'installment',
      originalAmount: 12000,
      remainingBalance: remaining,
      totalInstallments: total,
      paidInstallments: paid,
    );

    test('installment progress and remaining count', () {
      final loan = installment(total: 12, paid: 3);
      expect(loan.remainingInstallmentCount, 9);
      expect(loan.installmentProgress, closeTo(0.25, 1e-9));
      expect(loan.isPaidOff, isFalse);
    });

    test('overpaid installments clamp', () {
      final loan = installment(total: 12, paid: 15);
      expect(loan.remainingInstallmentCount, 0);
      expect(loan.installmentProgress, 1.0);
      expect(loan.isPaidOff, isTrue);
    });

    test('no total -> no installment stats', () {
      final loan = installment();
      expect(loan.remainingInstallmentCount, isNull);
      expect(loan.installmentProgress, isNull);
    });

    test('zero balance counts as paid off', () {
      expect(installment(total: 12, paid: 1, remaining: 0).isPaidOff, isTrue);
    });
  });

  test('PotBalance.copyWith recomputes balance', () {
    const pot = PotBalance(subcategoryId: 'p', openingBalance: 100);
    final next = pot.copyWith(deposited: 50, withdrawn: 20);
    expect(next.balance, 130);
    expect(pot.copyWith(balance: 7).balance, 7);
  });

  test('buildMonthCsv escapes commas, quotes and newlines', () {
    final csv = buildMonthCsv(
      monthId: '2026-08',
      householdName: 'Koniukh, family',
      incomeSources: const [
        IncomeSource(id: 's1', nameEn: 'Salary', nameRu: 'Зп', sortOrder: 0),
      ],
      incomeEntries: const [
        IncomeEntry(id: 'e1', sourceId: 's1', amount: 1, note: 'say "hi"'),
      ],
      categories: const [],
      subcategories: const [],
      plans: const [],
      expenses: [
        Expense(
          id: 'x',
          subcategoryId: 'missing',
          amount: 5,
          date: DateTime(2026, 8, 3),
          note: 'line1\nline2',
        ),
      ],
    );
    final lines = csv.split('\n');
    expect(lines.first, 'SyncMonth,"Koniukh, family",2026-08');
    expect(csv, contains('Salary,1.0,"say ""hi"""'));
    expect(csv, contains(',,2026-08-03,5.0,"line1\nline2"'));
  });
}
