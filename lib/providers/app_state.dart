import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';
import '../data/default_categories.dart';
import '../utils/leftover.dart';
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
  String _localeCode = 'en';
  bool _loading = true;
  String? _error;

  List<BudgetMonth> _months = [];
  List<IncomeSource> _incomeSources = [];
  List<IncomeEntry> _incomeEntries = [];
  List<BudgetCategory> _categories = [];
  List<Subcategory> _subcategories = [];
  List<MonthPlan> _plans = [];
  List<Expense> _expenses = [];

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;
  StreamSubscription<Household?>? _householdSub;
  StreamSubscription<List<BudgetMonth>>? _monthsSub;
  StreamSubscription<List<BudgetCategory>>? _categoriesSub;
  StreamSubscription<List<Subcategory>>? _subcategoriesSub;
  StreamSubscription<List<IncomeSource>>? _sourcesSub;
  StreamSubscription<List<IncomeEntry>>? _entriesSub;
  StreamSubscription<List<MonthPlan>>? _plansSub;
  StreamSubscription<List<Expense>>? _expensesSub;
  final List<StreamSubscription<dynamic>> _priorMonthSubs = [];

  final Map<String, List<Expense>> _priorExpensesByMonth = {};
  final Map<String, List<IncomeEntry>> _priorIncomeByMonth = {};
  /// Prior month ids included in leftover (sorted ascending).
  List<String> _priorMonthIds = [];

  bool get loading => _loading;
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

  List<IncomeSource> get incomeSources => _incomeSources;
  List<IncomeEntry> get incomeEntries => _incomeEntries;
  List<BudgetCategory> get categories => _categories;
  List<Subcategory> get subcategories =>
      _subcategories.where((s) => !s.archived).toList();
  List<MonthPlan> get plans => _plans;
  List<Expense> get expenses => _expenses;

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

  /// Most recent prior month included in leftover (for period label).
  String? get leftoverSourceMonthId =>
      _priorMonthIds.isEmpty ? null : _priorMonthIds.last;

  /// Cumulative cash left from all months before the selected one:
  /// Σ (income − spent), using the same spent rules as Home.
  double get leftoverFromPreviousMonth {
    if (_priorMonthIds.isEmpty) return 0;
    var income = 0.0;
    for (final id in _priorMonthIds) {
      for (final e in _priorIncomeByMonth[id] ?? const <IncomeEntry>[]) {
        income += e.amount;
      }
    }
    final leftoverId = leftoverPotId;
    final liveSubIds = subcategories.map((s) => s.id).toSet();
    final expenses = <Expense>[
      for (final id in _priorMonthIds)
        for (final e in _priorExpensesByMonth[id] ?? const <Expense>[])
          if (e.subcategoryId != leftoverId &&
              (liveSubIds.isEmpty || liveSubIds.contains(e.subcategoryId)))
            e,
    ];
    return computeUnspentLeftover(income: income, expenses: expenses);
  }

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
    for (final monthId in monthIds) {
      final expenses = await _repo.fetchExpenses(hid, monthId);
      final plans = await _repo.fetchPlans(hid, monthId);
      final incomeEntries = await _repo.fetchIncomeEntries(hid, monthId);
      result[monthId] = MonthStatsSnapshot(
        monthId: monthId,
        expenses: expenses,
        plans: plans,
        income: incomeEntries.fold<double>(0, (s, e) => s + e.amount),
      );
    }
    return result;
  }

  MonthTotals get totals {
    final income = _incomeEntries.fold<double>(0, (s, e) => s + e.amount);
    final liveSubIds = subcategories.map((s) => s.id).toSet();
    final leftoverId = leftoverPotId;
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
    final savedThisMonth = _expenses
        .where(
          (e) =>
              liveSubIds.contains(e.subcategoryId) &&
              (e.isDeposit || _isSavingsPot(e.subcategoryId)),
        )
        .fold<double>(0, (s, e) => s + e.amount);
    return MonthTotals(
      income: income,
      planned: planned,
      actual: actual,
      savedThisMonth: savedThisMonth,
    );
  }

  bool isDepositExpense(Expense e) =>
      e.isDeposit || _isSavingsPot(e.subcategoryId);

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

  List<Expense> expensesFor(String subcategoryId) {
    final list = _expenses
        .where((e) => e.subcategoryId == subcategoryId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double categoryPlanned(String categoryId) =>
      subcategoriesFor(categoryId).fold(0, (s, sub) => s + plannedFor(sub.id));

  double categoryActual(String categoryId) =>
      subcategoriesFor(categoryId).fold(0, (s, sub) => s + spentFor(sub.id));

  List<Expense> expensesForCategory(String categoryId) {
    final subIds = subcategoriesFor(categoryId).map((s) => s.id).toSet();
    final list = _expenses
        .where((e) => subIds.contains(e.subcategoryId))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  String? _savingsCategoryIdForSub(String subcategoryId) {
    final sub = subcategoryById(subcategoryId);
    if (sub == null) return null;
    final cat = categoryById(sub.categoryId);
    if (cat == null || !cat.isSavings) return null;
    return cat.id;
  }

  bool _isSavingsPot(String subcategoryId) {
    return _savingsCategoryIdForSub(subcategoryId) != null;
  }

  Future<void> _adjustSavedTotal({
    required String subcategoryId,
    required double delta,
  }) async {
    if (delta == 0) return;
    if (!_isSavingsPot(subcategoryId)) return;
    final hid = _activeHid;
    if (hid == null) return;
    await _repo.incrementSavedTotal(
      householdId: hid,
      subcategoryId: subcategoryId,
      delta: delta,
    );
  }

  String? installmentHint(Subcategory sub) {
    final current = planFor(sub.id)?.installmentCurrent;
    final total = sub.installmentTotal;
    if (current == null || total == null) return null;
    return '$current/$total';
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

  Future<void> _detachPriorMonthsListeners() async {
    for (final sub in _priorMonthSubs) {
      await sub.cancel();
    }
    _priorMonthSubs.clear();
  }

  int _priorListenGeneration = 0;

  Future<void> _detachCurrentMonthListeners() async {
    await _sourcesSub?.cancel();
    await _entriesSub?.cancel();
    await _plansSub?.cancel();
    await _expensesSub?.cancel();
    _sourcesSub = null;
    _entriesSub = null;
    _plansSub = null;
    _expensesSub = null;
    _incomeSources = [];
    _incomeEntries = [];
    _plans = [];
    _expenses = [];
  }

  Future<void> _detachMonthDataListeners() async {
    await _detachCurrentMonthListeners();
    await _detachPriorMonthsListeners();
    _priorExpensesByMonth.clear();
    _priorIncomeByMonth.clear();
    _priorMonthIds = [];
  }

  Future<List<String>> _priorMonthIdsFor(
    String hid,
    String currentMonthId,
  ) async {
    final fromList = _months
        .map((m) => m.id)
        .where((id) => id.compareTo(currentMonthId) < 0)
        .toSet();
    final prevId = previousMonthId(currentMonthId);
    if (!fromList.contains(prevId)) {
      try {
        if (await _repo.monthExists(hid, prevId)) {
          fromList.add(prevId);
        }
      } catch (_) {}
    }
    final ids = fromList.toList()..sort();
    return ids;
  }

  Future<void> _listenPriorMonthsData(String hid, String currentMonthId) async {
    final generation = ++_priorListenGeneration;
    final priorIds = await _priorMonthIdsFor(hid, currentMonthId);
    if (generation != _priorListenGeneration) return;

    if (priorIds.isEmpty) {
      await _detachPriorMonthsListeners();
      _priorExpensesByMonth.clear();
      _priorIncomeByMonth.clear();
      _priorMonthIds = [];
      notifyListeners();
      return;
    }

    if (_listEquals(priorIds, _priorMonthIds) && _priorMonthSubs.isNotEmpty) {
      return;
    }

    final incomeByMonth = <String, List<IncomeEntry>>{};
    final expensesByMonth = <String, List<Expense>>{};
    try {
      for (final id in priorIds) {
        if (generation != _priorListenGeneration) return;
        incomeByMonth[id] = await _repo.fetchIncomeEntries(hid, id);
        expensesByMonth[id] = await _repo.fetchExpenses(hid, id);
      }
    } catch (e) {
      if (generation != _priorListenGeneration) return;
      _error = e.toString();
      notifyListeners();
      return;
    }
    if (generation != _priorListenGeneration) return;

    await _detachPriorMonthsListeners();
    if (generation != _priorListenGeneration) return;

    _priorMonthIds = priorIds;
    _priorIncomeByMonth
      ..clear()
      ..addAll(incomeByMonth);
    _priorExpensesByMonth
      ..clear()
      ..addAll(expensesByMonth);
    notifyListeners();

    for (final id in priorIds) {
      if (generation != _priorListenGeneration) return;
      _priorMonthSubs.add(
        _repo.watchIncomeEntries(hid, id).listen((v) {
          if (generation != _priorListenGeneration) return;
          if (v.isEmpty && (_priorIncomeByMonth[id]?.isNotEmpty ?? false)) {
            return;
          }
          _priorIncomeByMonth[id] = v;
          notifyListeners();
        }),
      );
      _priorMonthSubs.add(
        _repo.watchExpenses(hid, id).listen((v) {
          if (generation != _priorListenGeneration) return;
          if (v.isEmpty && (_priorExpensesByMonth[id]?.isNotEmpty ?? false)) {
            return;
          }
          _priorExpensesByMonth[id] = v;
          notifyListeners();
        }),
      );
    }
  }

  Future<void> _detachBudgetListeners() async {
    await _householdSub?.cancel();
    await _monthsSub?.cancel();
    await _categoriesSub?.cancel();
    await _subcategoriesSub?.cancel();
    await _billsSub?.cancel();
    await _detachMonthDataListeners();
    _householdSub = null;
    _monthsSub = null;
    _categoriesSub = null;
    _subcategoriesSub = null;
    _billsSub = null;
    _household = null;
    _months = [];
    _categories = [];
    _subcategories = [];
    _recurringBills = [];
    _memberLabels = {};
    _monthId = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    _detachBudgetListeners();
    super.dispose();
  }

  Future<void> _attachHousehold(String? householdId) async {
    await _detachBudgetListeners();
    if (householdId == null || householdId.isEmpty) {
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
      return;
    }

    _categoriesSub = _repo
        .watchCategories(householdId)
        .listen(
          (v) {
            _categories = v;
            notifyListeners();
          },
          onError: (Object e) {
            _error = e.toString();
            notifyListeners();
          },
        );
    _subcategoriesSub = _repo
        .watchSubcategories(householdId)
        .listen(
          (v) {
            _subcategories = v;
            notifyListeners();
          },
          onError: (Object e) {
            _error = e.toString();
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
    _monthsSub = _repo.watchMonths(householdId).listen((list) async {
      _months = list;
      final monthIds = list.map((m) => m.id);
      if (_monthId != null && !list.any((m) => m.id == _monthId)) {
        _monthId = preferredMonthId(monthIds);
        if (_monthId != null) {
          await _listenMonthData(householdId, _monthId!);
        } else {
          await _detachMonthDataListeners();
        }
      } else if (_monthId == null && list.isNotEmpty) {
        _monthId = preferredMonthId(monthIds);
        await _listenMonthData(householdId, _monthId!);
      } else if (_monthId != null) {
        final nextPrior = list
            .map((m) => m.id)
            .where((id) => id.compareTo(_monthId!) < 0)
            .toList()
          ..sort();
        if (!_listEquals(nextPrior, _priorMonthIds)) {
          await _listenPriorMonthsData(householdId, _monthId!);
        }
      }
      notifyListeners();
    });
    notifyListeners();
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

  Future<void> _listenMonthData(String hid, String monthId) async {
    await _detachCurrentMonthListeners();
    _sourcesSub = _repo.watchIncomeSources(hid, monthId).listen((v) {
      _incomeSources = v;
      notifyListeners();
    });
    _entriesSub = _repo.watchIncomeEntries(hid, monthId).listen((v) {
      _incomeEntries = v;
      notifyListeners();
    });
    _plansSub = _repo.watchPlans(hid, monthId).listen((v) {
      _plans = v;
      notifyListeners();
    });
    _expensesSub = _repo.watchExpenses(hid, monthId).listen((v) {
      _expenses = v;
      notifyListeners();
    });

    await _listenPriorMonthsData(hid, monthId);
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
      await _repo.createEmptyMonth(householdId: hid, monthId: monthId);
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
        await _repo.createEmptyMonth(householdId: hid, monthId: monthId);
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

  /// Ensures the default Leftover pot exists under Savings (Set aside).
  Future<String?> ensureLeftoverPot() async {
    if (_activeHid == null) return null;
    for (final pot in savingsPots) {
      if (DefaultPots.isLeftoverName(pot.nameEn)) return pot.id;
    }
    return addPot(
      name: DefaultPots.leftoverNameEn,
      nameEn: DefaultPots.leftoverNameEn,
      nameRu: DefaultPots.leftoverNameRu,
    );
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
    int? installmentCurrent,
    int? installmentTotal,
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
    final initialSaved = priorSaved > 0 ? priorSaved : 0.0;
    final id = await _repo.addSubcategory(
      householdId: hid,
      categoryId: categoryId,
      nameEn: en,
      nameRu: ru,
      sortOrder: _subcategories.length,
      installmentTotal: installmentTotal,
      targetAmount: targetAmount,
      targetDate: targetDate,
      includeInTotal: includeInTotal,
      savedTotal: initialSaved,
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
          installmentTotal: installmentTotal,
          targetAmount: targetAmount,
          targetDate: targetDate,
          includeInTotal: includeInTotal,
          savedTotal: initialSaved,
        ),
      ];
    }
    if (_monthId != null && (planned > 0 || installmentCurrent != null)) {
      final plan = MonthPlan(
        subcategoryId: id,
        planned: planned,
        installmentCurrent: installmentCurrent,
      );
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
    notifyListeners();
    return id;
  }

  Future<void> updateSubcategory(Subcategory subcategory) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateSubcategory(householdId: hid, subcategory: subcategory);
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
    int? installmentCurrent,
    bool clearInstallmentCurrent = false,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.upsertPlan(
      householdId: hid,
      monthId: mid,
      plan: MonthPlan(
        subcategoryId: subcategoryId,
        planned: planned,
        installmentCurrent: clearInstallmentCurrent ? null : installmentCurrent,
      ),
    );
  }

  Future<void> addExpense({
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
    bool isDeposit = false,
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
      isDeposit: isDeposit,
    );
    await _adjustSavedTotal(subcategoryId: subcategoryId, delta: amount);
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
    await addExpense(
      subcategoryId: subcategoryId,
      amount: amount,
      date: date,
      note: note,
      isDeposit: true,
    );
  }

  /// Increases lifetime saved total without a month deposit/expense.
  Future<void> addPriorSavings({
    required String subcategoryId,
    required double amount,
  }) async {
    if (amount <= 0) return;
    await _adjustSavedTotal(subcategoryId: subcategoryId, delta: amount);
  }

  /// Sets the non-deposit (prior) portion of [savedTotal] for a pot.
  /// This month's deposits are left unchanged.
  Future<void> setPriorSavings({
    required String subcategoryId,
    required double amount,
  }) async {
    final pot = subcategoryById(subcategoryId);
    if (pot == null || !_isSavingsPot(subcategoryId)) return;
    final monthDeposits = expensesFor(subcategoryId)
        .fold<double>(0, (s, e) => s + e.amount);
    final currentPrior = pot.savedTotal - monthDeposits;
    final newPrior = amount < 0 ? 0.0 : amount;
    await _adjustSavedTotal(
      subcategoryId: subcategoryId,
      delta: newPrior - currentPrior,
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
    await _repo.updateExpense(householdId: hid, monthId: mid, expense: expense);
    if (old != null) {
      if (old.subcategoryId == expense.subcategoryId) {
        await _adjustSavedTotal(
          subcategoryId: expense.subcategoryId,
          delta: expense.amount - old.amount,
        );
      } else {
        await _adjustSavedTotal(
          subcategoryId: old.subcategoryId,
          delta: -old.amount,
        );
        await _adjustSavedTotal(
          subcategoryId: expense.subcategoryId,
          delta: expense.amount,
        );
      }
    } else {
      await _adjustSavedTotal(
        subcategoryId: expense.subcategoryId,
        delta: expense.amount,
      );
    }
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
    await _repo.deleteExpense(
      householdId: hid,
      monthId: mid,
      expenseId: expenseId,
    );
    if (old != null) {
      await _adjustSavedTotal(
        subcategoryId: old.subcategoryId,
        delta: -old.amount,
      );
    }
  }
}
