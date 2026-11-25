import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/locale_lookup.dart';
import '../models/models.dart';
import '../data/default_categories.dart';
import '../data/local/local_budget_store.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';
import '../services/sync_engine.dart';
import '../utils/money.dart';

part 'app_state/selectors.dart';
part 'app_state/sync.dart';
part 'app_state/households.dart';
part 'app_state/catalog.dart';
part 'app_state/ledger.dart';
part 'app_state/bills_and_loans.dart';

class AppState extends ChangeNotifier {
  AppState({
    AuthService? authService,
    BudgetRepository? budgetRepository,
    SyncEngine? syncEngine,
  }) : _auth = authService ?? AuthService(),
       _repo = budgetRepository ?? BudgetRepository() {
    _sync = syncEngine ?? SyncEngine(repo: _repo);
    _authSub = _auth.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _auth;
  final BudgetRepository _repo;
  late final SyncEngine _sync;

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
  StreamSubscription<List<IncomeSource>>? _sourcesSub;
  StreamSubscription<List<IncomeEntry>>? _entriesSub;
  StreamSubscription<List<MonthPlan>>? _plansSub;
  StreamSubscription<List<Expense>>? _expensesSub;
  StreamSubscription<List<Deposit>>? _depositsSub;
  StreamSubscription<List<PotBalance>>? _potBalancesSub;
  StreamSubscription<List<LoanPayment>>? _loanPaymentsSub;
  StreamSubscription<BudgetMonth?>? _monthDocSub;
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
  List<String> _labeledMemberIds = const [];

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

  /// Lets extension parts notify without touching the protected member.
  void _notify() => notifyListeners();

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    _detachBudgetListeners();
    super.dispose();
  }
}
