import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/default_categories.dart';
import '../models/models.dart';
import '../utils/leftover.dart';
import '../utils/money.dart';

part 'budget_repository/households.dart';
part 'budget_repository/recurring_bills.dart';
part 'budget_repository/months.dart';
part 'budget_repository/queries.dart';
part 'budget_repository/catalog.dart';
part 'budget_repository/ledger.dart';
part 'budget_repository/loans.dart';

class BudgetRepository {
  BudgetRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  /// Fixed income-source doc id for withdrawals from savings pots.
  static const fromSavingsIncomeSourceId = 'from_savings';

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  DocumentReference<Map<String, dynamic>> _householdRef(String householdId) =>
      _db.collection('households').doc(householdId);

  CollectionReference<Map<String, dynamic>> _months(String householdId) =>
      _householdRef(householdId).collection('months');

  DocumentReference<Map<String, dynamic>> _monthRef(
    String householdId,
    String monthId,
  ) => _months(householdId).doc(monthId);

  CollectionReference<Map<String, dynamic>> _categories(String householdId) =>
      _householdRef(householdId).collection('categories');

  CollectionReference<Map<String, dynamic>> _subcategories(
    String householdId,
  ) => _householdRef(householdId).collection('subcategories');

  CollectionReference<Map<String, dynamic>> _loans(String householdId) =>
      _householdRef(householdId).collection('loans');

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _commitInChunks(
    List<void Function(WriteBatch batch)> ops,
  ) async {
    const limit = 400;
    for (var i = 0; i < ops.length; i += limit) {
      final batch = _db.batch();
      final end = min(i + limit, ops.length);
      for (var j = i; j < end; j++) {
        ops[j](batch);
      }
      await batch.commit();
    }
  }

  Map<String, dynamic> _emptyMonthSummary({
    required String monthId,
    double leftoverFromPrior = 0,
    double savingsBeforeMonth = 0,
    double savingsThroughMonth = 0,
  }) {
    final cashLeft = computeMonthCashLeft(
      leftoverFromPrior: leftoverFromPrior,
      incomeTotal: 0,
      spentTotal: 0,
      depositTotal: 0,
    );
    return BudgetMonth(
      id: monthId,
      leftoverFromPrior: leftoverFromPrior,
      cashLeft: cashLeft,
      savingsBeforeMonth: savingsBeforeMonth,
      savingsThroughMonth: savingsThroughMonth,
    ).toMap();
  }

  Future<double> _resolveLeftoverFromPrior(
    String householdId,
    String monthId,
  ) async {
    final priorId = previousMonthId(monthId);
    final priorSnap = await _monthRef(householdId, priorId).get();
    if (!priorSnap.exists || priorSnap.data() == null) return 0;
    final prior = BudgetMonth.fromMap(priorSnap.id, priorSnap.data()!);
    return leftoverFromPriorCashLeft(prior.cashLeft);
  }

  Future<Map<String, PotBalance>> _fetchPriorPotBalances(
    String householdId,
    String monthId,
  ) async {
    final priorId = previousMonthId(monthId);
    final priorSnap = await _monthRef(householdId, priorId).get();
    if (!priorSnap.exists) return {};
    final pots = await priorSnap.reference.collection('potBalances').get();
    return {
      for (final d in pots.docs) d.id: PotBalance.fromMap(d.id, d.data()),
    };
  }

  Future<List<Subcategory>> _liveSavingsPots(String householdId) async {
    final cats = await _categories(householdId).get();
    final savingsCatIds = {
      for (final c in cats.docs)
        if (c.data()['type'] == 'savings') c.id,
    };
    if (savingsCatIds.isEmpty) return const [];
    final subs = await _subcategories(householdId).get();
    return subs.docs
        .map((d) => Subcategory.fromMap(d.id, d.data()))
        .where(
          (s) =>
              !s.archived &&
              savingsCatIds.contains(s.categoryId) &&
              !DefaultPots.isLeftoverName(s.nameEn),
        )
        .toList();
  }

