part of '../budget_repository.dart';

/// Month creation, copy, leftover rollover and duplication.
extension BudgetRepositoryMonths on BudgetRepository {
  Stream<Household?> watchHousehold(String householdId) {
    return _householdRef(householdId).snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return Household.fromMap(s.id, s.data()!);
    });
  }

  Stream<List<BudgetMonth>> watchMonths(String householdId) {
    return _months(householdId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => BudgetMonth.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    });
  }

  /// Full month list from server (bootstrap when the months listener is empty).
  Future<List<BudgetMonth>> fetchRecentMonths(
    String householdId, {
    Source source = Source.server,
  }) async {
    final snap = await _months(householdId).get(GetOptions(source: source));
    final list = snap.docs
        .map((d) => BudgetMonth.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  Stream<BudgetMonth?> watchMonth(String householdId, String monthId) {
    return _monthRef(householdId, monthId).snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return BudgetMonth.fromMap(s.id, s.data()!);
    });
  }

  Future<bool> monthExists(String householdId, String monthId) async {
    final snap = await _monthRef(householdId, monthId).get();
    return snap.exists;
  }

  Future<void> createEmptyMonth({
    required String householdId,
    required String monthId,
    bool rolloverLeftover = false,
  }) async {
    final ref = _monthRef(householdId, monthId);
    final existing = await ref.get();
    if (existing.exists) {
      throw StateError('Month already exists');
    }

    if (rolloverLeftover) {
      final cats = await _categories(householdId).get();
      final subs = await _subcategories(householdId).get();
      await _ensureLeftoverPot(
        householdId: householdId,
        categoryDocs: cats.docs,
        subcategoryDocs: subs.docs,
      );
    }

    final leftover = await _resolveLeftoverFromPrior(householdId, monthId);
    final pots = await _liveSavingsPots(householdId);
    final priorBalances = await _fetchPriorPotBalances(householdId, monthId);
    final savingsBefore = _sumIncludedBalances(pots, {
      for (final p in pots)
        p.id: PotBalance(
          subcategoryId: p.id,
          openingBalance: priorBalances[p.id]?.balance ?? 0,
          balance: priorBalances[p.id]?.balance ?? 0,
        ),
    }, opening: true);

    final batch = _db.batch();
    batch.set(
      ref,
      _emptyMonthSummary(
        monthId: monthId,
        leftoverFromPrior: leftover,
        savingsBeforeMonth: savingsBefore,
        savingsThroughMonth: savingsBefore,
      ),
    );
    _bootstrapPotBalances(
      batch: batch,
      monthRef: ref,
      pots: pots,
      priorBalances: priorBalances,
    );
    await batch.commit();

    await applyRecurringBillsToMonth(
      householdId: householdId,
      monthId: monthId,
    );
    await applyFixedPlanActualsToMonth(
      householdId: householdId,
      monthId: monthId,
    );
  }

  /// Copies income sources and plans. Does not copy prior expenses, deposits, or
  /// loan payments. After copy, posts planned amounts as spent (monthly) and
  /// deposits (savings). Bootstraps potBalances from the prior month end
  /// balances and stores leftoverFromPrior from the source month's cashLeft when
  /// [fromMonthId] is the calendar previous month (otherwise from prior doc).
  Future<void> createMonthFromCopy({
    required String householdId,
    required String fromMonthId,
    required String toMonthId,
    bool rolloverLeftover = false,
    Set<String>? categoryIds,
  }) async {
    if (fromMonthId == toMonthId) {
      throw StateError('Cannot copy a month onto itself');
    }
    final fromRef = _monthRef(householdId, fromMonthId);
    final toRef = _monthRef(householdId, toMonthId);

    final fromSnap = await fromRef.get();
    if (!fromSnap.exists) {
      throw StateError('Source month not found');
    }
    final existing = await toRef.get();
    if (existing.exists) {
      throw StateError('Month already exists');
    }

    final sources = await fromRef.collection('incomeSources').get();
    final plans = await fromRef.collection('plans').get();
    final cats = await _categories(householdId).get();
    final savingsCatIds = {
      for (final c in cats.docs)
        if (c.data()['type'] == 'savings') c.id,
    };
    final subs = await _subcategories(householdId).get();
    final subCategoryIds = <String, String>{};
    String? leftoverPotId;
    final leftoverName = DefaultPots.leftoverNameEn.toLowerCase();
    for (final doc in subs.docs) {
      final data = doc.data();
      final catId = data['categoryId'] as String? ?? '';
      subCategoryIds[doc.id] = catId;
      if (savingsCatIds.contains(catId) &&
          (data['nameEn'] as String? ?? '').toLowerCase() == leftoverName) {
        leftoverPotId = doc.id;
      }
    }

    if (rolloverLeftover) {
      leftoverPotId ??= await _ensureLeftoverPot(
        householdId: householdId,
        categoryDocs: cats.docs,
        subcategoryDocs: subs.docs,
      );
    }

    final leftover = await _resolveLeftoverFromPrior(householdId, toMonthId);
    final pots = await _liveSavingsPots(householdId);
    final priorBalances = await _fetchPriorPotBalances(householdId, toMonthId);
    final openingMap = {
      for (final p in pots)
        p.id: PotBalance(
          subcategoryId: p.id,
          openingBalance: priorBalances[p.id]?.balance ?? 0,
          balance: priorBalances[p.id]?.balance ?? 0,
        ),
    };
    final savingsBefore = _sumIncludedBalances(pots, openingMap, opening: true);

    final ops = <void Function(WriteBatch)>[
      (batch) {
        batch.set(
          toRef,
          _emptyMonthSummary(
            monthId: toMonthId,
            leftoverFromPrior: leftover,
            savingsBeforeMonth: savingsBefore,
            savingsThroughMonth: savingsBefore,
          ),
        );
        _bootstrapPotBalances(
          batch: batch,
          monthRef: toRef,
          pots: pots,
          priorBalances: priorBalances,
        );
      },
    ];

    for (final doc in sources.docs) {
      ops.add(
        (batch) => batch.set(
          toRef.collection('incomeSources').doc(_uuid.v4()),
          doc.data(),
        ),
      );
    }

    var plannedTotal = 0.0;
    for (final doc in plans.docs) {
      // Leftover is month cash, not a recurring savings target.
      if (leftoverPotId != null && doc.id == leftoverPotId) continue;
      if (categoryIds != null) {
        final catId = subCategoryIds[doc.id] ?? '';
        if (!categoryIds.contains(catId)) continue;
      }
      final data = Map<String, dynamic>.from(doc.data());
      data.remove('installmentCurrent');
      plannedTotal += (data['planned'] as num?)?.toDouble() ?? 0;
      ops.add(
        (batch) => batch.set(toRef.collection('plans').doc(doc.id), data),
      );
    }
    if (plannedTotal != 0) {
      ops.add((batch) => batch.update(toRef, {'plannedTotal': plannedTotal}));
    }

    await _commitInChunks(ops);
    await applyRecurringBillsToMonth(
      householdId: householdId,
      monthId: toMonthId,
    );
    await applyFixedPlanActualsToMonth(
      householdId: householdId,
      monthId: toMonthId,
    );
  }

  /// Finds or creates the dedicated Leftover savings pot under Savings.
  Future<String> _ensureLeftoverPot({
    required String householdId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> categoryDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> subcategoryDocs,
  }) async {
    final leftoverName = DefaultPots.leftoverNameEn.toLowerCase();

    String? savingsCatId;
    for (final doc in categoryDocs) {
      final data = doc.data();
      if (data['type'] == 'savings' &&
          (data['nameEn'] as String? ?? '').toLowerCase() ==
              DefaultCategories.savingsNameEn.toLowerCase()) {
        savingsCatId = doc.id;
        break;
      }
    }
    savingsCatId ??= categoryDocs
        .where((d) => d.data()['type'] == 'savings')
        .map((d) => d.id)
        .firstOrNull;

    savingsCatId ??= await addCategory(
      householdId: householdId,
      nameEn: DefaultCategories.savingsNameEn,
      nameRu: DefaultCategories.savingsNameRu,
      colorValue: DefaultCategories.savingsColorValue,
      iconKey: DefaultCategories.savingsIconKey,
      type: 'savings',
      sortOrder: categoryDocs.length,
    );

    for (final doc in subcategoryDocs) {
      final data = doc.data();
      if (data['categoryId'] == savingsCatId &&
          (data['nameEn'] as String? ?? '').toLowerCase() == leftoverName) {
        return doc.id;
      }
    }

    final potSort = subcategoryDocs
        .where((d) => d.data()['categoryId'] == savingsCatId)
        .length;
    return addSubcategory(
      householdId: householdId,
      categoryId: savingsCatId,
      nameEn: DefaultPots.leftoverNameEn,
      nameRu: DefaultPots.leftoverNameRu,
      sortOrder: potSort,
      includeInTotal: false,
    );
  }

  Future<String> ensureLeftoverPot(String householdId) async {
    final cats = await _categories(householdId).get();
    final subs = await _subcategories(householdId).get();
    return _ensureLeftoverPot(
      householdId: householdId,
      categoryDocs: cats.docs,
      subcategoryDocs: subs.docs,
    );
  }

  Future<String> duplicateMonth({
    required String householdId,
    required String fromMonthId,
  }) async {
    final toMonthId = nextMonthId(fromMonthId);
    await createMonthFromCopy(
      householdId: householdId,
      fromMonthId: fromMonthId,
      toMonthId: toMonthId,
    );
    return toMonthId;
  }
}
