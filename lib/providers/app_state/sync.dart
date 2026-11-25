part of '../app_state.dart';

/// Auth, household and month listeners plus local-cache hydration.
extension AppStateSync on AppState {
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
      _notify();
      return;
    }
    _loading = true;
    _notify();
    try {
      _appUser = await _auth.ensureUserDoc(user);
      await _auth.refreshMembershipClaims();
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
        _notify();
      });
      await _refreshMyHouseholds();
      await _attachHousehold(_appUser!.activeHouseholdId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _notify();
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
      _notify();
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
      _notify();
    } catch (e) {
      _error = e.toString();
      _notify();
    }
  }

  Future<void> _detachCurrentMonthListeners({bool clearData = true}) async {
    await _sourcesSub?.cancel();
    await _entriesSub?.cancel();
    await _plansSub?.cancel();
    await _expensesSub?.cancel();
    await _depositsSub?.cancel();
    await _potBalancesSub?.cancel();
    await _loanPaymentsSub?.cancel();
    await _monthDocSub?.cancel();
    _sourcesSub = null;
    _entriesSub = null;
    _plansSub = null;
    _expensesSub = null;
    _depositsSub = null;
    _potBalancesSub = null;
    _loanPaymentsSub = null;
    _monthDocSub = null;
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
      _labeledMemberIds = const [];
      _monthId = null;
      _budgetDataReady = false;
    }
  }

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
      _notify();
      return;
    }

    final hydrated = await _hydrateFromLocal(householdId);
    if (hydrated) {
      _budgetDataReady = true;
      _notify();
    }

    final ready = Completer<Household?>();
    _householdSub = _repo
        .watchHousehold(householdId)
        .listen(
          (h) {
            _household = h;
            if (h != null) {
              unawaited(_sync.persistHousehold(h));
              unawaited(_refreshMemberLabels(h.memberIds));
            }
            if (!ready.isCompleted) ready.complete(h);
            if (h == null) {
              unawaited(_clearStaleHousehold());
            }
            _notify();
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
      _notify();
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
            unawaited(_sync.persistCategories(householdId, v));
            if (!categoriesReady.isCompleted) categoriesReady.complete();
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (!categoriesReady.isCompleted) categoriesReady.complete();
            _notify();
          },
        );
    _subcategoriesSub = _repo
        .watchSubcategories(householdId)
        .listen(
          (v) {
            _subcategories = v;
            unawaited(_sync.persistSubcategories(householdId, v));
            if (!subcategoriesReady.isCompleted) subcategoriesReady.complete();
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (!subcategoriesReady.isCompleted) subcategoriesReady.complete();
            _notify();
          },
        );
    _billsSub = _repo
        .watchRecurringBills(householdId)
        .listen(
          (v) {
            _recurringBills = v;
            unawaited(_sync.persistBills(householdId, v));
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            _notify();
          },
        );
    _loansSub = _repo
        .watchLoans(householdId)
        .listen(
          (v) {
            _loans = v;
            unawaited(_sync.persistLoans(householdId, v));
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            _notify();
          },
        );
    var isFirstMonths = true;
    _monthsSub = _repo
        .watchMonths(householdId)
        .listen(
          (list) async {
            _months = list;
            unawaited(_sync.persistMonthSummaries(householdId, list));
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
              _notify();
            }
          },
          onError: (Object e) {
            _error = e.toString();
            if (!monthsReady.isCompleted) monthsReady.complete();
            unawaited(
              _bootstrapMonthsFromServer(householdId, hydrated: hydrated),
            );
            _notify();
          },
        );

    try {
      await Future.wait([
        categoriesReady.future,
        subcategoriesReady.future,
        monthsReady.future,
      ]);
      if (_months.isEmpty) {
        await _bootstrapMonthsFromServer(householdId, hydrated: hydrated);
      }
    } finally {
      _budgetDataReady = true;
      _notify();
    }
  }

  Future<void> _bootstrapMonthsFromServer(
    String householdId, {
    required bool hydrated,
  }) async {
    try {
      final remote = await _repo.fetchRecentMonths(householdId);
      if (remote.isEmpty) return;
      _months = remote;
      unawaited(_sync.persistMonthSummaries(householdId, remote));
      if (_monthId == null) {
        _monthId = preferredMonthId(_months.map((m) => m.id));
        if (_monthId != null) {
          await _listenMonthData(
            householdId,
            _monthId!,
            waitForFirst: !hydrated,
          );
        }
      } else {
        for (final m in remote) {
          if (m.id == _monthId) {
            _selectedMonth = m;
            break;
          }
        }
      }
      _notify();
    } catch (e) {
      _error = e.toString();
      _notify();
    }
  }

  Future<bool> _hydrateFromLocal(String householdId) async {
    try {
      final catalog = await _sync.loadCatalog(householdId);
      if (catalog.household != null) _household = catalog.household;
      if (catalog.categories.isNotEmpty) _categories = catalog.categories;
      if (catalog.subcategories.isNotEmpty) {
        _subcategories = catalog.subcategories;
      }
      if (catalog.bills.isNotEmpty) _recurringBills = catalog.bills;
      if (catalog.loans.isNotEmpty) _loans = catalog.loans;
      if (catalog.months.isNotEmpty) {
        _months = catalog.months;
        _monthId ??= preferredMonthId(catalog.months.map((m) => m.id));
        for (final m in catalog.months) {
          if (m.id == _monthId) {
            _selectedMonth = m;
            break;
          }
        }
      }
      final mid = _monthId;
      if (mid != null) {
        final bundle = await _sync.loadMonth(householdId, mid);
        if (bundle != null) _applyMonthBundle(bundle);
      }
      return _household != null || _months.isNotEmpty || _categories.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _applyMonthBundle(LocalMonthBundle bundle) {
    if (bundle.month != null) _selectedMonth = bundle.month;
    _incomeSources = bundle.incomeSources;
    _incomeEntries = bundle.incomeEntries;
    _plans = bundle.plans;
    _expenses = bundle.expenses;
    _deposits = bundle.deposits;
    _potBalances = bundle.potBalances;
    _loanPayments = bundle.loanPayments;
  }

  Future<void> _clearStaleHousehold() async {
    final uid = _firebaseUser?.uid;
    final staleId = _appUser?.activeHouseholdId ?? _household?.id;
    await _householdSub?.cancel();
    _householdSub = null;
    _household = null;
    _memberLabels = {};
    _labeledMemberIds = const [];
    if (uid != null && staleId != null) {
      try {
        await _auth.removeHouseholdMembership(uid, staleId);
      } catch (_) {}
    }
    _notify();
  }

  Future<void> _refreshMemberLabels(List<String> memberIds) async {
    if (_listEquals(memberIds, _labeledMemberIds) && _memberLabels.isNotEmpty) {
      return;
    }
    final fromProfiles = <String, String>{};
    final household = _household;
    if (household != null) {
      for (final uid in memberIds) {
        final name = household.memberName(uid).trim();
        if (name.isNotEmpty && name != uid) {
          fromProfiles[uid] = name;
        }
      }
    }
    final missing = memberIds
        .where((id) => !fromProfiles.containsKey(id))
        .toList();
    if (missing.isEmpty) {
      _memberLabels = fromProfiles;
      _labeledMemberIds = List.of(memberIds);
      _notify();
      return;
    }
    final fetched = await _auth.getMemberLabels(missing);
    _memberLabels = {...fromProfiles, ...fetched};
    _labeledMemberIds = List.of(memberIds);
    _notify();
  }

  Future<void> _listenMonthData(
    String hid,
    String monthId, {
    bool waitForFirst = false,
  }) async {
    await _detachCurrentMonthListeners(clearData: waitForFirst);

    Completer<void>? sourcesReady;
    Completer<void>? entriesReady;
    Completer<void>? plansReady;
    Completer<void>? expensesReady;
    Completer<void>? depositsReady;
    Completer<void>? potBalancesReady;
    Completer<void>? loanPaymentsReady;
    if (waitForFirst) {
      sourcesReady = Completer<void>();
      entriesReady = Completer<void>();
      plansReady = Completer<void>();
      expensesReady = Completer<void>();
      depositsReady = Completer<void>();
      potBalancesReady = Completer<void>();
      loanPaymentsReady = Completer<void>();
    }

    void persistChanged({
      List<IncomeSource>? incomeSources,
      List<IncomeEntry>? incomeEntries,
      List<MonthPlan>? plans,
      List<Expense>? expenses,
      List<Deposit>? deposits,
      List<PotBalance>? potBalances,
      List<LoanPayment>? loanPayments,
    }) {
      unawaited(
        _sync.persistMonthBundle(
          householdId: hid,
          monthId: monthId,
          month: _selectedMonth,
          incomeSources: incomeSources,
          incomeEntries: incomeEntries,
          plans: plans,
          expenses: expenses,
          deposits: deposits,
          potBalances: potBalances,
          loanPayments: loanPayments,
          markSynced: !waitForFirst,
        ),
      );
    }

    _sourcesSub = _repo
        .watchIncomeSources(hid, monthId)
        .listen(
          (v) {
            _incomeSources = v;
            persistChanged(incomeSources: v);
            if (sourcesReady != null && !sourcesReady.isCompleted) {
              sourcesReady.complete();
            }
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (sourcesReady != null && !sourcesReady.isCompleted) {
              sourcesReady.complete();
            }
            _notify();
          },
        );
    _entriesSub = _repo
        .watchIncomeEntries(hid, monthId)
        .listen(
          (v) {
            _incomeEntries = v;
            persistChanged(incomeEntries: v);
            if (entriesReady != null && !entriesReady.isCompleted) {
              entriesReady.complete();
            }
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (entriesReady != null && !entriesReady.isCompleted) {
              entriesReady.complete();
            }
            _notify();
          },
        );
    _plansSub = _repo
        .watchPlans(hid, monthId)
        .listen(
          (v) {
            _plans = v;
            persistChanged(plans: v);
            if (plansReady != null && !plansReady.isCompleted) {
              plansReady.complete();
            }
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (plansReady != null && !plansReady.isCompleted) {
              plansReady.complete();
            }
            _notify();
          },
        );
    _expensesSub = _repo
        .watchExpenses(hid, monthId)
        .listen(
          (v) {
            _expenses = v;
            persistChanged(expenses: v);
            if (expensesReady != null && !expensesReady.isCompleted) {
              expensesReady.complete();
            }
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (expensesReady != null && !expensesReady.isCompleted) {
              expensesReady.complete();
            }
            _notify();
          },
        );
    _depositsSub = _repo
        .watchDeposits(hid, monthId)
        .listen(
          (v) {
            _deposits = v;
            persistChanged(deposits: v);
            if (depositsReady != null && !depositsReady.isCompleted) {
              depositsReady.complete();
            }
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (depositsReady != null && !depositsReady.isCompleted) {
              depositsReady.complete();
            }
            _notify();
          },
        );
    _potBalancesSub = _repo
        .watchPotBalances(hid, monthId)
        .listen(
          (v) {
            _potBalances = v;
            persistChanged(potBalances: v);
            if (potBalancesReady != null && !potBalancesReady.isCompleted) {
              potBalancesReady.complete();
            }
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (potBalancesReady != null && !potBalancesReady.isCompleted) {
              potBalancesReady.complete();
            }
            _notify();
          },
        );
    _loanPaymentsSub = _repo
        .watchLoanPayments(hid, monthId)
        .listen(
          (v) {
            _loanPayments = v;
            persistChanged(loanPayments: v);
            if (loanPaymentsReady != null && !loanPaymentsReady.isCompleted) {
              loanPaymentsReady.complete();
            }
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            if (loanPaymentsReady != null && !loanPaymentsReady.isCompleted) {
              loanPaymentsReady.complete();
            }
            _notify();
          },
        );
    // Month doc (leftoverFromPrior / cashLeft) is not covered by subcollection
    // listeners; without this, setMonth can show a stale local leftover until PTR.
    _monthDocSub = _repo
        .watchMonth(hid, monthId)
        .listen(
          (month) {
            if (month == null) return;
            _selectedMonth = month;
            unawaited(_sync.persistMonthSummary(hid, month));
            persistChanged();
            _notify();
          },
          onError: (Object e) {
            _error = e.toString();
            _notify();
          },
        );

    if (waitForFirst) {
      await Future.wait([
        sourcesReady!.future,
        entriesReady!.future,
        plansReady!.future,
        expensesReady!.future,
        depositsReady!.future,
        potBalancesReady!.future,
        loanPaymentsReady!.future,
      ]);
      unawaited(
        _sync.persistMonthBundle(
          householdId: hid,
          monthId: monthId,
          month: _selectedMonth,
          incomeSources: _incomeSources,
          incomeEntries: _incomeEntries,
          plans: _plans,
          expenses: _expenses,
          deposits: _deposits,
          potBalances: _potBalances,
          loanPayments: _loanPayments,
          markSynced: true,
        ),
      );
    }
  }

  Future<T> _trackedWrite<T>(
    String op,
    Map<String, dynamic> payload,
    Future<T> Function() send,
  ) {
    return _sync.enqueueAndRun(op, payload, send);
  }
}