  void _bootstrapPotBalances({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> monthRef,
    required List<Subcategory> pots,
    required Map<String, PotBalance> priorBalances,
  }) {
    for (final pot in pots) {
      final opening = priorBalances[pot.id]?.balance ?? 0;
      final balance = PotBalance(
        subcategoryId: pot.id,
        openingBalance: opening,
        deposited: 0,
        withdrawn: 0,
        balance: opening,
      );
      batch.set(
        monthRef.collection('potBalances').doc(pot.id),
        balance.toMap(),
      );
    }
  }

  double _sumIncludedBalances(
    List<Subcategory> pots,
    Map<String, PotBalance> balances, {
    required bool opening,
  }) {
    var sum = 0.0;
    for (final pot in pots) {
      if (!pot.includeInTotal) continue;
      final b = balances[pot.id];
      if (b == null) continue;
      sum += opening ? b.openingBalance : b.balance;
    }
    return sum;
  }

  static MonthStatsSnapshot monthStatsFromArchive(
    String monthId,
    Map<String, dynamic> data,
  ) {
    List<Map<String, dynamic>> maps(String key) {
      final raw = data[key];
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }

    final monthMap = data['month'];
    final month = monthMap is Map
        ? BudgetMonth.fromMap(monthId, Map<String, dynamic>.from(monthMap))
        : null;
    return MonthStatsSnapshot(
      monthId: monthId,
      expenses: [
        for (final m in maps('expenses'))
          Expense.fromMap(m['id'] as String? ?? '', m),
      ],
      deposits: [
        for (final m in maps('deposits'))
          Deposit.fromMap(m['id'] as String? ?? '', m),
      ],
      plans: [
        for (final m in maps('plans'))
          MonthPlan.fromMap(
            m['id'] as String? ?? m['subcategoryId'] as String? ?? '',
            m,
          ),
      ],
      income: (data['income'] as num?)?.toDouble() ?? month?.incomeTotal ?? 0,
      debtPaid:
          (data['debtPaid'] as num?)?.toDouble() ?? month?.debtPaidTotal ?? 0,
    );
  }

  Future<void> _refreshCashLeftInTx(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> monthRef,
    Map<String, dynamic> monthData, {
    double? incomeDelta,
    double? spentDelta,
    double? depositDelta,
    double? debtPaidDelta,
    double? savingsBeforeDelta,
    double? savingsThroughDelta,
  }) {
    final income = (monthData['incomeTotal'] as num?)?.toDouble() ?? 0;
    final spent = (monthData['spentTotal'] as num?)?.toDouble() ?? 0;
    final deposit = (monthData['depositTotal'] as num?)?.toDouble() ?? 0;
    final debtPaid = (monthData['debtPaidTotal'] as num?)?.toDouble() ?? 0;
    final leftover = (monthData['leftoverFromPrior'] as num?)?.toDouble() ?? 0;
    final nextIncome = income + (incomeDelta ?? 0);
    final nextSpent = spent + (spentDelta ?? 0);
    final nextDeposit = deposit + (depositDelta ?? 0);
    final nextDebtPaid = debtPaid + (debtPaidDelta ?? 0);
    final updates = <String, dynamic>{
      if (incomeDelta != null && incomeDelta != 0)
        'incomeTotal': FieldValue.increment(incomeDelta),
      if (spentDelta != null && spentDelta != 0)
        'spentTotal': FieldValue.increment(spentDelta),
      if (depositDelta != null && depositDelta != 0)
        'depositTotal': FieldValue.increment(depositDelta),
      if (debtPaidDelta != null && debtPaidDelta != 0)
        'debtPaidTotal': FieldValue.increment(debtPaidDelta),
      if (savingsBeforeDelta != null && savingsBeforeDelta != 0)
        'savingsBeforeMonth': FieldValue.increment(savingsBeforeDelta),
      if (savingsThroughDelta != null && savingsThroughDelta != 0)
        'savingsThroughMonth': FieldValue.increment(savingsThroughDelta),
      'cashLeft': computeMonthCashLeft(
        leftoverFromPrior: leftover,
        incomeTotal: nextIncome,
        spentTotal: nextSpent,
        depositTotal: nextDeposit,
        debtPaidTotal: nextDebtPaid,
      ),
    };
    tx.update(monthRef, updates);
    return Future.value();
  }

