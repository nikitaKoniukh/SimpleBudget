import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/locale_lookup.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';
import '../data/default_categories.dart';
import '../utils/money.dart';

class AppState extends ChangeNotifier {
  AppState({AuthService? authService, BudgetRepository? budgetRepository})
    : _auth = authService ?? AuthService(),
      _repo = budgetRepository ?? BudgetRepository() {
    _authSub = _auth.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _auth;
  final BudgetRepository _repo;

  AuthService get auth => _auth;
  BudgetRepository get repo => _repo;

  User? _firebaseUser;
  AppUser? _appUser;
  Household? _household;
  List<Household> _myHouseholds = [];
  String? _monthId;
  String _localeCode = deviceLocaleCode();
  bool _loading = true;
  /// False until the first months (and selected month) snapshots arrive.
  bool _budgetDataReady = false;
  String? _error;

  List<BudgetMonth> _months = [];
  BudgetMonth? _selectedMonth;
  List<IncomeSource> _incomeSources = [];
  List<IncomeEntry> _incomeEntries = [];
  List<BudgetCategory> _categories = [];
  List<Subcategory> _subcategories = [];
  List<MonthPlan> _plans = [];
  List<Expense> _expenses = [];
  List<Deposit> _deposits = [];
  List<PotBalance> _potBalances = [];
  List<Loan> _loans = [];
  List<LoanPayment> _loanPayments = [];

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;
  StreamSubscription<Household?>? _householdSub;
  StreamSubscription<List<BudgetMonth>>? _monthsSub;
  StreamSubscription<List<BudgetCategory>>? _categoriesSub;
  StreamSubscription<List<Subcategory>>? _subcategoriesSub;
  StreamSubscription<List<Loan>>? _loansSub;
  StreamSubscription<BudgetMonth?>? _selectedMonthSub;
  StreamSubscription<List<IncomeSource>>? _sourcesSub;
  StreamSubscription<List<IncomeEntry>>? _entriesSub;
  StreamSubscription<List<MonthPlan>>? _plansSub;
  StreamSubscription<List<Expense>>? _expensesSub;
  StreamSubscription<List<Deposit>>? _depositsSub;
  StreamSubscription<List<PotBalance>>? _potBalancesSub;
  StreamSubscription<List<LoanPayment>>? _loanPaymentsSub;
  bool get loading => _loading;
  bool get budgetDataReady => _budgetDataReady;
  String? get error => _error;
  AppUser? get appUser => _appUser;
  Household? get household => _household;
  List<Household> get myHouseholds => _myHouseholds;
  String? get activeHouseholdId =>
      _household?.id ?? _appUser?.activeHouseholdId;
  String? get monthId => _monthId;
  String get localeCode => _localeCode;
  bool get isSignedIn => _firebaseUser != null;
  bool get hasHousehold => _appUser?.hasHouseholds == true;
  bool get isHouseholdOwner {
    final uid = _firebaseUser?.uid;
    final household = _household;
    if (uid == null || household == null) return false;
    return household.isOwnedBy(uid);
  }

  bool get ownsAnyHousehold {
    final uid = _firebaseUser?.uid;
    if (uid == null) return false;
    return _myHouseholds.any((h) => h.isOwnedBy(uid));
  }

  bool get canEditPlan {
    final uid = _firebaseUser?.uid;
    final household = _household;
    if (uid == null || household == null) return false;
    return household.canEditPlan(uid);
  }

  String? get currentUid => _firebaseUser?.uid;
  Map<String, String> _memberLabels = {};

  String get currentDisplayName {
    final name = _appUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = _appUser?.email.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Member';
  }

  String memberLabel(String? uid) {
    if (uid == null || uid.isEmpty) return '';
    final fallback = _memberLabels[uid]?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return _household?.memberName(uid) ?? uid;
  }

  List<RecurringBill> _recurringBills = [];
  StreamSubscription<List<RecurringBill>>? _billsSub;
  List<RecurringBill> get recurringBills => _recurringBills;

  bool get hasMonthSelected => _monthId != null && _monthId!.isNotEmpty;
  List<BudgetMonth> get months => _months;
  BudgetMonth? get selectedMonth => _selectedMonth;

  List<IncomeSource> get incomeSources => _incomeSources;
  List<IncomeEntry> get incomeEntries => _incomeEntries;
  List<BudgetCategory> get categories => _categories;
  List<Subcategory> get subcategories =>
      _subcategories.where((s) => !s.archived).toList();
  List<MonthPlan> get plans => _plans;
  List<Expense> get expenses => _expenses;
  List<Deposit> get deposits => _deposits;
  List<PotBalance> get potBalances => _potBalances;
  List<Loan> get loans => _loans;
  List<Loan> get activeLoans =>
      _loans.where((l) => l.isActive && !l.isPaidOff).toList();
  List<LoanPayment> get loanPayments => _loanPayments;

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
    final catIds =
        _categories.where((c) => c.type == type).map((c) => c.id).toSet();
    return subcategories.where((s) => catIds.contains(s.categoryId)).toList();
  }

