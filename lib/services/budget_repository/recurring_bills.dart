part of '../budget_repository.dart';

/// Recurring bills and applying fixed actuals to a month.
extension BudgetRepositoryRecurringBills on BudgetRepository {
  Stream<List<RecurringBill>> watchRecurringBills(String householdId) {
    return _householdRef(householdId)
        .collection('recurringBills')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => RecurringBill.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addRecurringBill({
    required String householdId,
    required String name,
    required double amount,
    required int dayOfMonth,
    String? subcategoryId,
  }) async {
    await _householdRef(householdId).collection('recurringBills').add({
      'name': name,
      'amount': amount,
      'dayOfMonth': dayOfMonth.clamp(1, 28),
      'subcategoryId': subcategoryId,
    });
  }

  Future<void> updateRecurringBill({
    required String householdId,
    required RecurringBill bill,
  }) async {
    await _householdRef(
      householdId,
    ).collection('recurringBills').doc(bill.id).set({
      'name': bill.name,
      'amount': bill.amount,
      'dayOfMonth': bill.dayOfMonth.clamp(1, 28),
      'subcategoryId': bill.subcategoryId,
    });
  }

  Future<void> deleteRecurringBill({
    required String householdId,
    required String billId,
  }) async {
    await _householdRef(
      householdId,
    ).collection('recurringBills').doc(billId).delete();
  }

  Future<void> applyRecurringBillsToMonth({
    required String householdId,
    required String monthId,
    Set<String> excludeSubcategoryIds = const {},
  }) async {
    final bills = await _householdRef(
      householdId,
    ).collection('recurringBills').get();
    if (bills.docs.isEmpty) return;
    final plans = await _monthRef(
      householdId,
      monthId,
    ).collection('plans').get();
    final planned = {
      for (final d in plans.docs)
        d.id: (d.data()['planned'] as num?)?.toDouble() ?? 0,
    };
    final ops = <void Function(WriteBatch)>[];
    var plannedDelta = 0.0;
    for (final doc in bills.docs) {
      final bill = RecurringBill.fromMap(doc.id, doc.data());
      final subId = bill.subcategoryId;
      if (subId == null || subId.isEmpty || bill.amount <= 0) continue;
      if (excludeSubcategoryIds.contains(subId)) continue;
      final existing = planned[subId] ?? 0;
      if (existing > 0) continue;
      plannedDelta += bill.amount;
      ops.add(
        (batch) => batch.set(
          _monthRef(householdId, monthId).collection('plans').doc(subId),
          {'planned': bill.amount},
          SetOptions(merge: true),
        ),
      );
    }
    if (plannedDelta != 0) {
      ops.add(
        (batch) => batch.update(_monthRef(householdId, monthId), {
          'plannedTotal': FieldValue.increment(plannedDelta),
        }),
      );
    }
    if (ops.isNotEmpty) await _commitInChunks(ops);
  }

  /// For monthly plans, posts an expense equal to planned; for savings plans,
  /// posts a deposit equal to planned. Skips spend envelopes and leftover.
  /// Idempotent: skips a subcategory that already has activity this month.
  Future<void> applyFixedPlanActualsToMonth({
    required String householdId,
    required String monthId,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final plansSnap = await monthRef.collection('plans').get();
    if (plansSnap.docs.isEmpty) return;

    final cats = await _categories(householdId).get();
    final catType = {
      for (final d in cats.docs) d.id: d.data()['type'] as String? ?? 'spend',
    };
    final subs = await _subcategories(householdId).get();
    final subMeta =
        <String, ({String categoryId, bool includeInTotal, String nameEn})>{};
    for (final d in subs.docs) {
      final data = d.data();
      subMeta[d.id] = (
        categoryId: data['categoryId'] as String? ?? '',
        includeInTotal: data['includeInTotal'] as bool? ?? true,
        nameEn: data['nameEn'] as String? ?? '',
      );
    }

    final billDayBySub = <String, int>{};
    final bills = await _householdRef(
      householdId,
    ).collection('recurringBills').get();
    for (final d in bills.docs) {
      final bill = RecurringBill.fromMap(d.id, d.data());
      final subId = bill.subcategoryId;
      if (subId != null && subId.isNotEmpty) {
        billDayBySub[subId] = bill.dayOfMonth;
      }
    }

    final expensesSnap = await monthRef.collection('expenses').get();
    final spentSubs = {
      for (final d in expensesSnap.docs)
        d.data()['subcategoryId'] as String? ?? '',
    };
    final depositsSnap = await monthRef.collection('deposits').get();
    final depositedSubs = {
      for (final d in depositsSnap.docs)
        d.data()['subcategoryId'] as String? ?? '',
    };

    final monthStart = dateFromMonthId(monthId);
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;

    for (final doc in plansSnap.docs) {
      final planned = (doc.data()['planned'] as num?)?.toDouble() ?? 0;
      if (planned <= 0) continue;
      final subId = doc.id;
      final meta = subMeta[subId];
      if (meta == null) continue;
      if (DefaultPots.isLeftoverName(meta.nameEn)) continue;
      final type = catType[meta.categoryId];
      final day = (billDayBySub[subId] ?? 1).clamp(1, lastDay);
      final date = DateTime(monthStart.year, monthStart.month, day);

      if (type == 'monthly') {
        if (spentSubs.contains(subId)) continue;
        await addExpense(
          householdId: householdId,
          monthId: monthId,
          subcategoryId: subId,
          amount: planned,
          date: date,
        );
        spentSubs.add(subId);
      } else if (type == 'savings') {
        if (depositedSubs.contains(subId)) continue;
        await addDeposit(
          householdId: householdId,
          monthId: monthId,
          subcategoryId: subId,
          amount: planned,
          date: date,
          includeInTotal: meta.includeInTotal,
        );
        depositedSubs.add(subId);
      }
    }
  }
}