  /// Propagate cashLeft → leftoverFromPrior along the next calendar months only.
  Future<void> _cascadeLeftoverToFollowingMonths(
    String householdId,
    String monthId,
  ) async {
    final currentSnap = await _monthRef(householdId, monthId).get();
    if (!currentSnap.exists || currentSnap.data() == null) return;
    final current = BudgetMonth.fromMap(currentSnap.id, currentSnap.data()!);
    var cashLeft = computeMonthCashLeft(
      leftoverFromPrior: current.leftoverFromPrior,
      incomeTotal: current.incomeTotal,
      spentTotal: current.spentTotal,
      depositTotal: current.depositTotal,
      debtPaidTotal: current.debtPaidTotal,
    );
    if ((cashLeft - current.cashLeft).abs() > 0.0001) {
      await currentSnap.reference.update({'cashLeft': cashLeft});
    }

    var id = monthId;
    while (true) {
      final nextId = nextMonthId(id);
      final nextRef = _monthRef(householdId, nextId);
      final nextSnap = await nextRef.get();
      if (!nextSnap.exists || nextSnap.data() == null) return;
      final next = BudgetMonth.fromMap(nextSnap.id, nextSnap.data()!);
      final nextLeftover = leftoverFromPriorCashLeft(cashLeft);
      if ((next.leftoverFromPrior - nextLeftover).abs() <= 0.0001 &&
          (computeMonthCashLeft(
                        leftoverFromPrior: next.leftoverFromPrior,
                        incomeTotal: next.incomeTotal,
                        spentTotal: next.spentTotal,
                        depositTotal: next.depositTotal,
                        debtPaidTotal: next.debtPaidTotal,
                      ) -
                      next.cashLeft)
                  .abs() <=
              0.0001) {
        return;
      }
      final newCash = computeMonthCashLeft(
        leftoverFromPrior: nextLeftover,
        incomeTotal: next.incomeTotal,
        spentTotal: next.spentTotal,
        depositTotal: next.depositTotal,
        debtPaidTotal: next.debtPaidTotal,
      );
      await nextRef.update({
        'leftoverFromPrior': nextLeftover,
        'cashLeft': newCash,
      });
      cashLeft = newCash;
      id = nextId;
    }
  }

  /// Propagate end balance of [subcategoryId] along the next calendar months.
  Future<void> _cascadePotBalancesToFollowingMonths(
    String householdId,
    String monthId,
    String subcategoryId,
  ) async {
    var id = monthId;
    while (true) {
      final nextId = nextMonthId(id);
      final curPot = await _monthRef(
        householdId,
        id,
      ).collection('potBalances').doc(subcategoryId).get();
      if (!curPot.exists || curPot.data() == null) return;
      final endBalance = PotBalance.fromMap(
        subcategoryId,
        curPot.data()!,
      ).balance;

      final nextMonthRef = _monthRef(householdId, nextId);
      final nextMonthSnap = await nextMonthRef.get();
      if (!nextMonthSnap.exists) return;

      final nextPotRef = nextMonthRef
          .collection('potBalances')
          .doc(subcategoryId);
      var openingDelta = 0.0;
      var balanceDelta = 0.0;
      await _db.runTransaction((tx) async {
        final nextPotSnap = await tx.get(nextPotRef);
        final monthSnap = await tx.get(nextMonthRef);
        if (!monthSnap.exists) return;

        final existing = nextPotSnap.exists
            ? PotBalance.fromMap(subcategoryId, nextPotSnap.data()!)
            : PotBalance(subcategoryId: subcategoryId);
        final next = existing.copyWith(
          openingBalance: endBalance,
          balance: PotBalance.computeBalance(
            openingBalance: endBalance,
            deposited: existing.deposited,
            withdrawn: existing.withdrawn,
          ),
        );
        openingDelta = next.openingBalance - existing.openingBalance;
        balanceDelta = next.balance - existing.balance;
        tx.set(nextPotRef, next.toMap());
        if (openingDelta != 0 || balanceDelta != 0) {
          await _refreshCashLeftInTx(
            tx,
            nextMonthRef,
            monthSnap.data()!,
            savingsBeforeDelta: openingDelta,
            savingsThroughDelta: balanceDelta,
          );
        }
      });
      if (openingDelta == 0 && balanceDelta == 0) return;
      id = nextId;
    }
  }
}
