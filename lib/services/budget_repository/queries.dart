part of '../budget_repository.dart';

/// Read-side streams, fetches, archive and statistics.
extension BudgetRepositoryQueries on BudgetRepository {
  Stream<List<BudgetCategory>> watchCategories(String householdId) {
    return _categories(householdId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => BudgetCategory.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<Subcategory>> watchSubcategories(String householdId) {
    return _subcategories(householdId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Subcategory.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<MonthPlan>> watchPlans(String householdId, String monthId) {
    return _monthRef(householdId, monthId)
        .collection('plans')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => MonthPlan.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<Expense>> watchExpenses(String householdId, String monthId) {
    return _monthRef(householdId, monthId)
        .collection('expenses')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Expense.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<Deposit>> watchDeposits(String householdId, String monthId) {
    return _monthRef(householdId, monthId)
        .collection('deposits')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Deposit.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<PotBalance>> watchPotBalances(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('potBalances')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => PotBalance.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<Loan>> watchLoans(String householdId) {
    return _loans(householdId)
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs.map((d) => Loan.fromMap(d.id, d.data())).toList());
  }

  Stream<List<LoanPayment>> watchLoanPayments(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('loanPayments')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => LoanPayment.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<LoanPayment>> watchLoanPaymentsForLoan({
    required String householdId,
    required String loanId,
  }) {
    return _db
        .collectionGroup('loanPayments')
        .where('loanId', isEqualTo: loanId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .where((d) {
                // Scope to this household's months path.
                final path = d.reference.path;
                return path.startsWith('households/$householdId/months/');
              })
              .map((d) => LoanPayment.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<List<MonthPlan>> fetchPlans(String householdId, String monthId) async {
    final snap = await _monthRef(
      householdId,
      monthId,
    ).collection('plans').get();
    return snap.docs.map((d) => MonthPlan.fromMap(d.id, d.data())).toList();
  }

  Future<List<Expense>> fetchExpenses(
    String householdId,
    String monthId,
  ) async {
    final snap = await _monthRef(
      householdId,
      monthId,
    ).collection('expenses').get();
    return snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList();
  }

  Future<List<Deposit>> fetchDeposits(
    String householdId,
    String monthId,
  ) async {
    final snap = await _monthRef(
      householdId,
      monthId,
    ).collection('deposits').get();
    return snap.docs.map((d) => Deposit.fromMap(d.id, d.data())).toList();
  }

  Future<List<IncomeEntry>> fetchIncomeEntries(
    String householdId,
    String monthId,
  ) async {
    final snap = await _monthRef(
      householdId,
      monthId,
    ).collection('incomeEntries').get();
    return snap.docs.map((d) => IncomeEntry.fromMap(d.id, d.data())).toList();
  }

  Future<BudgetMonth?> fetchMonth(String householdId, String monthId) async {
    final snap = await _monthRef(householdId, monthId).get();
    if (!snap.exists || snap.data() == null) return null;
    return BudgetMonth.fromMap(snap.id, snap.data()!);
  }

  DocumentReference<Map<String, dynamic>> _monthArchiveRef(
    String householdId,
    String monthId,
  ) => _monthRef(householdId, monthId).collection('archive').doc('bundle');

  bool isClosedMonth(String monthId) =>
      monthId.compareTo(monthIdFromDate(DateTime.now())) < 0;

  Future<MonthStatsSnapshot?> fetchMonthArchive(
    String householdId,
    String monthId,
  ) async {
    final snap = await _monthArchiveRef(householdId, monthId).get();
    if (!snap.exists || snap.data() == null) return null;
    return BudgetRepository.monthStatsFromArchive(monthId, snap.data()!);
  }

  Future<void> writeMonthArchive({
    required String householdId,
    required String monthId,
    required MonthStatsSnapshot stats,
    BudgetMonth? month,
  }) {
    return _monthArchiveRef(householdId, monthId).set({
      'month': month?.toMap(),
      'income': stats.income,
      'debtPaid': stats.debtPaid,
      'expenses': [
        for (final e in stats.expenses) {'id': e.id, ...e.toMap()},
      ],
      'deposits': [
        for (final d in stats.deposits) {'id': d.id, ...d.toMap()},
      ],
      'plans': [
        for (final p in stats.plans) {'id': p.subcategoryId, ...p.toMap()},
      ],
      'incomeEntries': const <Map<String, dynamic>>[],
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<MonthStatsSnapshot> fetchMonthStats(
    String householdId,
    String monthId, {
    bool preferArchive = true,
  }) async {
    if (preferArchive) {
      final archived = await fetchMonthArchive(householdId, monthId);
      if (archived != null) return archived;
    }
    final expenses = await fetchExpenses(householdId, monthId);
    final deposits = await fetchDeposits(householdId, monthId);
    final plans = await fetchPlans(householdId, monthId);
    final month = await fetchMonth(householdId, monthId);
    final incomeEntries = await fetchIncomeEntries(householdId, monthId);
    final stats = MonthStatsSnapshot(
      monthId: monthId,
      expenses: expenses,
      deposits: deposits,
      plans: plans,
      income:
          month?.incomeTotal ??
          incomeEntries.fold<double>(0, (s, e) => s + e.amount),
      debtPaid: month?.debtPaidTotal ?? 0,
    );
    if (isClosedMonth(monthId)) {
      try {
        await writeMonthArchive(
          householdId: householdId,
          monthId: monthId,
          stats: stats,
          month: month,
        );
      } catch (_) {}
    }
    return stats;
  }

  Stream<List<IncomeSource>> watchIncomeSources(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('incomeSources')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => IncomeSource.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<IncomeEntry>> watchIncomeEntries(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('incomeEntries')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => IncomeEntry.fromMap(d.id, d.data())).toList(),
        );
  }
}
