import 'package:flutter_test/flutter_test.dart';
import 'package:sync_month/data/default_categories.dart';
import 'package:sync_month/models/models.dart';
import 'package:sync_month/utils/csv_export.dart';
import 'package:sync_month/utils/leftover.dart';
import 'package:sync_month/utils/money.dart';

void main() {
  test('month id helpers', () {
    expect(monthIdFromDate(DateTime(2026, 8, 17)), '2026-08');
    expect(nextMonthId('2026-08'), '2026-09');
    expect(previousMonthId('2026-08'), '2026-07');
    expect(nextMonthId('2026-12'), '2027-01');
  });

  test('preferredMonthId opens current month when it exists', () {
    expect(
      preferredMonthId(['2026-09', '2026-08', '2026-07']),
      '2026-08',
    );
  });

  test('preferredMonthId skips future months when current is missing', () {
    expect(
      preferredMonthId(['2026-09', '2026-07']),
      '2026-07',
    );
  });

  test('formatIls includes shekel symbol', () {
    final text = formatIls(4650);
    expect(text.contains('₪'), isTrue);
  });

  test('default categories are localized EN/RU without debt type', () {
    expect(DefaultCategories.all, isNotEmpty);
    for (final cat in DefaultCategories.all) {
      expect(cat.nameEn, isNotEmpty);
      expect(cat.nameRu, isNotEmpty);
      expect(
        ['spend', 'monthly', 'savings'],
        contains(cat.type),
      );
    }
    expect(
      DefaultCategories.all.any(
        (c) => c.nameEn == 'Groceries' && c.nameRu == 'Продукты',
      ),
      isTrue,
    );
    expect(
      DefaultCategories.all.where((c) => c.type == 'savings').length,
      1,
    );
    expect(
      DefaultCategories.all.any((c) => c.type == 'debt'),
      isFalse,
    );
    expect(
      DefaultCategories.all.any((c) => c.nameEn == 'Loans & debt'),
      isFalse,
    );
    expect(
      DefaultPots.all.any((p) => p.nameEn == 'Emergency fund'),
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
          iconKey: 'directions_car',
          type: 'spend',
          sortOrder: 0,
        ),
      ],
      subcategories: const [
        Subcategory(
          id: 'sub1',
          categoryId: 'c1',
          nameEn: 'Insurance',
          nameRu: 'Страховка',
        ),
      ],
      plans: const [
        MonthPlan(subcategoryId: 'sub1', planned: 400),
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
    expect(csv.contains('TOTALS'), isTrue);
  });

  test('BudgetCategory serializes optional target', () {
    const cat = BudgetCategory(
      id: 'c1',
      nameEn: 'Emergency fund',
      nameRu: 'Резервный фонд',
      colorValue: 0xFFFFCC80,
      iconKey: 'savings',
      type: 'savings',
      sortOrder: 0,
      targetAmount: 30000,
    );
    expect(cat.isSavings, isTrue);
    final map = cat.toMap();
    expect(map['targetAmount'], 30000);
    expect(map['iconKey'], 'savings');
    expect(map.containsKey('savedTotal'), isFalse);

    final parsed = BudgetCategory.fromMap('c1', map);
    expect(parsed.targetAmount, 30000);
    expect(parsed.iconKey, 'savings');

    final noTarget = BudgetCategory.fromMap('c2', {
      'nameEn': 'Savings',
      'nameRu': 'Накопления',
      'colorValue': 0,
      'type': 'savings',
      'sortOrder': 1,
    });
    expect(noTarget.targetAmount, isNull);
    expect(noTarget.iconKey, 'category');
  });

  test('Subcategory serializes optional target and includeInTotal', () {
    const sub = Subcategory(
      id: 's1',
      categoryId: 'c1',
      nameEn: 'Investments',
      nameRu: 'Инвестиции',
      targetAmount: 10000,
      includeInTotal: true,
    );
    final map = sub.toMap();
    expect(map['targetAmount'], 10000);
    expect(map.containsKey('savedTotal'), isFalse);
    expect(map.containsKey('installmentTotal'), isFalse);

    final parsed = Subcategory.fromMap('s1', map);
    expect(parsed.targetAmount, 10000);
    expect(parsed.includeInTotal, isTrue);
  });

  test('PotBalance computes end balance', () {
    final pot = PotBalance(
      subcategoryId: 'p1',
      openingBalance: 1000,
      deposited: 200,
      withdrawn: 50,
      balance: PotBalance.computeBalance(
        openingBalance: 1000,
        deposited: 200,
        withdrawn: 50,
      ),
    );
    expect(pot.balance, 1150);
    final map = pot.toMap();
    final parsed = PotBalance.fromMap('p1', map);
    expect(parsed.openingBalance, 1000);
    expect(parsed.deposited, 200);
    expect(parsed.balance, 1150);
  });

  test('BudgetMonth summary fields round-trip', () {
    const month = BudgetMonth(
      id: '2026-08',
      incomeTotal: 10000,
      spentTotal: 4000,
      depositTotal: 1000,
      leftoverFromPrior: 500,
      cashLeft: 5500,
      savingsBeforeMonth: 2000,
      savingsThroughMonth: 3000,
      debtPaidTotal: 800,
    );
    final map = month.toMap();
    final parsed = BudgetMonth.fromMap('2026-08', map);
    expect(parsed.incomeTotal, 10000);
    expect(parsed.leftoverFromPrior, 500);
    expect(parsed.savingsThroughMonth, 3000);
    expect(parsed.debtPaidTotal, 800);
  });

  test('computeMonthCashLeft floors at zero', () {
    expect(
      computeMonthCashLeft(
        leftoverFromPrior: 100,
        incomeTotal: 1000,
        spentTotal: 400,
        depositTotal: 200,
      ),
      500,
    );
    expect(
      computeMonthCashLeft(
        leftoverFromPrior: 100,
        incomeTotal: 1000,
        spentTotal: 400,
        depositTotal: 200,
        debtPaidTotal: 100,
      ),
      400,
    );
    expect(
      computeMonthCashLeft(
        leftoverFromPrior: 0,
        incomeTotal: 100,
        spentTotal: 200,
        depositTotal: 0,
      ),
      0,
    );
  });

  test('Loan and LoanPayment serialize', () {
    final loan = Loan(
      id: 'l1',
      name: 'Car loan',
      type: 'installment',
      originalAmount: 60000,
      remainingBalance: 48000,
      monthlyPayment: 2000,
      totalInstallments: 30,
      paidInstallments: 6,
      status: 'active',
    );
    final map = loan.toMap();
    final parsed = Loan.fromMap('l1', map);
    expect(parsed.isInstallment, isTrue);
    expect(parsed.remainingBalance, 48000);
    expect(parsed.monthlyPayment, 2000);
    expect(parsed.isPaidOff, isFalse);

    final finished = loan.copyWith(
      paidInstallments: 30,
      remainingBalance: 0,
      status: 'paidOff',
    );
    expect(finished.isPaidOff, isTrue);

    final finishedByCount = loan.copyWith(
      paidInstallments: 30,
      remainingBalance: 100,
    );
    expect(finishedByCount.isPaidOff, isTrue);

    final payment = LoanPayment(
      id: 'p1',
      loanId: 'l1',
      amount: 2000,
      date: DateTime(2026, 8, 1),
      reducesBalance: true,
    );
    final pMap = payment.toMap();
    expect(pMap['loanId'], 'l1');
    expect(LoanPayment.fromMap('p1', pMap).amount, 2000);
  });

  test('Deposit serializes like spend events without isDeposit flag', () {
    final d = Deposit(
      id: 'd1',
      subcategoryId: 'pot1',
      amount: 40,
      date: DateTime(2026, 8, 12),
      createdBy: 'u1',
      createdByName: 'Ada',
    );
    final map = d.toMap();
    expect(map['createdBy'], 'u1');
    expect(map.containsKey('isDeposit'), isFalse);
    final parsed = Deposit.fromMap('d1', map);
    expect(parsed.createdByName, 'Ada');
  });

  test('MonthTotals totalSpent includes deposits and debt', () {
    const totals = MonthTotals(
      income: 100,
      planned: 80,
      actual: 50,
      savedThisMonth: 20,
      debtPaidThisMonth: 10,
      leftoverFromPrior: 10,
    );
    expect(totals.totalSpent, 80);
    expect(totals.remaining, 0);
    expect(totals.cashLeft, 20);
    expect(totals.planExceedsIncome, isFalse);
    expect(totals.savedThisMonth, 20);
  });

  test('Household member roles default to editor', () {
    const household = Household(
      id: 'h1',
      name: 'Ours',
      memberIds: ['a', 'b'],
      inviteCode: 'ABC123',
      createdBy: 'a',
      memberProfiles: {
        'a': MemberProfile(uid: 'a', name: 'Ann', role: 'owner'),
        'b': MemberProfile(uid: 'b', name: 'Ben', role: 'viewer'),
      },
    );
    expect(household.canEditPlan('a'), isTrue);
    expect(household.canEditPlan('b'), isFalse);
    expect(household.memberName('b'), 'Ben');
  });

  test('Household.isOwnedBy uses createdBy, or sole member if owner is missing',
      () {
    const owned = Household(
      id: 'h1',
      name: 'Ours',
      memberIds: ['a', 'b'],
      inviteCode: 'ABC123',
      createdBy: 'a',
    );
    expect(owned.isOwnedBy('a'), isTrue);
    expect(owned.isOwnedBy('b'), isFalse);

    const legacySole = Household(
      id: 'h2',
      name: 'Mine',
      memberIds: ['a'],
      inviteCode: 'XYZ789',
    );
    expect(legacySole.isOwnedBy('a'), isTrue);
    expect(legacySole.isOwnedBy('b'), isFalse);

    const legacyShared = Household(
      id: 'h3',
      name: 'Shared',
      memberIds: ['a', 'b'],
      inviteCode: 'QWE456',
    );
    expect(legacyShared.isOwnedBy('a'), isFalse);
    expect(legacyShared.isOwnedBy('b'), isFalse);
  });

  test('AppUser supports multiple householdIds and activeHouseholdId', () {
    final user = AppUser.fromMap('u1', {
      'email': 'a@b.c',
      'householdIds': ['h1', 'h2'],
      'activeHouseholdId': 'h2',
      'localeCode': 'en',
    });
    expect(user.householdIds, ['h1', 'h2']);
    expect(user.activeHouseholdId, 'h2');
    expect(user.hasHouseholds, isTrue);

    final repaired = AppUser.fromMap('u1', {
      'email': 'a@b.c',
      'householdIds': ['h1', 'h2'],
      'activeHouseholdId': 'missing',
    });
    expect(repaired.activeHouseholdId, 'h1');

    final empty = AppUser.fromMap('u1', {'email': 'a@b.c'});
    expect(empty.householdIds, isEmpty);
    expect(empty.activeHouseholdId, isNull);
    expect(empty.hasHouseholds, isFalse);
  });
}
