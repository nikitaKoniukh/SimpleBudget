part of '../app_state.dart';

/// Logging and editing expenses, income, deposits and withdrawals.
extension AppStateLedger on AppState {
  Future<void> addExpense({
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _trackedWrite(
      'addExpense',
      {
        'householdId': hid,
        'monthId': mid,
        'subcategoryId': subcategoryId,
        'amount': amount,
      },
      () {
        return _repo.addExpense(
          householdId: hid,
          monthId: mid,
          subcategoryId: subcategoryId,
          amount: amount,
          date: date,
          note: note,
          createdBy: currentUid,
          createdByName: currentDisplayName,
        );
      },
    );
  }

  Future<void> addIncomeEntry({
    required String sourceId,
    required double amount,
    String? note,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _trackedWrite(
      'addIncomeEntry',
      {
        'householdId': hid,
        'monthId': mid,
        'sourceId': sourceId,
        'amount': amount,
      },
      () {
        return _repo.addIncomeEntry(
          householdId: hid,
          monthId: mid,
          sourceId: sourceId,
          amount: amount,
          note: note,
          createdBy: currentUid,
          createdByName: currentDisplayName,
        );
      },
    );
  }

  Future<void> addDeposit({
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _trackedWrite(
      'addDeposit',
      {
        'householdId': hid,
        'monthId': mid,
        'subcategoryId': subcategoryId,
        'amount': amount,
      },
      () {
        return _repo.addDeposit(
          householdId: hid,
          monthId: mid,
          subcategoryId: subcategoryId,
          amount: amount,
          date: date,
          note: note,
          createdBy: currentUid,
          createdByName: currentDisplayName,
          includeInTotal: potIncludeInTotal(subcategoryId),
        );
      },
    );
  }

  /// Withdraws from a savings pot for the selected month.
  ///
  /// When [creditIncome] is true, also logs income under "From savings".
  Future<void> addWithdrawal({
    required String subcategoryId,
    required double amount,
    String? note,
    bool creditIncome = true,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    if (!_isSavingsPot(subcategoryId)) return;
    if (amount <= 0) return;
    if (creditIncome) {
      await _repo.ensureFromSavingsIncomeSource(householdId: hid, monthId: mid);
    }
    await _repo.addWithdrawal(
      householdId: hid,
      monthId: mid,
      subcategoryId: subcategoryId,
      amount: amount,
      note: note,
      createdBy: currentUid,
      createdByName: currentDisplayName,
      includeInTotal: potIncludeInTotal(subcategoryId),
      creditIncome: creditIncome,
    );
  }

  /// Sets opening balance ("already saved") for a pot in the selected month.
  Future<void> addPriorSavings({
    required String subcategoryId,
    required double amount,
  }) async {
    if (amount <= 0) return;
    final current = potOpeningBalance(subcategoryId);
    await setPriorSavings(
      subcategoryId: subcategoryId,
      amount: current + amount,
    );
  }

  /// Sets the opening (prior) balance for a pot; this month's deposits stay.
  Future<void> setPriorSavings({
    required String subcategoryId,
    required double amount,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    if (!_isSavingsPot(subcategoryId)) return;
    await _repo.setPotOpeningBalance(
      householdId: hid,
      monthId: mid,
      subcategoryId: subcategoryId,
      openingBalance: amount < 0 ? 0 : amount,
      includeInTotal: potIncludeInTotal(subcategoryId),
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    Expense? old;
    for (final e in _expenses) {
      if (e.id == expense.id) {
        old = e;
        break;
      }
    }
    await _repo.updateExpense(
      householdId: hid,
      monthId: mid,
      expense: expense,
      previous: old ?? expense,
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    Expense? old;
    for (final e in _expenses) {
      if (e.id == expenseId) {
        old = e;
        break;
      }
    }
    if (old == null) return;
    await _repo.deleteExpense(householdId: hid, monthId: mid, expense: old);
  }

  Future<void> updateDeposit(Deposit deposit) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    Deposit? old;
    for (final d in _deposits) {
      if (d.id == deposit.id) {
        old = d;
        break;
      }
    }
    await _repo.updateDeposit(
      householdId: hid,
      monthId: mid,
      deposit: deposit,
      previous: old ?? deposit,
      includeInTotal: potIncludeInTotal(deposit.subcategoryId),
    );
  }

  Future<void> deleteDeposit(String depositId) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    Deposit? old;
    for (final d in _deposits) {
      if (d.id == depositId) {
        old = d;
        break;
      }
    }
    if (old == null) return;
    await _repo.deleteDeposit(
      householdId: hid,
      monthId: mid,
      deposit: old,
      includeInTotal: potIncludeInTotal(old.subcategoryId),
    );
  }

  Future<void> updateIncomeEntry(IncomeEntry entry) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    IncomeEntry? old;
    for (final e in _incomeEntries) {
      if (e.id == entry.id) {
        old = e;
        break;
      }
    }
    await _repo.updateIncomeEntry(
      householdId: hid,
      monthId: mid,
      entry: entry,
      previous: old ?? entry,
    );
  }

  Future<void> deleteIncomeEntry(String entryId) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    IncomeEntry? old;
    for (final e in _incomeEntries) {
      if (e.id == entryId) {
        old = e;
        break;
      }
    }
    if (old == null) return;
    await _repo.deleteIncomeEntry(householdId: hid, monthId: mid, entry: old);
  }
}
