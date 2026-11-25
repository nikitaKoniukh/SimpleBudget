part of '../app_state.dart';

/// Derived, read-only views over the loaded household and month.
extension AppStateSelectors on AppState {
  List<BudgetCategory> get savingsCategories =>
      _categories.where((c) => c.isSavings).toList();

  BudgetCategory? get savingsCategory {
    for (final c in _categories) {
      if (c.isSavings &&
          c.nameEn.toLowerCase() ==
              DefaultCategories.savingsNameEn.toLowerCase()) {
        return c;
      }
    }
    for (final c in _categories) {
      if (c.isSavings) return c;
    }
    return null;
  }

  List<Subcategory> get savingsPots {
    final cat = savingsCategory;
    if (cat == null) return const [];
    return subcategoriesFor(cat.id);
  }

  List<Subcategory> get summableSavingsPots =>
      savingsPots.where((p) => p.includeInTotal).toList();

  String? get leftoverPotId {
    for (final pot in savingsPots) {
      if (DefaultPots.isLeftoverName(pot.nameEn)) return pot.id;
    }
    return null;
  }

  /// Calendar month before the selected one (for leftover period label).
  String? get leftoverSourceMonthId {
    final mid = _monthId;
    if (mid == null) return null;
    final prev = previousMonthId(mid);
    return _months.any((m) => m.id == prev) ? prev : null;
  }

  /// Cash leftover entering the selected month (stored on month doc).
  double get leftoverFromPreviousMonth =>
      _selectedMonth?.leftoverFromPrior ?? 0;

  /// Savings through and including the selected month (header total).
  double get savingsThroughSelectedMonth =>
      _selectedMonth?.savingsThroughMonth ?? 0;

  PotBalance? potBalanceFor(String subcategoryId) {
    for (final b in _potBalances) {
      if (b.subcategoryId == subcategoryId) return b;
    }
    return null;
  }

  double potBalanceAmount(String subcategoryId) =>
      potBalanceFor(subcategoryId)?.balance ?? 0;

  double potOpeningBalance(String subcategoryId) =>
      potBalanceFor(subcategoryId)?.openingBalance ?? 0;

  List<BudgetCategory> categoriesOfType(String type) =>
      _categories.where((c) => c.type == type).toList();

  List<Subcategory> subcategoriesOfType(String type) {
    final catIds = _categories
        .where((c) => c.type == type)
        .map((c) => c.id)
        .toSet();
    return subcategories.where((s) => catIds.contains(s.categoryId)).toList();
  }

  /// One-shot multi-month snapshot for Statistics (does not replace live month).
  Future<Map<String, MonthStatsSnapshot>> loadStatsForMonths(
    List<String> monthIds,
  ) async {
    final hid = _activeHid;
    if (hid == null) return {};
    final result = <String, MonthStatsSnapshot>{};
    await Future.wait(
      monthIds.map((monthId) async {
        if (monthId == _monthId) {
          result[monthId] = MonthStatsSnapshot(
            monthId: monthId,
            expenses: List.of(_expenses),
            deposits: List.of(_deposits),
            plans: List.of(_plans),
            income:
                _selectedMonth?.incomeTotal ??
                _incomeEntries.fold<double>(0, (s, e) => s + e.amount),
            debtPaid: _selectedMonth?.debtPaidTotal ?? 0,
          );
          return;
        }
        final local = await _sync.loadMonth(hid, monthId);
        if (local != null && await _sync.isMonthSynced(hid, monthId)) {
          result[monthId] = await _sync.statsFromBundle(monthId, local);
          return;
        }
        final remote = await _repo.fetchMonthStats(hid, monthId);
        await _sync.persistMonthBundle(
          householdId: hid,
          monthId: monthId,
          expenses: remote.expenses,
          deposits: remote.deposits,
          plans: remote.plans,
          markSynced: true,
        );
        result[monthId] = remote;
      }),
    );
    return result;
  }

