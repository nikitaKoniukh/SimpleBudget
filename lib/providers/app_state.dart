import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';
import '../data/default_categories.dart';

class AppState extends ChangeNotifier {
  AppState({
    AuthService? authService,
    BudgetRepository? budgetRepository,
  })  : _auth = authService ?? AuthService(),
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

  bool get loading => _loading;
  String? get error => _error;
  AppUser? get appUser => _appUser;
  Household? get household => _household;
  String? get monthId => _monthId;
  String get localeCode => _localeCode;
  bool get isSignedIn => _firebaseUser != null;
  bool get hasHousehold => _household != null;
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

  MonthTotals get totals {
    final income = _incomeEntries.fold<double>(0, (s, e) => s + e.amount);
    final liveSubIds = subcategories.map((s) => s.id).toSet();
    final planned = _plans
        .where((p) => liveSubIds.contains(p.subcategoryId))
        .fold<double>(0, (s, p) => s + p.planned);
    final actual = _expenses
        .where((e) => liveSubIds.contains(e.subcategoryId))
        .fold<double>(0, (s, e) => s + e.amount);
    return MonthTotals(income: income, planned: planned, actual: actual);
  }

  List<Subcategory> subcategoriesFor(String categoryId) => subcategories
      .where((s) => s.categoryId == categoryId)
      .toList();

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
    final list =
        _expenses.where((e) => e.subcategoryId == subcategoryId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double categoryPlanned(String categoryId) => subcategoriesFor(categoryId)
      .fold(0, (s, sub) => s + plannedFor(sub.id));

  double categoryActual(String categoryId) =>
      subcategoriesFor(categoryId).fold(0, (s, sub) => s + spentFor(sub.id));

  List<Expense> expensesForCategory(String categoryId) {
    final subIds = subcategoriesFor(categoryId).map((s) => s.id).toSet();
    final list =
        _expenses.where((e) => subIds.contains(e.subcategoryId)).toList();
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

  Future<void> _adjustSavedTotal({
    required String subcategoryId,
    required double delta,
  }) async {
    if (delta == 0) return;
    final catId = _savingsCategoryIdForSub(subcategoryId);
    if (catId == null) return;
    final hid = _appUser?.householdId;
    if (hid == null) return;
    await _repo.incrementSavedTotal(
      householdId: hid,
      categoryId: catId,
      delta: delta,
    );
  }

  /// Returns an existing subcategory for [categoryId], creating one if needed.
  Future<String> ensureImplicitSubcategory(String categoryId) async {
    final existing = subcategoriesFor(categoryId);
    if (existing.isNotEmpty) return existing.first.id;
    final cat = categoryById(categoryId);
    if (cat == null) throw StateError('Category not found');
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    return _repo.ensureImplicitSubcategory(
      householdId: hid,
      categoryId: categoryId,
      nameEn: cat.nameEn,
      nameRu: cat.nameRu,
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

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    await _userSub?.cancel();
    _userSub = null;
    await _detachBudgetListeners();
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
        final householdChanged = u.householdId != _appUser?.householdId;
        _appUser = u;
        _localeCode = u.localeCode;
        if (householdChanged) {
          await _attachHousehold(u.householdId);
        }
        notifyListeners();
      });
      await _attachHousehold(_appUser!.householdId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _detachMonthDataListeners() async {
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

  Future<void> _detachBudgetListeners() async {
    await _householdSub?.cancel();
    await _monthsSub?.cancel();
    await _categoriesSub?.cancel();
    await _subcategoriesSub?.cancel();
    await _detachMonthDataListeners();
    _householdSub = null;
    _monthsSub = null;
    _categoriesSub = null;
    _subcategoriesSub = null;
    _household = null;
    _months = [];
    _categories = [];
    _subcategories = [];
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
    _householdSub = _repo.watchHousehold(householdId).listen(
      (h) {
        _household = h;
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

    unawaited(_repo.migrateLegacyCatalogIfNeeded(householdId));
    _categoriesSub = _repo.watchCategories(householdId).listen(
      (v) {
        _categories = v;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
    _subcategoriesSub = _repo.watchSubcategories(householdId).listen(
      (v) {
        _subcategories = v;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
    _monthsSub = _repo.watchMonths(householdId).listen((list) async {
      _months = list;
      if (_monthId != null && !list.any((m) => m.id == _monthId)) {
        _monthId = list.isNotEmpty ? list.first.id : null;
        if (_monthId != null) {
          await _listenMonthData(householdId, _monthId!);
        } else {
          await _detachMonthDataListeners();
        }
      } else if (_monthId == null && list.isNotEmpty) {
        _monthId = list.first.id;
        await _listenMonthData(householdId, _monthId!);
      }
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _clearStaleHousehold() async {
    final uid = _firebaseUser?.uid;
    await _householdSub?.cancel();
    _householdSub = null;
    _household = null;
    if (_appUser != null) {
      _appUser = AppUser(
        id: _appUser!.id,
        email: _appUser!.email,
        displayName: _appUser!.displayName,
        localeCode: _appUser!.localeCode,
      );
    }
    if (uid != null) {
      try {
        await _auth.clearHouseholdId(uid);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _listenMonthData(String hid, String monthId) async {
    await _detachMonthDataListeners();
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
  }

  Future<void> setMonth(String monthId) async {
    final hid = _appUser?.householdId;
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
  }) async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    final copyFrom = copyFromMonthId ??
        _months.where((m) => m.id != monthId).firstOrNull?.id;
    if (copyFrom != null && copyFrom.isNotEmpty) {
      await _repo.createMonthFromCopy(
        householdId: hid,
        fromMonthId: copyFrom,
        toMonthId: monthId,
      );
    } else {
      await _repo.createEmptyMonth(householdId: hid, monthId: monthId);
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
    final h = await _repo.createHousehold(name: name, creatorUid: uid);
    _appUser = _appUser?.copyWith(householdId: h.id);
    await _attachHousehold(h.id);
  }

  Future<void> updateHouseholdName(String name) async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    await _repo.updateHouseholdName(householdId: hid, name: name);
  }

  Future<void> joinHousehold(String inviteCode) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    final h = await _repo.joinHousehold(inviteCode: inviteCode, uid: uid);
    _appUser = _appUser?.copyWith(householdId: h.id);
    await _attachHousehold(h.id);
  }

  Future<String> duplicateCurrentMonth() async {
    final hid = _appUser?.householdId;
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
    required String type,
    String? nameEn,
    String? nameRu,
    double? targetAmount,
  }) async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    final trimmed = name.trim();
    final en = (nameEn ?? trimmed).trim();
    final ru = (nameRu ?? trimmed).trim();
    final id = await _repo.addCategory(
      householdId: hid,
      nameEn: en,
      nameRu: ru,
      colorValue: colorValue,
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
      type: suggested.type,
    );
  }

  Future<int> addDefaultCategories() async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    return _repo.addDefaultCategories(householdId: hid);
  }

  Future<void> updateCategory(BudgetCategory category) async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    await _repo.updateCategory(householdId: hid, category: category);
    if (category.isSavings) {
      await ensureImplicitSubcategory(category.id);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    await _repo.deleteCategory(householdId: hid, categoryId: categoryId);
  }

  Future<String> addSubcategory({
    required String categoryId,
    required String name,
    double planned = 0,
    int? installmentCurrent,
    int? installmentTotal,
  }) async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    final trimmed = name.trim();
    final id = await _repo.addSubcategory(
      householdId: hid,
      categoryId: categoryId,
      nameEn: trimmed,
      nameRu: trimmed,
      sortOrder: _subcategories.length,
      installmentTotal: installmentTotal,
    );
    if (_monthId != null && (planned > 0 || installmentCurrent != null)) {
      await _repo.upsertPlan(
        householdId: hid,
        monthId: _monthId!,
        plan: MonthPlan(
          subcategoryId: id,
          planned: planned,
          installmentCurrent: installmentCurrent,
        ),
      );
    }
    return id;
  }

  Future<void> updateSubcategory(Subcategory subcategory) async {
    final hid = _appUser?.householdId;
    if (hid == null) throw StateError('No household');
    await _repo.updateSubcategory(
      householdId: hid,
      subcategory: subcategory,
    );
  }

  Future<void> deleteSubcategory(String subcategoryId) async {
    final hid = _appUser?.householdId;
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
    final hid = _appUser?.householdId;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.upsertPlan(
      householdId: hid,
      monthId: mid,
      plan: MonthPlan(
        subcategoryId: subcategoryId,
        planned: planned,
        installmentCurrent:
            clearInstallmentCurrent ? null : installmentCurrent,
      ),
    );
  }

  Future<void> addExpense({
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final hid = _appUser?.householdId;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.addExpense(
      householdId: hid,
      monthId: mid,
      subcategoryId: subcategoryId,
      amount: amount,
      date: date,
      note: note,
    );
    await _adjustSavedTotal(subcategoryId: subcategoryId, delta: amount);
  }

  Future<void> addDeposit({
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final subId = await ensureImplicitSubcategory(categoryId);
    await addExpense(
      subcategoryId: subId,
      amount: amount,
      date: date,
      note: note,
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final hid = _appUser?.householdId;
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
    );
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
    final hid = _appUser?.householdId;
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
