import '../data/local/local_budget_store.dart';
import '../models/models.dart';
import 'budget_repository.dart';

class SyncEngine {
  SyncEngine({
    required BudgetRepository repo,
    LocalBudgetStore? store,
  })  : _repo = repo,
        _store = store ?? LocalBudgetStore.instance;

  final BudgetRepository _repo;
  final LocalBudgetStore _store;

  LocalBudgetStore get store => _store;
  BudgetRepository get repo => _repo;

  Future<LocalCatalog> loadCatalog(String householdId) =>
      _store.loadCatalog(householdId);

  Future<LocalMonthBundle?> loadMonth(String householdId, String monthId) =>
      _store.loadMonth(householdId, monthId);

  Future<bool> hasMonth(String householdId, String monthId) =>
      _store.hasMonthSummary(householdId, monthId);

  Future<bool> isMonthSynced(String householdId, String monthId) =>
      _store.isMonthSynced(householdId, monthId);

  Future<void> persistHousehold(Household household) {
    return _store.upsertHouseholdDoc(
      householdId: household.id,
      collection: kColHousehold,
      docId: household.id,
      data: household.toMap(),
    );
  }

  Future<void> persistCategories(
    String householdId,
    List<BudgetCategory> items,
  ) {
    return _store.replaceHouseholdCollection(
      householdId: householdId,
      collection: kColCategories,
      docs: {for (final c in items) c.id: c.toMap()},
    );
  }

  Future<void> persistSubcategories(
    String householdId,
    List<Subcategory> items,
  ) {
    return _store.replaceHouseholdCollection(
      householdId: householdId,
      collection: kColSubcategories,
      docs: {for (final s in items) s.id: s.toMap()},
    );
  }

  Future<void> persistBills(String householdId, List<RecurringBill> items) {
    return _store.replaceHouseholdCollection(
      householdId: householdId,
      collection: kColBills,
      docs: {for (final b in items) b.id: b.toMap()},
    );
  }

  Future<void> persistLoans(String householdId, List<Loan> items) {
    return _store.replaceHouseholdCollection(
      householdId: householdId,
      collection: kColLoans,
      docs: {for (final l in items) l.id: l.toMap()},
    );
  }

  Future<void> persistMonthSummaries(
    String householdId,
    List<BudgetMonth> items,
  ) async {
    for (final month in items) {
      await persistMonthSummary(householdId, month);
    }
  }

  Future<void> persistMonthSummary(
    String householdId,
    BudgetMonth month,
  ) {
    return _store.upsertHouseholdDoc(
      householdId: householdId,
      collection: kColMonths,
      docId: month.id,
      data: month.toMap(),
    );
  }

  Future<void> persistMonthBundle({
    required String householdId,
    required String monthId,
    BudgetMonth? month,
    List<IncomeSource>? incomeSources,
    List<IncomeEntry>? incomeEntries,
    List<MonthPlan>? plans,
    List<Expense>? expenses,
    List<Deposit>? deposits,
    List<PotBalance>? potBalances,
    List<LoanPayment>? loanPayments,
    bool markSynced = false,
  }) async {
    if (month != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColMonths,
        docs: {monthId: month.toMap()},
      );
      await persistMonthSummary(householdId, month);
    }
    if (incomeSources != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColIncomeSources,
        docs: {for (final s in incomeSources) s.id: s.toMap()},
      );
    }
    if (incomeEntries != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColIncomeEntries,
        docs: {for (final e in incomeEntries) e.id: e.toMap()},
      );
    }
    if (plans != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColPlans,
        docs: {for (final p in plans) p.subcategoryId: p.toMap()},
      );
    }
    if (expenses != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColExpenses,
        docs: {for (final e in expenses) e.id: e.toMap()},
      );
    }
    if (deposits != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColDeposits,
        docs: {for (final d in deposits) d.id: d.toMap()},
      );
    }
    if (potBalances != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColPotBalances,
        docs: {for (final p in potBalances) p.subcategoryId: p.toMap()},
      );
    }
    if (loanPayments != null) {
      await _store.replaceMonthCollection(
        householdId: householdId,
        monthId: monthId,
        collection: kColLoanPayments,
        docs: {for (final p in loanPayments) p.id: p.toMap()},
      );
    }
    if (markSynced) {
      await _store.markMonthSynced(householdId, monthId);
    }
  }

  Future<T> enqueueAndRun<T>(
    String op,
    Map<String, dynamic> payload,
    Future<T> Function() send,
  ) async {
    final id = await _store.enqueueOutbox(op, payload);
    try {
      final result = await send();
      await _store.markOutboxDone(id);
      return result;
    } catch (_) {
      await _store.markOutboxFailed(id);
      rethrow;
    }
  }

  Future<MonthStatsSnapshot> statsFromBundle(
    String monthId,
    LocalMonthBundle bundle,
  ) {
    return Future.value(
      MonthStatsSnapshot(
        monthId: monthId,
        expenses: bundle.expenses,
        deposits: bundle.deposits,
        plans: bundle.plans,
        income: bundle.month?.incomeTotal ??
            bundle.incomeEntries.fold<double>(0, (s, e) => s + e.amount),
        debtPaid: bundle.month?.debtPaidTotal ?? 0,
      ),
    );
  }
}