  MonthTotals get totals {
    // Live collections, not month.spentTotal — that summary only refreshes
    // on pull-to-refresh, so the Home hero would lag behind logged expenses.
    final liveSubIds = subcategories.map((s) => s.id).toSet();
    final leftoverId = leftoverPotId;
    final income = _incomeEntries.fold<double>(0, (s, e) => s + e.amount);
    final planned = _plans
        .where(
          (p) =>
              liveSubIds.contains(p.subcategoryId) &&
              p.subcategoryId != leftoverId,
        )
        .fold<double>(0, (s, p) => s + p.planned);
    final actual = _expenses
        .where((e) => liveSubIds.contains(e.subcategoryId))
        .fold<double>(0, (s, e) => s + e.amount);
    final savedThisMonth = _deposits
        .where((d) => liveSubIds.contains(d.subcategoryId))
        .fold<double>(0, (s, d) => s + d.amount);
    final debtPaid = _loanPayments.fold<double>(0, (s, p) => s + p.amount);
    return MonthTotals(
      income: income,
      planned: planned,
      actual: actual,
      savedThisMonth: savedThisMonth,
      debtPaidThisMonth: debtPaid,
      leftoverFromPrior: _selectedMonth?.leftoverFromPrior ?? 0,
    );
  }

  List<BudgetCategory> overspendWatchlist({double threshold = 0.8}) {
    return _categories.where((c) {
      if (c.isSavings) return false;
      final planned = categoryPlanned(c.id);
      if (planned <= 0) return false;
      return categoryActual(c.id) / planned >= threshold;
    }).toList();
  }

  List<Subcategory> subcategoriesFor(String categoryId) =>
      subcategories.where((s) => s.categoryId == categoryId).toList();

  /// Subcategories active in the selected month: has a plan and/or activity.
  List<Subcategory> subcategoriesForMonth(String categoryId) =>
      subcategoriesFor(categoryId).where(isSubcategoryActiveThisMonth).toList();

  bool isSubcategoryActiveThisMonth(Subcategory sub) {
    if (planFor(sub.id) != null ||
        spentFor(sub.id) > 0 ||
        depositedFor(sub.id) > 0) {
      return true;
    }
    // New months bootstrap potBalances; show pots even before a plan exists.
    if (_isSavingsPot(sub.id) && potBalanceFor(sub.id) != null) {
      return true;
    }
    return false;
  }

  String localizedSubcategoryName(Subcategory sub) {
    final plan = planFor(sub.id);
    if (plan != null) return plan.localizedName(localeCode, sub);
    return sub.localizedName(localeCode);
  }

  MonthPlan? planFor(String subcategoryId) {
    for (final plan in _plans) {
      if (plan.subcategoryId == subcategoryId) return plan;
    }
    return null;
  }

  double plannedFor(String subcategoryId) =>
      planFor(subcategoryId)?.planned ?? 0;

  double spentFor(String subcategoryId) => _expenses
      .where((e) => e.subcategoryId == subcategoryId)
      .fold(0, (s, e) => s + e.amount);

  double depositedFor(String subcategoryId) => _deposits
      .where((d) => d.subcategoryId == subcategoryId)
      .fold(0, (s, d) => s + d.amount);

  List<Expense> expensesFor(String subcategoryId) {
    final list = _expenses
        .where((e) => e.subcategoryId == subcategoryId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Deposit> depositsFor(String subcategoryId) {
    final list = _deposits
        .where((d) => d.subcategoryId == subcategoryId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double categoryPlanned(String categoryId) => subcategoriesForMonth(
    categoryId,
  ).fold(0, (s, sub) => s + plannedFor(sub.id));

  double categoryActual(String categoryId) => subcategoriesForMonth(
    categoryId,
  ).fold(0, (s, sub) => s + spentFor(sub.id));

  List<Expense> expensesForCategory(String categoryId) {
    final subIds = subcategoriesForMonth(categoryId).map((s) => s.id).toSet();
    final list = _expenses
        .where((e) => subIds.contains(e.subcategoryId))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  bool _isSavingsPot(String subcategoryId) {
    final sub = subcategoryById(subcategoryId);
    if (sub == null) return false;
    final cat = categoryById(sub.categoryId);
    return cat?.isSavings == true;
  }

  bool potIncludeInTotal(String subcategoryId) =>
      subcategoryById(subcategoryId)?.includeInTotal ?? true;

  Loan? loanById(String id) {
    for (final loan in _loans) {
      if (loan.id == id) return loan;
    }
    return null;
  }

  Subcategory? subcategoryById(String id) {
    for (final sub in _subcategories) {
      if (sub.id == id) return sub;
    }
    return null;
  }

  BudgetCategory? categoryById(String id) {
    for (final cat in _categories) {
      if (cat.id == id) return cat;
    }
    return null;
  }

  double incomeForSource(String sourceId) => _incomeEntries
      .where((e) => e.sourceId == sourceId)
      .fold(0, (s, e) => s + e.amount);
}
