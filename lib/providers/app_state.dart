import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';

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
  List<LineItem> _lineItems = [];

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;
  StreamSubscription<Household?>? _householdSub;
  StreamSubscription<List<BudgetMonth>>? _monthsSub;
  StreamSubscription<List<IncomeSource>>? _sourcesSub;
  StreamSubscription<List<IncomeEntry>>? _entriesSub;
  StreamSubscription<List<BudgetCategory>>? _categoriesSub;
  StreamSubscription<List<LineItem>>? _itemsSub;

  bool get loading => _loading;
  String? get error => _error;
  AppUser? get appUser => _appUser;
  Household? get household => _household;
  String? get monthId => _monthId;
  String get localeCode => _localeCode;
  bool get isSignedIn => _firebaseUser != null;
  bool get hasHousehold =>
      _appUser?.householdId != null && _appUser!.householdId!.isNotEmpty;
  bool get hasMonthSelected => _monthId != null && _monthId!.isNotEmpty;
  List<BudgetMonth> get months => _months;

  List<IncomeSource> get incomeSources => _incomeSources;
  List<IncomeEntry> get incomeEntries => _incomeEntries;
  List<BudgetCategory> get categories => _categories;
  List<LineItem> get lineItems => _lineItems;

  MonthTotals get totals {
    final income = _incomeEntries.fold<double>(0, (s, e) => s + e.amount);
    final planned = _lineItems.fold<double>(0, (s, e) => s + e.planned);
    final actual = _lineItems.fold<double>(0, (s, e) => s + e.actual);
    return MonthTotals(income: income, planned: planned, actual: actual);
  }

  double categoryPlanned(String categoryId) => _lineItems
      .where((i) => i.categoryId == categoryId)
      .fold(0, (s, i) => s + i.planned);

  double categoryActual(String categoryId) => _lineItems
      .where((i) => i.categoryId == categoryId)
      .fold(0, (s, i) => s + i.actual);

  List<LineItem> itemsForCategory(String categoryId) =>
      _lineItems.where((i) => i.categoryId == categoryId).toList();

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
    await _categoriesSub?.cancel();
    await _itemsSub?.cancel();
    _sourcesSub = null;
    _entriesSub = null;
    _categoriesSub = null;
    _itemsSub = null;
    _incomeSources = [];
    _incomeEntries = [];
    _categories = [];
    _lineItems = [];
  }

  Future<void> _detachBudgetListeners() async {
    await _householdSub?.cancel();
    await _monthsSub?.cancel();
    await _detachMonthDataListeners();
    _householdSub = null;
    _monthsSub = null;
    _household = null;
    _months = [];
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
    _householdSub = _repo.watchHousehold(householdId).listen((h) {
      _household = h;
      notifyListeners();
    });
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
    _categoriesSub = _repo.watchCategories(hid, monthId).listen((v) {
      _categories = v;
      notifyListeners();
    });
    _itemsSub = _repo.watchLineItems(hid, monthId).listen((v) {
      _lineItems = v;
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
    if (copyFromMonthId != null && copyFromMonthId.isNotEmpty) {
      await _repo.createMonthFromCopy(
        householdId: hid,
        fromMonthId: copyFromMonthId,
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

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required String type,
  }) async {
    final hid = _appUser?.householdId;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.addCategory(
      householdId: hid,
      monthId: mid,
      nameEn: name.trim(),
      nameRu: name.trim(),
      colorValue: colorValue,
      type: type,
      sortOrder: _categories.length,
    );
  }

  Future<void> updateCategory(BudgetCategory category) async {
    final hid = _appUser?.householdId;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.updateCategory(
      householdId: hid,
      monthId: mid,
      category: category,
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final hid = _appUser?.householdId;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.deleteCategory(
      householdId: hid,
      monthId: mid,
      categoryId: categoryId,
    );
  }
}
