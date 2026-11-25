part of '../budget_repository.dart';

/// Categories, subcategories and month plans.
extension BudgetRepositoryCatalog on BudgetRepository {
  Future<String> addCategory({
    required String householdId,
    required String nameEn,
    required String nameRu,
    required int colorValue,
    required String iconKey,
    required String type,
    required int sortOrder,
    double? targetAmount,
  }) async {
    final doc = await _categories(householdId).add({
      'nameEn': nameEn,
      'nameRu': nameRu,
      'colorValue': colorValue,
      'iconKey': iconKey,
      'type': type,
      'sortOrder': sortOrder,
      'targetAmount': targetAmount,
    });
    return doc.id;
  }

  Future<void> updateCategory({
    required String householdId,
    required BudgetCategory category,
  }) async {
    await _categories(
      householdId,
    ).doc(category.id).set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCategory({
    required String householdId,
    required String categoryId,
  }) async {
    final subs = await _subcategories(
      householdId,
    ).where('categoryId', isEqualTo: categoryId).get();
    final ops = <void Function(WriteBatch)>[];
    for (final doc in subs.docs) {
      ops.add((batch) => batch.delete(doc.reference));
    }
    ops.add((batch) => batch.delete(_categories(householdId).doc(categoryId)));
    await _commitInChunks(ops);
  }

  Future<int> addDefaultCategories({
    required String householdId,
    List<DefaultCategory>? only,
  }) async {
    final existing = await _categories(householdId).get();
    final existingNames = existing.docs
        .map((d) => (d.data()['nameEn'] as String? ?? '').toLowerCase())
        .toSet();

    final toAdd = only ?? DefaultCategories.all;
    final ops = <void Function(WriteBatch)>[];
    var added = 0;
    var sortBase = existing.docs.length;
    String? savingsCatId;
    for (final doc in existing.docs) {
      final data = doc.data();
      if (data['type'] == 'savings' &&
          (data['nameEn'] as String? ?? '').toLowerCase() ==
              DefaultCategories.savingsNameEn.toLowerCase()) {
        savingsCatId = doc.id;
        break;
      }
    }
    for (final cat in toAdd) {
      if (existingNames.contains(cat.nameEn.toLowerCase())) continue;
      final sortOrder = sortBase + added;
      final catId = _uuid.v4();
      ops.add(
        (batch) => batch.set(_categories(householdId).doc(catId), {
          'nameEn': cat.nameEn,
          'nameRu': cat.nameRu,
          'colorValue': cat.colorValue,
          'iconKey': cat.iconKey,
          'type': cat.type,
          'sortOrder': sortOrder,
        }),
      );
      if (cat.type == 'savings') {
        savingsCatId = catId;
      }
      added++;
    }

    if (only == null) {
      savingsCatId ??= _uuid.v4();
      if (!existingNames.contains(
        DefaultCategories.savingsNameEn.toLowerCase(),
      )) {
        final alreadyQueued = toAdd.any(
          (c) =>
              c.type == 'savings' &&
              c.nameEn.toLowerCase() ==
                  DefaultCategories.savingsNameEn.toLowerCase(),
        );
        if (!alreadyQueued) {
          ops.add(
            (batch) => batch.set(_categories(householdId).doc(savingsCatId!), {
              'nameEn': DefaultCategories.savingsNameEn,
              'nameRu': DefaultCategories.savingsNameRu,
              'colorValue': DefaultCategories.savingsColorValue,
              'iconKey': DefaultCategories.savingsIconKey,
              'type': 'savings',
              'sortOrder': sortBase + added,
            }),
          );
          added++;
        }
      }
      final existingSubs = await _subcategories(householdId).get();
      final existingPotNames = existingSubs.docs
          .where((d) => d.data()['categoryId'] == savingsCatId)
          .map((d) => (d.data()['nameEn'] as String? ?? '').toLowerCase())
          .toSet();
      var potSort = existingPotNames.length;
      for (final pot in DefaultPots.all) {
        if (existingPotNames.contains(pot.nameEn.toLowerCase())) continue;
        final sort = potSort;
        final isLeftover = DefaultPots.isLeftoverName(pot.nameEn);
        ops.add(
          (batch) => batch.set(_subcategories(householdId).doc(_uuid.v4()), {
            'categoryId': savingsCatId,
            'nameEn': pot.nameEn,
            'nameRu': pot.nameRu,
            'sortOrder': sort,
            'archived': false,
            'includeInTotal': !isLeftover,
          }),
        );
        existingPotNames.add(pot.nameEn.toLowerCase());
        potSort++;
        added++;
      }
    }

    if (ops.isNotEmpty) {
      await _commitInChunks(ops);
    }
    return added;
  }

  Future<String> ensureImplicitSubcategory({
    required String householdId,
    required String categoryId,
    required String nameEn,
    required String nameRu,
  }) async {
    final existing = await _subcategories(
      householdId,
    ).where('categoryId', isEqualTo: categoryId).limit(1).get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    return addSubcategory(
      householdId: householdId,
      categoryId: categoryId,
      nameEn: nameEn,
      nameRu: nameRu,
      sortOrder: 0,
    );
  }

  Future<String> addSubcategory({
    required String householdId,
    required String categoryId,
    required String nameEn,
    required String nameRu,
    required int sortOrder,
    double? targetAmount,
    DateTime? targetDate,
    bool includeInTotal = true,
    String? monthId,
  }) async {
    final doc = await _subcategories(householdId).add({
      'categoryId': categoryId,
      'nameEn': nameEn,
      'nameRu': nameRu,
      'sortOrder': sortOrder,
      'archived': false,
      'targetAmount': targetAmount,
      'targetDate': targetDate?.toIso8601String(),
      'includeInTotal': includeInTotal,
    });

    // If this is a savings pot and a month is selected, seed potBalances.
    if (monthId != null && monthId.isNotEmpty) {
      final cat = await _categories(householdId).doc(categoryId).get();
      if (cat.data()?['type'] == 'savings' &&
          !DefaultPots.isLeftoverName(nameEn)) {
        final monthRef = _monthRef(householdId, monthId);
        final balance = PotBalance(subcategoryId: doc.id);
        await monthRef
            .collection('potBalances')
            .doc(doc.id)
            .set(balance.toMap());
        if (includeInTotal) {
          // opening/balance are 0 — no summary change needed
        }
      }
    }
    return doc.id;
  }

  Future<void> updateSubcategory({
    required String householdId,
    required Subcategory subcategory,
  }) async {
    await _subcategories(
      householdId,
    ).doc(subcategory.id).set(subcategory.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSubcategory({
    required String householdId,
    required String subcategoryId,
  }) async {
    await _subcategories(householdId).doc(subcategoryId).delete();
  }

  Future<void> upsertPlan({
    required String householdId,
    required String monthId,
    required MonthPlan plan,
    bool clearNameEn = false,
    bool clearNameRu = false,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final planRef = monthRef.collection('plans').doc(plan.subcategoryId);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(planRef);
      final oldPlanned = existing.exists
          ? ((existing.data()?['planned'] as num?)?.toDouble() ?? 0)
          : 0.0;
      final data = plan.toMap();
      if (clearNameEn) {
        data['nameEn'] = FieldValue.delete();
      } else if (plan.nameEn != null) {
        data['nameEn'] = plan.nameEn;
      }
      if (clearNameRu) {
        data['nameRu'] = FieldValue.delete();
      } else if (plan.nameRu != null) {
        data['nameRu'] = plan.nameRu;
      }
      tx.set(planRef, data, SetOptions(merge: true));
      final delta = plan.planned - oldPlanned;
      if (delta != 0) {
        tx.update(monthRef, {'plannedTotal': FieldValue.increment(delta)});
      }
    });
  }

  Future<void> deletePlan({
    required String householdId,
    required String monthId,
    required String subcategoryId,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final planRef = monthRef.collection('plans').doc(subcategoryId);
    await _db.runTransaction((tx) async {
      final existing = await tx.get(planRef);
      if (!existing.exists) return;
      final oldPlanned = (existing.data()?['planned'] as num?)?.toDouble() ?? 0;
      tx.delete(planRef);
      if (oldPlanned != 0) {
        tx.update(monthRef, {
          'plannedTotal': FieldValue.increment(-oldPlanned),
        });
      }
    });
  }
}