  /// One-shot multi-month snapshot for Statistics (does not replace live month).
  Future<Map<String, MonthStatsSnapshot>> loadStatsForMonths(
    List<String> monthIds,
  ) async {
    final hid = _activeHid;
    if (hid == null) return {};
    final result = <String, MonthStatsSnapshot>{};
    await Future.wait(monthIds.map((monthId) async {
      final expenses = await _repo.fetchExpenses(hid, monthId);
      final deposits = await _repo.fetchDeposits(hid, monthId);
      final plans = await _repo.fetchPlans(hid, monthId);
      final month = await _repo.fetchMonth(hid, monthId);
      final incomeEntries = await _repo.fetchIncomeEntries(hid, monthId);
      result[monthId] = MonthStatsSnapshot(
        monthId: monthId,
        expenses: expenses,
        deposits: deposits,
        plans: plans,
        income: month?.incomeTotal ??
            incomeEntries.fold<double>(0, (s, e) => s + e.amount),
        debtPaid: month?.debtPaidTotal ?? 0,
      );
    }));
    return result;
  }

  MonthTotals get totals {
    final month = _selectedMonth;
    final income = month?.incomeTotal ??
        _incomeEntries.fold<double>(0, (s, e) => s + e.amount);
    final liveSubIds = subcategories.map((s) => s.id).toSet();
    final leftoverId = leftoverPotId;
    final planned = month?.plannedTotal ??
        _plans
            .where(
              (p) =>
                  liveSubIds.contains(p.subcategoryId) &&
                  p.subcategoryId != leftoverId,
            )
            .fold<double>(0, (s, p) => s + p.planned);
    final actual = month?.spentTotal ??
        _expenses
            .where((e) => liveSubIds.contains(e.subcategoryId))
            .fold<double>(0, (s, e) => s + e.amount);
    final savedThisMonth = month?.depositTotal ??
        _deposits
            .where((d) => liveSubIds.contains(d.subcategoryId))
            .fold<double>(0, (s, d) => s + d.amount);
    return MonthTotals(
      income: income,
      planned: planned,
      actual: actual,
      savedThisMonth: savedThisMonth,
      debtPaidThisMonth: month?.debtPaidTotal ?? 0,
      leftoverFromPrior: month?.leftoverFromPrior ?? 0,
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

  double categoryPlanned(String categoryId) => subcategoriesForMonth(categoryId)
      .fold(0, (s, sub) => s + plannedFor(sub.id));

  double categoryActual(String categoryId) => subcategoriesForMonth(categoryId)
      .fold(0, (s, sub) => s + spentFor(sub.id));

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

  String? get _activeHid => _household?.id ?? _appUser?.activeHouseholdId;

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    await _userSub?.cancel();
    _userSub = null;
    await _detachBudgetListeners();
    _myHouseholds = [];
    if (user == null) {
      _appUser = null;
      _household = null;
      _monthId = null;
      _budgetDataReady = false;
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _appUser = await _auth.ensureUserDoc(user);
      _localeCode = _appUser!.localeCode;
      _userSub = _auth.watchAppUser(user.uid).listen((u) async {
        if (u == null) return;
        final prevActive = _appUser?.activeHouseholdId;
        final prevIds = _appUser?.householdIds ?? const <String>[];
        final activeChanged = u.activeHouseholdId != prevActive;
        final idsChanged = !_listEquals(u.householdIds, prevIds);
        _appUser = u;
        _localeCode = u.localeCode;
        if (idsChanged) {
          unawaited(_refreshMyHouseholds());
        }
        if (activeChanged) {
          await _attachHousehold(u.activeHouseholdId);
        }
        notifyListeners();
      });
      await _refreshMyHouseholds();
      await _attachHousehold(_appUser!.activeHouseholdId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _refreshMyHouseholds() async {
    final ids = _appUser?.householdIds ?? const [];
    if (ids.isEmpty) {
      _myHouseholds = [];
      notifyListeners();
      return;
    }
    try {
      final list = await _repo.fetchHouseholdsByIds(ids);
      _myHouseholds = list;
      // Drop stale ids that no longer resolve.
      if (list.length < ids.length) {
        final live = list.map((h) => h.id).toSet();
        for (final id in ids) {
          if (!live.contains(id)) {
            final uid = _firebaseUser?.uid;
            if (uid != null) {
              try {
                await _auth.removeHouseholdMembership(uid, id);
              } catch (_) {}
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _detachCurrentMonthListeners({bool clearData = true}) async {
    await _selectedMonthSub?.cancel();
    await _sourcesSub?.cancel();
    await _entriesSub?.cancel();
    await _plansSub?.cancel();
    await _expensesSub?.cancel();
    await _depositsSub?.cancel();
    await _potBalancesSub?.cancel();
    await _loanPaymentsSub?.cancel();
    _selectedMonthSub = null;
    _sourcesSub = null;
    _entriesSub = null;
    _plansSub = null;
    _expensesSub = null;
    _depositsSub = null;
    _potBalancesSub = null;
    _loanPaymentsSub = null;
    if (clearData) {
      _selectedMonth = null;
      _incomeSources = [];
      _incomeEntries = [];
      _plans = [];
      _expenses = [];
      _deposits = [];
      _potBalances = [];
      _loanPayments = [];
    }
  }

  Future<void> _detachMonthDataListeners({bool clearData = true}) async {
    await _detachCurrentMonthListeners(clearData: clearData);
  }

  Future<void> _detachBudgetListeners({bool clearData = true}) async {
    await _householdSub?.cancel();
    await _monthsSub?.cancel();
    await _categoriesSub?.cancel();
    await _subcategoriesSub?.cancel();
    await _loansSub?.cancel();
    await _billsSub?.cancel();
    await _detachMonthDataListeners(clearData: clearData);
    _householdSub = null;
    _monthsSub = null;
    _categoriesSub = null;
    _subcategoriesSub = null;
    _loansSub = null;
    _billsSub = null;
    if (clearData) {
      _household = null;
      _months = [];
      _categories = [];
      _subcategories = [];
      _loans = [];
      _recurringBills = [];
      _memberLabels = {};
      _monthId = null;
      _budgetDataReady = false;
    }
  }
  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    _detachBudgetListeners();
    super.dispose();
  }

  /// Rebinds Firestore listeners without clearing the UI loading gate.
  Future<void> refreshBudget() async {
    final hid = _activeHid;
    if (hid == null || hid.isEmpty) return;
    await _attachHousehold(hid, soft: true);
  }

  Future<void> _attachHousehold(
    String? householdId, {
    bool soft = false,
  }) async {
    await _detachBudgetListeners(clearData: !soft);
    if (householdId == null || householdId.isEmpty) {
      if (!soft) _budgetDataReady = true;
      notifyListeners();
      return;
    }

    final ready = Completer<Household?>();
    _householdSub = _repo
        .watchHousehold(householdId)
        .listen(
          (h) {
            _household = h;
            if (h != null) {
              unawaited(_refreshMemberLabels(h.memberIds));
            }
            if (!ready.isCompleted) ready.complete(h);
            if (h == null) {
              unawaited(_clearStaleHousehold());
            }
            notifyListeners();
          },
          onError: (Object e) {
            if (!ready.isCompleted) {
              ready.complete(null);
            } else {
              unawaited(_clearStaleHousehold());
            }
          },
        );

    final household = await ready.future;
    if (household == null) {
      await _clearStaleHousehold();
      if (!soft) _budgetDataReady = true;
      notifyListeners();
      return;
    }

    final categoriesReady = Completer<void>();
    final subcategoriesReady = Completer<void>();
    final monthsReady = Completer<void>();

    _categoriesSub = _repo
        .watchCategories(householdId)
        .listen(
          (v) {
            _categories = v;
            if (!categoriesReady.isCompleted) categoriesReady.complete();
            notifyListeners();
          },
          onError: (Object e) {
            _error = e.toString();
            if (!categoriesReady.isCompleted) categoriesReady.complete();
            notifyListeners();
          },
        );
    _subcategoriesSub = _repo
        .watchSubcategories(householdId)
        .listen(
          (v) {
            _subcategories = v;
            if (!subcategoriesReady.isCompleted) subcategoriesReady.complete();
            notifyListeners();
          },
          onError: (Object e) {
            _error = e.toString();
            if (!subcategoriesReady.isCompleted) subcategoriesReady.complete();
            notifyListeners();
          },
        );
    _billsSub = _repo.watchRecurringBills(householdId).listen(
      (v) {
        _recurringBills = v;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
    _loansSub = _repo.watchLoans(householdId).listen(
      (v) {
        _loans = v;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
    var isFirstMonths = true;
    _monthsSub = _repo.watchMonths(householdId).listen((list) async {
      _months = list;
      try {
        final monthIds = list.map((m) => m.id);
        if (_monthId != null && !list.any((m) => m.id == _monthId)) {
          _monthId = preferredMonthId(monthIds);
          if (_monthId != null) {
            await _listenMonthData(
              householdId,
              _monthId!,
              waitForFirst: isFirstMonths,
            );
          } else {
            await _detachMonthDataListeners();
          }
        } else if (_monthId == null && list.isNotEmpty) {
          _monthId = preferredMonthId(monthIds);
          await _listenMonthData(
            householdId,
            _monthId!,
            waitForFirst: isFirstMonths,
          );
        } else if (_monthId != null && isFirstMonths) {
          await _listenMonthData(
            householdId,
            _monthId!,
            waitForFirst: true,
          );
        } else if (_monthId != null) {
          // Keep selected month summary in sync from months list.
          for (final m in list) {
            if (m.id == _monthId) {
              _selectedMonth = m;
              break;
            }
          }
        }
      } finally {
        if (isFirstMonths) {
          isFirstMonths = false;
          if (!monthsReady.isCompleted) monthsReady.complete();
        }
        notifyListeners();
      }
    }, onError: (Object e) {
      _error = e.toString();
      if (!monthsReady.isCompleted) monthsReady.complete();
      notifyListeners();
    });

    try {
      await Future.wait([
        categoriesReady.future,
        subcategoriesReady.future,
        monthsReady.future,
      ]);
    } finally {
      if (!soft) _budgetDataReady = true;
      notifyListeners();
    }
  }

  Future<void> _clearStaleHousehold() async {
    final uid = _firebaseUser?.uid;
    final staleId = _appUser?.activeHouseholdId ?? _household?.id;
    await _householdSub?.cancel();
    _householdSub = null;
    _household = null;
    _memberLabels = {};
    if (uid != null && staleId != null) {
      try {
        await _auth.removeHouseholdMembership(uid, staleId);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _refreshMemberLabels(List<String> memberIds) async {
    final labels = await _auth.getMemberLabels(memberIds);
    _memberLabels = labels;
    notifyListeners();
  }

  Future<void> _listenMonthData(
    String hid,
    String monthId, {
    bool waitForFirst = false,
  }) async {
    await _detachCurrentMonthListeners();

    Completer<void>? monthReady;
    Completer<void>? sourcesReady;
    Completer<void>? entriesReady;
    Completer<void>? plansReady;
    Completer<void>? expensesReady;
    Completer<void>? depositsReady;
    Completer<void>? potBalancesReady;
    Completer<void>? loanPaymentsReady;
    if (waitForFirst) {
      monthReady = Completer<void>();
      sourcesReady = Completer<void>();
      entriesReady = Completer<void>();
      plansReady = Completer<void>();
      expensesReady = Completer<void>();
      depositsReady = Completer<void>();
      potBalancesReady = Completer<void>();
      loanPaymentsReady = Completer<void>();
    }

    _selectedMonthSub = _repo.watchMonth(hid, monthId).listen(
      (v) {
        _selectedMonth = v;
        if (monthReady != null && !monthReady.isCompleted) {
          monthReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (monthReady != null && !monthReady.isCompleted) {
          monthReady.complete();
        }
        notifyListeners();
      },
    );
    _sourcesSub = _repo.watchIncomeSources(hid, monthId).listen(
      (v) {
        _incomeSources = v;
        if (sourcesReady != null && !sourcesReady.isCompleted) {
          sourcesReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (sourcesReady != null && !sourcesReady.isCompleted) {
          sourcesReady.complete();
        }
        notifyListeners();
      },
    );
    _entriesSub = _repo.watchIncomeEntries(hid, monthId).listen(
      (v) {
        _incomeEntries = v;
        if (entriesReady != null && !entriesReady.isCompleted) {
          entriesReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (entriesReady != null && !entriesReady.isCompleted) {
          entriesReady.complete();
        }
        notifyListeners();
      },
    );
    _plansSub = _repo.watchPlans(hid, monthId).listen(
      (v) {
        _plans = v;
        if (plansReady != null && !plansReady.isCompleted) {
          plansReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (plansReady != null && !plansReady.isCompleted) {
          plansReady.complete();
        }
        notifyListeners();
      },
    );
    _expensesSub = _repo.watchExpenses(hid, monthId).listen(
      (v) {
        _expenses = v;
        if (expensesReady != null && !expensesReady.isCompleted) {
          expensesReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (expensesReady != null && !expensesReady.isCompleted) {
          expensesReady.complete();
        }
        notifyListeners();
      },
    );
    _depositsSub = _repo.watchDeposits(hid, monthId).listen(
      (v) {
        _deposits = v;
        if (depositsReady != null && !depositsReady.isCompleted) {
          depositsReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (depositsReady != null && !depositsReady.isCompleted) {
          depositsReady.complete();
        }
        notifyListeners();
      },
    );
    _potBalancesSub = _repo.watchPotBalances(hid, monthId).listen(
      (v) {
        _potBalances = v;
        if (potBalancesReady != null && !potBalancesReady.isCompleted) {
          potBalancesReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (potBalancesReady != null && !potBalancesReady.isCompleted) {
          potBalancesReady.complete();
        }
        notifyListeners();
      },
    );
    _loanPaymentsSub = _repo.watchLoanPayments(hid, monthId).listen(
      (v) {
        _loanPayments = v;
        if (loanPaymentsReady != null && !loanPaymentsReady.isCompleted) {
          loanPaymentsReady.complete();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        if (loanPaymentsReady != null && !loanPaymentsReady.isCompleted) {
          loanPaymentsReady.complete();
        }
        notifyListeners();
      },
    );

    if (waitForFirst) {
      await Future.wait([
        monthReady!.future,
        sourcesReady!.future,
        entriesReady!.future,
        plansReady!.future,
        expensesReady!.future,
        depositsReady!.future,
        potBalancesReady!.future,
        loanPaymentsReady!.future,
      ]);
    }
  }
  Future<void> setMonth(String monthId) async {
    final hid = _activeHid;
    if (hid == null) return;
    final exists = await _repo.monthExists(hid, monthId);
    if (!exists) {
      throw StateError('Month does not exist. Create it first.');
    }
    _monthId = monthId;
    await _listenMonthData(hid, monthId);
    notifyListeners();
  }

  Future<void> createMonth({
    required String monthId,
    String? copyFromMonthId,
    bool empty = false,
    bool rolloverLeftover = false,
    Set<String>? categoryIdsToCopy,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    if (empty) {
      await _repo.createEmptyMonth(
        householdId: hid,
        monthId: monthId,
        rolloverLeftover: rolloverLeftover,
      );
    } else {
      final copyFrom =
          copyFromMonthId ??
          _months.where((m) => m.id != monthId).firstOrNull?.id;
      if (copyFrom != null && copyFrom.isNotEmpty) {
        await _repo.createMonthFromCopy(
          householdId: hid,
          fromMonthId: copyFrom,
          toMonthId: monthId,
          rolloverLeftover: rolloverLeftover,
          categoryIds: categoryIdsToCopy,
        );
      } else {
        await _repo.createEmptyMonth(
          householdId: hid,
          monthId: monthId,
          rolloverLeftover: rolloverLeftover,
        );
      }
    }
    await setMonth(monthId);
  }

  Future<void> setLocale(String code) async {
    _localeCode = code;
    notifyListeners();
    final uid = _firebaseUser?.uid;
    if (uid != null) {
      await _auth.updateLocale(uid, code);
    }
  }

  Future<void> createHousehold(String name) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    final h = await _repo.createHousehold(
      name: name,
      creatorUid: uid,
      creatorName: currentDisplayName,
    );
    final ids = [...?_appUser?.householdIds];
    if (!ids.contains(h.id)) ids.add(h.id);
    _appUser = _appUser?.copyWith(
      householdIds: ids,
      activeHouseholdId: h.id,
    );
    await _refreshMyHouseholds();
    await _attachHousehold(h.id);
  }

  Future<void> updateHouseholdName(String name) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateHouseholdName(householdId: hid, name: name);
    await _refreshMyHouseholds();
  }

  Future<void> joinHousehold(String inviteCode) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    final h = await _repo.joinHousehold(
      inviteCode: inviteCode,
      uid: uid,
      displayName: currentDisplayName,
    );
    final ids = [...?_appUser?.householdIds];
    if (!ids.contains(h.id)) ids.add(h.id);
    _appUser = _appUser?.copyWith(
      householdIds: ids,
      activeHouseholdId: h.id,
    );
    await _refreshMyHouseholds();
    await _attachHousehold(h.id);
  }

  Future<void> switchHousehold(String householdId) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    if (_appUser?.activeHouseholdId == householdId &&
        _household?.id == householdId) {
      return;
    }
    if (!(_appUser?.householdIds.contains(householdId) ?? false)) {
      throw StateError('Not a member of this household');
    }
    await _auth.setActiveHouseholdId(uid, householdId);
    _appUser = _appUser?.copyWith(activeHouseholdId: householdId);
    await _attachHousehold(householdId);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> deleteHousehold() async {
    final uid = _firebaseUser?.uid;
    final household = _household;
    if (uid == null || household == null) throw StateError('No household');
    if (!household.isOwnedBy(uid)) {
      throw StateError('Only the owner can delete the household');
    }
    final deletedId = household.id;
    await _detachBudgetListeners();
    try {
      await _repo.deleteHousehold(householdId: deletedId, ownerUid: uid);
    } catch (e) {
      await _attachHousehold(deletedId);
      rethrow;
    }
    final remaining =
        (_appUser?.householdIds ?? const []).where((id) => id != deletedId).toList();
    _appUser = _appUser?.copyWith(
      householdIds: remaining,
      activeHouseholdId: remaining.isEmpty ? null : remaining.first,
      clearActiveHouseholdId: remaining.isEmpty,
    );
    await _refreshMyHouseholds();
    if (remaining.isEmpty) {
      _household = null;
      notifyListeners();
    } else {
      await _attachHousehold(remaining.first);
    }
  }

  Future<void> leaveHousehold() async {
    final uid = _firebaseUser?.uid;
    final household = _household;
    if (uid == null || household == null) throw StateError('No household');
    if (household.isOwnedBy(uid)) {
      throw StateError('owner-must-delete');
    }
    final leftId = household.id;
    await _repo.leaveHousehold(householdId: leftId, uid: uid);
    final remaining =
        (_appUser?.householdIds ?? const []).where((id) => id != leftId).toList();
    _appUser = _appUser?.copyWith(
      householdIds: remaining,
      activeHouseholdId: remaining.isEmpty ? null : remaining.first,
      clearActiveHouseholdId: remaining.isEmpty,
    );
    await _refreshMyHouseholds();
    if (remaining.isEmpty) {
      await _detachBudgetListeners();
      notifyListeners();
    } else {
      await _attachHousehold(remaining.first);
    }
  }

  Future<void> removeMember(String memberUid) async {
    final hid = _household?.id;
    if (hid == null) throw StateError('No household');
    if (!isHouseholdOwner) throw StateError('Only the owner can remove members');
    if (memberUid == _firebaseUser?.uid) {
      throw StateError('Use leave household');
    }
    await _repo.removeMember(householdId: hid, memberUid: memberUid);
  }

  Future<void> setMemberRole(String memberUid, String role) async {
    final hid = _household?.id;
    if (hid == null) throw StateError('No household');
    if (!isHouseholdOwner) throw StateError('Only the owner can change roles');
    await _repo.setMemberRole(
      householdId: hid,
      memberUid: memberUid,
      role: role,
    );
  }

  Future<void> addRecurringBill({
    required String name,
    required double amount,
    required int dayOfMonth,
    String? subcategoryId,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.addRecurringBill(
      householdId: hid,
      name: name,
      amount: amount,
      dayOfMonth: dayOfMonth,
      subcategoryId: subcategoryId,
    );
  }

  Future<void> deleteRecurringBill(String billId) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.deleteRecurringBill(householdId: hid, billId: billId);
  }

  Future<void> deleteAccount({String? password}) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    for (final h in _myHouseholds) {
      if (h.isOwnedBy(uid)) {
        throw StateError('must-delete-household-first');
      }
    }
    final ids = List<String>.from(_appUser?.householdIds ?? const []);
    for (final hid in ids) {
      try {
        await _repo.leaveHousehold(householdId: hid, uid: uid);
      } catch (_) {}
    }
    await _detachBudgetListeners();
    _household = null;
    _myHouseholds = [];
    await _auth.deleteUserDoc(uid);
    await _auth.deleteAuthUser(password: password);
  }

  Future<String> duplicateCurrentMonth() async {
    final hid = _activeHid;
    final from = _monthId;
    if (hid == null || from == null) throw StateError('No month selected');
    final next = await _repo.duplicateMonth(
      householdId: hid,
      fromMonthId: from,
    );
    await setMonth(next);
    return next;
  }

  Future<String> addCategory({
    required String name,
    required int colorValue,
    required String iconKey,
    required String type,
    String? nameEn,
    String? nameRu,
    double? targetAmount,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    final trimmed = name.trim();
    final en = (nameEn ?? trimmed).trim();
    final ru = (nameRu ?? trimmed).trim();
    if (type == 'savings') {
      if (en.toLowerCase() == DefaultCategories.savingsNameEn.toLowerCase()) {
        return ensureSavingsCategory();
      }
      return addPot(
        name: trimmed,
        nameEn: en,
        nameRu: ru,
        targetAmount: targetAmount,
      );
    }
    final id = await _repo.addCategory(
      householdId: hid,
      nameEn: en,
      nameRu: ru,
      colorValue: colorValue,
      iconKey: iconKey,
      type: type,
      sortOrder: _categories.length,
      targetAmount: targetAmount,
    );
    if (!_categories.any((c) => c.id == id)) {
      _categories = [
        ..._categories,
        BudgetCategory(
          id: id,
          nameEn: en,
          nameRu: ru,
          colorValue: colorValue,
          iconKey: iconKey,
          type: type,
          sortOrder: _categories.length,
          targetAmount: targetAmount,
        ),
      ];
      notifyListeners();
    }
    return id;
  }

  Future<String?> addSuggestedCategory(DefaultCategory suggested) async {
    if (suggested.type == 'savings') {
      return ensureSavingsCategory();
    }
    for (final c in _categories) {
      if (c.nameEn.toLowerCase() == suggested.nameEn.toLowerCase()) {
        return c.id;
      }
    }
    return addCategory(
      name: suggested.nameEn,
      nameEn: suggested.nameEn,
      nameRu: suggested.nameRu,
      colorValue: suggested.colorValue,
      iconKey: suggested.iconKey,
      type: suggested.type,
    );
  }

  Future<String> ensureSavingsCategory() async {
    final existing = savingsCategory;
    if (existing != null) return existing.id;
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    final id = await _repo.addCategory(
      householdId: hid,
      nameEn: DefaultCategories.savingsNameEn,
      nameRu: DefaultCategories.savingsNameRu,
      colorValue: DefaultCategories.savingsColorValue,
      iconKey: DefaultCategories.savingsIconKey,
      type: 'savings',
      sortOrder: _categories.length,
    );
    if (!_categories.any((c) => c.id == id)) {
      _categories = [
        ..._categories,
        BudgetCategory(
          id: id,
          nameEn: DefaultCategories.savingsNameEn,
          nameRu: DefaultCategories.savingsNameRu,
          colorValue: DefaultCategories.savingsColorValue,
          iconKey: DefaultCategories.savingsIconKey,
          type: 'savings',
          sortOrder: _categories.length,
        ),
      ];
      notifyListeners();
    }
    return id;
  }

  Future<String> addPot({
    required String name,
    String? nameEn,
    String? nameRu,
    double? targetAmount,
    DateTime? targetDate,
    bool includeInTotal = true,
    double planned = 0,
    double priorSaved = 0,
  }) async {
    final catId = await ensureSavingsCategory();
    final trimmed = name.trim();
    final en = (nameEn ?? trimmed).trim();
    final ru = (nameRu ?? trimmed).trim();
    for (final s in subcategoriesFor(catId)) {
      if (s.nameEn.toLowerCase() == en.toLowerCase()) return s.id;
    }
    return addSubcategory(
      categoryId: catId,
      name: trimmed,
      nameEn: en,
      nameRu: ru,
      targetAmount: targetAmount,
      targetDate: targetDate,
      includeInTotal: includeInTotal,
      planned: planned,
      priorSaved: priorSaved,
    );
  }

  Future<String> addSuggestedPot(DefaultPot pot) async {
    return addPot(name: pot.nameEn, nameEn: pot.nameEn, nameRu: pot.nameRu);
  }

  Future<String> ensureLeftoverPot() async {
    if (_activeHid == null) return '';
    for (final pot in savingsPots) {
      if (DefaultPots.isLeftoverName(pot.nameEn)) return pot.id;
    }
    final hid = _activeHid!;
    return _repo.ensureLeftoverPot(hid);
  }

  Future<int> addDefaultCategories() async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    return _repo.addDefaultCategories(householdId: hid);
  }

  Future<void> updateCategory(BudgetCategory category) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateCategory(householdId: hid, category: category);
  }

  Future<void> deleteCategory(String categoryId) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.deleteCategory(householdId: hid, categoryId: categoryId);
  }

  Future<String> addSubcategory({
    required String categoryId,
    required String name,
    String? nameEn,
    String? nameRu,
    double planned = 0,
    double? targetAmount,
    DateTime? targetDate,
    bool includeInTotal = true,
    double priorSaved = 0,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    final trimmed = name.trim();
    final en = (nameEn ?? trimmed).trim();
    final ru = (nameRu ?? trimmed).trim();
    final id = await _repo.addSubcategory(
      householdId: hid,
      categoryId: categoryId,
      nameEn: en,
      nameRu: ru,
      sortOrder: _subcategories.length,
      targetAmount: targetAmount,
      targetDate: targetDate,
      includeInTotal: includeInTotal,
      monthId: _monthId,
    );
    if (!_subcategories.any((s) => s.id == id)) {
      _subcategories = [
        ..._subcategories,
        Subcategory(
          id: id,
          categoryId: categoryId,
          nameEn: en,
          nameRu: ru,
          sortOrder: _subcategories.length,
          targetAmount: targetAmount,
          targetDate: targetDate,
          includeInTotal: includeInTotal,
        ),
      ];
    }
    if (_monthId != null && planned > 0) {
      final plan = MonthPlan(subcategoryId: id, planned: planned);
      await _repo.upsertPlan(
        householdId: hid,
        monthId: _monthId!,
        plan: plan,
      );
      final planIdx = _plans.indexWhere((p) => p.subcategoryId == id);
      if (planIdx < 0) {
        _plans = [..._plans, plan];
      } else {
        _plans = [
          ..._plans.sublist(0, planIdx),
          plan,
          ..._plans.sublist(planIdx + 1),
        ];
      }
    }
    if (_monthId != null && priorSaved > 0 && _isSavingsPot(id)) {
      await _repo.setPotOpeningBalance(
        householdId: hid,
        monthId: _monthId!,
        subcategoryId: id,
        openingBalance: priorSaved,
        includeInTotal: includeInTotal,
      );
    }
    notifyListeners();
    return id;
  }

  Future<void> updateSubcategory(Subcategory subcategory) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateSubcategory(householdId: hid, subcategory: subcategory);
  }

  Future<void> removeSubcategoryFromMonth(String subcategoryId) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.deletePlan(
      householdId: hid,
      monthId: mid,
      subcategoryId: subcategoryId,
    );
    _plans = _plans.where((p) => p.subcategoryId != subcategoryId).toList();
    notifyListeners();
  }

  Future<void> deleteSubcategory(String subcategoryId) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.deleteSubcategory(
      householdId: hid,
      subcategoryId: subcategoryId,
    );
  }

  Future<void> upsertPlan({
    required String subcategoryId,
    required double planned,
    String? nameEn,
    String? nameRu,
    bool clearNameEn = false,
    bool clearNameRu = false,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    final existing = planFor(subcategoryId);
    final plan = MonthPlan(
      subcategoryId: subcategoryId,
      planned: planned,
      nameEn: clearNameEn ? null : (nameEn ?? existing?.nameEn),
      nameRu: clearNameRu ? null : (nameRu ?? existing?.nameRu),
    );
    await _repo.upsertPlan(
      householdId: hid,
      monthId: mid,
      plan: plan,
      clearNameEn: clearNameEn,
      clearNameRu: clearNameRu,
    );
    final planIdx = _plans.indexWhere((p) => p.subcategoryId == subcategoryId);
    if (planIdx < 0) {
      _plans = [..._plans, plan];
    } else {
      _plans = [
        ..._plans.sublist(0, planIdx),
        plan,
        ..._plans.sublist(planIdx + 1),
      ];
    }
    notifyListeners();
  }

  Future<void> addExpense({
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.addExpense(
      householdId: hid,
      monthId: mid,
      subcategoryId: subcategoryId,
      amount: amount,
      date: date,
      note: note,
      createdBy: currentUid,
      createdByName: currentDisplayName,
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
    await _repo.addIncomeEntry(
      householdId: hid,
      monthId: mid,
      sourceId: sourceId,
      amount: amount,
      note: note,
      createdBy: currentUid,
      createdByName: currentDisplayName,
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
    await _repo.addDeposit(
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
    await _repo.deleteExpense(
      householdId: hid,
      monthId: mid,
      expense: old,
    );
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
    await _repo.deleteIncomeEntry(
      householdId: hid,
      monthId: mid,
      entry: old,
    );
  }

  Future<String> addLoan({
    required String name,
    required String type,
    required double originalAmount,
    double? remainingBalance,
    double? monthlyPayment,
    int? totalInstallments,
    int? paidInstallments,
    int? dueDayOfMonth,
    double? interestRate,
    String? note,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    final remaining = remainingBalance ?? originalAmount;
    final paid = type == 'installment'
        ? (paidInstallments ?? 0).clamp(0, totalInstallments ?? 999999)
        : 0;
    final loan = Loan(
      id: '',
      name: name.trim(),
      type: type,
      originalAmount: originalAmount,
      remainingBalance: remaining,
      monthlyPayment: monthlyPayment,
      totalInstallments: totalInstallments,
      paidInstallments: paid,
      dueDayOfMonth: dueDayOfMonth,
      interestRate: interestRate,
      note: note,
      sortOrder: _loans.length,
      status: remaining <= 0 ? 'paidOff' : 'active',
    );
    return _repo.addLoan(householdId: hid, loan: loan);
  }

  Future<void> updateLoan(Loan loan) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateLoan(householdId: hid, loan: loan);
  }

  Future<void> deleteLoan(String loanId) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.deleteLoan(householdId: hid, loanId: loanId);
  }

  Future<void> addLoanPayment({
    required String loanId,
    required double amount,
    required DateTime date,
    String? note,
    bool reducesBalance = true,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.addLoanPayment(
      householdId: hid,
      monthId: mid,
      loanId: loanId,
      amount: amount,
      date: date,
      note: note,
      reducesBalance: reducesBalance,
      createdBy: currentUid,
      createdByName: currentDisplayName,
    );
  }

  Future<void> deleteLoanPayment(String paymentId) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    LoanPayment? old;
    for (final p in _loanPayments) {
      if (p.id == paymentId) {
        old = p;
        break;
      }
    }
    if (old == null) return;
    await _repo.deleteLoanPayment(
      householdId: hid,
      monthId: mid,
      payment: old,
    );
  }
}
