part of '../app_state.dart';

/// Categories, savings pots, subcategories and plans.
extension AppStateCatalog on AppState {
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
      _notify();
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
      _notify();
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
      await _repo.upsertPlan(householdId: hid, monthId: _monthId!, plan: plan);
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
    _notify();
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
    _notify();
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
    _notify();
  }
}
