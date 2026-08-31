import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/default_categories.dart';
import '../models/models.dart';
import '../utils/leftover.dart';
import '../utils/money.dart';

class BudgetRepository {
  BudgetRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  DocumentReference<Map<String, dynamic>> _householdRef(String householdId) =>
      _db.collection('households').doc(householdId);

  CollectionReference<Map<String, dynamic>> _months(String householdId) =>
      _householdRef(householdId).collection('months');

  DocumentReference<Map<String, dynamic>> _monthRef(
    String householdId,
    String monthId,
  ) => _months(householdId).doc(monthId);

  CollectionReference<Map<String, dynamic>> _categories(String householdId) =>
      _householdRef(householdId).collection('categories');

  CollectionReference<Map<String, dynamic>> _subcategories(
    String householdId,
  ) => _householdRef(householdId).collection('subcategories');

  CollectionReference<Map<String, dynamic>> _loans(String householdId) =>
      _householdRef(householdId).collection('loans');

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _commitInChunks(
    List<void Function(WriteBatch batch)> ops,
  ) async {
    const limit = 400;
    for (var i = 0; i < ops.length; i += limit) {
      final batch = _db.batch();
      final end = min(i + limit, ops.length);
      for (var j = i; j < end; j++) {
        ops[j](batch);
      }
      await batch.commit();
    }
  }

  Map<String, dynamic> _emptyMonthSummary({
    required String monthId,
    double leftoverFromPrior = 0,
    double savingsBeforeMonth = 0,
    double savingsThroughMonth = 0,
  }) {
    final cashLeft = computeMonthCashLeft(
      leftoverFromPrior: leftoverFromPrior,
      incomeTotal: 0,
      spentTotal: 0,
      depositTotal: 0,
    );
    return BudgetMonth(
      id: monthId,
      leftoverFromPrior: leftoverFromPrior,
      cashLeft: cashLeft,
      savingsBeforeMonth: savingsBeforeMonth,
      savingsThroughMonth: savingsThroughMonth,
    ).toMap();
  }

  Future<double> _resolveLeftoverFromPrior(
    String householdId,
    String monthId,
  ) async {
    final priorId = previousMonthId(monthId);
    final priorSnap = await _monthRef(householdId, priorId).get();
    if (!priorSnap.exists || priorSnap.data() == null) return 0;
    final prior = BudgetMonth.fromMap(priorSnap.id, priorSnap.data()!);
    return leftoverFromPriorCashLeft(prior.cashLeft);
  }

  Future<Map<String, PotBalance>> _fetchPriorPotBalances(
    String householdId,
    String monthId,
  ) async {
    final priorId = previousMonthId(monthId);
    final priorSnap = await _monthRef(householdId, priorId).get();
    if (!priorSnap.exists) return {};
    final pots = await priorSnap.reference.collection('potBalances').get();
    return {
      for (final d in pots.docs) d.id: PotBalance.fromMap(d.id, d.data()),
    };
  }

  Future<List<Subcategory>> _liveSavingsPots(String householdId) async {
    final cats = await _categories(householdId).get();
    final savingsCatIds = {
      for (final c in cats.docs)
        if (c.data()['type'] == 'savings') c.id,
    };
    if (savingsCatIds.isEmpty) return const [];
    final subs = await _subcategories(householdId).get();
    return subs.docs
        .map((d) => Subcategory.fromMap(d.id, d.data()))
        .where(
          (s) =>
              !s.archived &&
              savingsCatIds.contains(s.categoryId) &&
              !DefaultPots.isLeftoverName(s.nameEn),
        )
        .toList();
  }

  void _bootstrapPotBalances({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> monthRef,
    required List<Subcategory> pots,
    required Map<String, PotBalance> priorBalances,
  }) {
    for (final pot in pots) {
      final opening = priorBalances[pot.id]?.balance ?? 0;
      final balance = PotBalance(
        subcategoryId: pot.id,
        openingBalance: opening,
        deposited: 0,
        withdrawn: 0,
        balance: opening,
      );
      batch.set(
        monthRef.collection('potBalances').doc(pot.id),
        balance.toMap(),
      );
    }
  }

  double _sumIncludedBalances(
    List<Subcategory> pots,
    Map<String, PotBalance> balances, {
    required bool opening,
  }) {
    var sum = 0.0;
    for (final pot in pots) {
      if (!pot.includeInTotal) continue;
      final b = balances[pot.id];
      if (b == null) continue;
      sum += opening ? b.openingBalance : b.balance;
    }
    return sum;
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
    String? creatorName,
  }) async {
    final ref = _db.collection('households').doc();
    final profileName = (creatorName ?? '').trim().isEmpty
        ? 'Member'
        : creatorName!.trim();
    final household = Household(
      id: ref.id,
      name: name.trim(),
      memberIds: [creatorUid],
      inviteCode: _generateInviteCode(),
      createdBy: creatorUid,
      memberProfiles: {
        creatorUid: MemberProfile(
          uid: creatorUid,
          name: profileName,
          role: 'owner',
        ),
      },
    );
    await ref.set(household.toMap());
    await _addUserMembership(creatorUid, household.id);
    return household;
  }

  Future<Household> joinHousehold({
    required String inviteCode,
    required String uid,
    String? displayName,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    final query = await _db
        .collection('households')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('Invite code not found');
    }
    final doc = query.docs.first;
    final data = doc.data();
    final members = List<String>.from(data['memberIds'] as List? ?? []);
    if (!members.contains(uid)) {
      members.add(uid);
      final profileName = (displayName ?? '').trim().isEmpty
          ? 'Member'
          : displayName!.trim();
      await doc.reference.update({
        'memberIds': members,
        'memberProfiles.$uid': {'name': profileName, 'role': 'editor'},
      });
    }
    await _addUserMembership(uid, doc.id);
    return Household.fromMap(doc.id, {...data, 'memberIds': members});
  }

  Future<void> _addUserMembership(String uid, String householdId) async {
    await _db.collection('users').doc(uid).update({
      'householdIds': FieldValue.arrayUnion([householdId]),
      'activeHouseholdId': householdId,
    });
  }

  Future<void> _removeUserMembership(String uid, String householdId) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final ids = List<String>.from(data['householdIds'] as List? ?? const []);
    ids.remove(householdId);
    final active = data['activeHouseholdId'] as String?;
    final newActive =
        ids.contains(active) ? active : (ids.isEmpty ? null : ids.first);
    await ref.update({
      'householdIds': ids,
      if (newActive == null)
        'activeHouseholdId': FieldValue.delete()
      else
        'activeHouseholdId': newActive,
    });
  }

  Future<List<Household>> fetchHouseholdsByIds(List<String> ids) async {
    final result = await Future.wait(
      ids.where((id) => id.isNotEmpty).map((id) async {
        final snap = await _householdRef(id).get();
        if (!snap.exists || snap.data() == null) return null;
        return Household.fromMap(snap.id, snap.data()!);
      }),
    );
    return result.whereType<Household>().toList();
  }

  Future<void> updateHouseholdName({
    required String householdId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _householdRef(householdId).update({'name': trimmed});
  }

  Future<void> _deleteQueryDocs(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final snap = await col.get();
    if (snap.docs.isEmpty) return;
    await _commitInChunks([
      for (final doc in snap.docs) (batch) => batch.delete(doc.reference),
    ]);
  }

  Future<void> deleteHousehold({
    required String householdId,
    required String ownerUid,
  }) async {
    final snap = await _householdRef(householdId).get();
    final memberIds = List<String>.from(
      snap.data()?['memberIds'] as List? ?? [ownerUid],
    );
    if (!memberIds.contains(ownerUid)) {
      memberIds.add(ownerUid);
    }

    const monthSubs = [
      'incomeSources',
      'incomeEntries',
      'plans',
      'expenses',
      'deposits',
      'potBalances',
      'loanPayments',
    ];
    final months = await _months(householdId).get();
    for (final month in months.docs) {
      for (final name in monthSubs) {
        await _deleteQueryDocs(month.reference.collection(name));
      }
    }
    await _deleteQueryDocs(_months(householdId));
    await _deleteQueryDocs(_categories(householdId));
    await _deleteQueryDocs(_subcategories(householdId));
    await _deleteQueryDocs(_loans(householdId));
    await _deleteQueryDocs(
      _householdRef(householdId).collection('recurringBills'),
    );
    await _householdRef(householdId).delete();

    for (final uid in memberIds) {
      try {
        await _removeUserMembership(uid, householdId);
      } catch (_) {}
    }
  }

  Future<void> leaveHousehold({
    required String householdId,
    required String uid,
  }) async {
    final ref = _householdRef(householdId);
    final snap = await ref.get();
    if (snap.exists) {
      final members = List<String>.from(
        snap.data()?['memberIds'] as List? ?? const [],
      );
      members.remove(uid);
      await ref.update({
        'memberIds': members,
        'memberProfiles.$uid': FieldValue.delete(),
      });
    }
    await _removeUserMembership(uid, householdId);
  }

  Future<void> removeMember({
    required String householdId,
    required String memberUid,
  }) async {
    await leaveHousehold(householdId: householdId, uid: memberUid);
  }

  Future<void> setMemberRole({
    required String householdId,
    required String memberUid,
    required String role,
  }) async {
    await _householdRef(householdId).update({
      'memberProfiles.$memberUid.role': role,
    });
  }

  Stream<List<RecurringBill>> watchRecurringBills(String householdId) {
    return _householdRef(householdId)
        .collection('recurringBills')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => RecurringBill.fromMap(d.id, d.data()))
              .toList(),
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
    final subMeta = <String, ({String categoryId, bool includeInTotal, String nameEn})>{};
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
    final savingsBefore = _sumIncludedBalances(
      pots,
      {
        for (final p in pots)
          p.id: PotBalance(
            subcategoryId: p.id,
            openingBalance: priorBalances[p.id]?.balance ?? 0,
            balance: priorBalances[p.id]?.balance ?? 0,
          ),
      },
      opening: true,
    );

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
    final savingsBefore = _sumIncludedBalances(
      pots,
      openingMap,
      opening: true,
    );

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
      ops.add(
        (batch) => batch.update(toRef, {'plannedTotal': plannedTotal}),
      );
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

    if (savingsCatId == null) {
      savingsCatId = await addCategory(
        householdId: householdId,
        nameEn: DefaultCategories.savingsNameEn,
        nameRu: DefaultCategories.savingsNameRu,
        colorValue: DefaultCategories.savingsColorValue,
        iconKey: DefaultCategories.savingsIconKey,
        type: 'savings',
        sortOrder: categoryDocs.length,
      );
    }

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

  Stream<List<BudgetCategory>> watchCategories(String householdId) {
    return _categories(householdId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => BudgetCategory.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<Subcategory>> watchSubcategories(String householdId) {
    return _subcategories(householdId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Subcategory.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<MonthPlan>> watchPlans(String householdId, String monthId) {
    return _monthRef(householdId, monthId)
        .collection('plans')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => MonthPlan.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<Expense>> watchExpenses(String householdId, String monthId) {
    return _monthRef(householdId, monthId)
        .collection('expenses')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Expense.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<Deposit>> watchDeposits(String householdId, String monthId) {
    return _monthRef(householdId, monthId)
        .collection('deposits')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Deposit.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<PotBalance>> watchPotBalances(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('potBalances')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => PotBalance.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<Loan>> watchLoans(String householdId) {
    return _loans(householdId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Loan.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<LoanPayment>> watchLoanPayments(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('loanPayments')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => LoanPayment.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<LoanPayment>> watchLoanPaymentsForLoan({
    required String householdId,
    required String loanId,
  }) {
    return _db
        .collectionGroup('loanPayments')
        .where('loanId', isEqualTo: loanId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .where((d) {
                // Scope to this household's months path.
                final path = d.reference.path;
                return path.startsWith('households/$householdId/months/');
              })
              .map((d) => LoanPayment.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<List<MonthPlan>> fetchPlans(String householdId, String monthId) async {
    final snap =
        await _monthRef(householdId, monthId).collection('plans').get();
    return snap.docs.map((d) => MonthPlan.fromMap(d.id, d.data())).toList();
  }

  Future<List<Expense>> fetchExpenses(
    String householdId,
    String monthId,
  ) async {
    final snap =
        await _monthRef(householdId, monthId).collection('expenses').get();
    return snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList();
  }

  Future<List<Deposit>> fetchDeposits(
    String householdId,
    String monthId,
  ) async {
    final snap =
        await _monthRef(householdId, monthId).collection('deposits').get();
    return snap.docs.map((d) => Deposit.fromMap(d.id, d.data())).toList();
  }

  Future<List<IncomeEntry>> fetchIncomeEntries(
    String householdId,
    String monthId,
  ) async {
    final snap = await _monthRef(
      householdId,
      monthId,
    ).collection('incomeEntries').get();
    return snap.docs.map((d) => IncomeEntry.fromMap(d.id, d.data())).toList();
  }

  Future<BudgetMonth?> fetchMonth(String householdId, String monthId) async {
    final snap = await _monthRef(householdId, monthId).get();
    if (!snap.exists || snap.data() == null) return null;
    return BudgetMonth.fromMap(snap.id, snap.data()!);
  }

  Stream<List<IncomeSource>> watchIncomeSources(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('incomeSources')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => IncomeSource.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<IncomeEntry>> watchIncomeEntries(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('incomeEntries')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => IncomeEntry.fromMap(d.id, d.data())).toList(),
        );
  }

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
        await monthRef.collection('potBalances').doc(doc.id).set(
          balance.toMap(),
        );
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
        tx.update(monthRef, {
          'plannedTotal': FieldValue.increment(delta),
        });
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
      final oldPlanned =
          (existing.data()?['planned'] as num?)?.toDouble() ?? 0;
      tx.delete(planRef);
      if (oldPlanned != 0) {
        tx.update(monthRef, {
          'plannedTotal': FieldValue.increment(-oldPlanned),
        });
      }
    });
  }

  Future<void> _refreshCashLeftInTx(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> monthRef,
    Map<String, dynamic> monthData, {
    double? incomeDelta,
    double? spentDelta,
    double? depositDelta,
    double? debtPaidDelta,
    double? savingsBeforeDelta,
    double? savingsThroughDelta,
  }) {
    final income =
        (monthData['incomeTotal'] as num?)?.toDouble() ?? 0;
    final spent = (monthData['spentTotal'] as num?)?.toDouble() ?? 0;
    final deposit = (monthData['depositTotal'] as num?)?.toDouble() ?? 0;
    final leftover =
        (monthData['leftoverFromPrior'] as num?)?.toDouble() ?? 0;
    final nextIncome = income + (incomeDelta ?? 0);
    final nextSpent = spent + (spentDelta ?? 0);
    final nextDeposit = deposit + (depositDelta ?? 0);
    final updates = <String, dynamic>{
      if (incomeDelta != null && incomeDelta != 0)
        'incomeTotal': FieldValue.increment(incomeDelta),
      if (spentDelta != null && spentDelta != 0)
        'spentTotal': FieldValue.increment(spentDelta),
      if (depositDelta != null && depositDelta != 0)
        'depositTotal': FieldValue.increment(depositDelta),
      if (debtPaidDelta != null && debtPaidDelta != 0)
        'debtPaidTotal': FieldValue.increment(debtPaidDelta),
      if (savingsBeforeDelta != null && savingsBeforeDelta != 0)
        'savingsBeforeMonth': FieldValue.increment(savingsBeforeDelta),
      if (savingsThroughDelta != null && savingsThroughDelta != 0)
        'savingsThroughMonth': FieldValue.increment(savingsThroughDelta),
      'cashLeft': computeMonthCashLeft(
        leftoverFromPrior: leftover,
        incomeTotal: nextIncome,
        spentTotal: nextSpent,
        depositTotal: nextDeposit,
      ),
    };
    tx.update(monthRef, updates);
    return Future.value();
  }

  Future<String> addExpense({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
    String? createdBy,
    String? createdByName,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final expenseRef = monthRef.collection('expenses').doc();
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(expenseRef, {
        'subcategoryId': subcategoryId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        spentDelta: amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    return expenseRef.id;
  }

  Future<void> updateExpense({
    required String householdId,
    required String monthId,
    required Expense expense,
    required Expense previous,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final expenseRef = monthRef.collection('expenses').doc(expense.id);
    final amountDelta = expense.amount - previous.amount;
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(expenseRef, expense.toMap(), SetOptions(merge: true));
      if (amountDelta != 0) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          spentDelta: amountDelta,
        );
      }
    });
    if (amountDelta != 0) {
      await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    }
  }

  Future<void> deleteExpense({
    required String householdId,
    required String monthId,
    required Expense expense,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final expenseRef = monthRef.collection('expenses').doc(expense.id);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.delete(expenseRef);
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        spentDelta: -expense.amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
  }

  Future<String> addDeposit({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
    String? createdBy,
    String? createdByName,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final depositRef = monthRef.collection('deposits').doc();
    final potRef = monthRef.collection('potBalances').doc(subcategoryId);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final potSnap = await tx.get(potRef);
      final pot = potSnap.exists
          ? PotBalance.fromMap(subcategoryId, potSnap.data()!)
          : PotBalance(subcategoryId: subcategoryId);
      final next = pot.copyWith(
        deposited: pot.deposited + amount,
        balance: pot.balance + amount,
      );
      tx.set(depositRef, {
        'subcategoryId': subcategoryId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });
      tx.set(potRef, next.toMap());
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        depositDelta: amount,
        savingsThroughDelta: includeInTotal ? amount : 0,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    await _cascadePotBalancesToFollowingMonths(
      householdId,
      monthId,
      subcategoryId,
    );
    return depositRef.id;
  }

  Future<void> updateDeposit({
    required String householdId,
    required String monthId,
    required Deposit deposit,
    required Deposit previous,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final depositRef = monthRef.collection('deposits').doc(deposit.id);
    final potRef = monthRef.collection('potBalances').doc(deposit.subcategoryId);
    final amountDelta = deposit.amount - previous.amount;
    final potChanged = deposit.subcategoryId != previous.subcategoryId;

    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');

      if (potChanged) {
        final oldPotRef =
            monthRef.collection('potBalances').doc(previous.subcategoryId);
        final oldPotSnap = await tx.get(oldPotRef);
        final newPotSnap = await tx.get(potRef);
        if (oldPotSnap.exists) {
          final oldPot =
              PotBalance.fromMap(previous.subcategoryId, oldPotSnap.data()!);
          tx.set(
            oldPotRef,
            oldPot
                .copyWith(
                  deposited: oldPot.deposited - previous.amount,
                  balance: oldPot.balance - previous.amount,
                )
                .toMap(),
          );
        }
        final newPot = newPotSnap.exists
            ? PotBalance.fromMap(deposit.subcategoryId, newPotSnap.data()!)
            : PotBalance(subcategoryId: deposit.subcategoryId);
        tx.set(
          potRef,
          newPot
              .copyWith(
                deposited: newPot.deposited + deposit.amount,
                balance: newPot.balance + deposit.amount,
              )
              .toMap(),
        );
      } else if (amountDelta != 0) {
        final potSnap = await tx.get(potRef);
        if (potSnap.exists) {
          final pot =
              PotBalance.fromMap(deposit.subcategoryId, potSnap.data()!);
          tx.set(
            potRef,
            pot
                .copyWith(
                  deposited: pot.deposited + amountDelta,
                  balance: pot.balance + amountDelta,
                )
                .toMap(),
          );
        }
      }

      tx.set(depositRef, deposit.toMap(), SetOptions(merge: true));
      if (amountDelta != 0) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          depositDelta: amountDelta,
          savingsThroughDelta: includeInTotal ? amountDelta : 0,
        );
      }
    });
    if (amountDelta != 0 || potChanged) {
      await _cascadeLeftoverToFollowingMonths(householdId, monthId);
      await _cascadePotBalancesToFollowingMonths(
        householdId,
        monthId,
        deposit.subcategoryId,
      );
      if (potChanged) {
        await _cascadePotBalancesToFollowingMonths(
          householdId,
          monthId,
          previous.subcategoryId,
        );
      }
    }
  }

  Future<void> deleteDeposit({
    required String householdId,
    required String monthId,
    required Deposit deposit,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final depositRef = monthRef.collection('deposits').doc(deposit.id);
    final potRef =
        monthRef.collection('potBalances').doc(deposit.subcategoryId);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final potSnap = await tx.get(potRef);
      if (potSnap.exists) {
        final pot =
            PotBalance.fromMap(deposit.subcategoryId, potSnap.data()!);
        tx.set(
          potRef,
          pot
              .copyWith(
                deposited: pot.deposited - deposit.amount,
                balance: pot.balance - deposit.amount,
              )
              .toMap(),
        );
      }
      tx.delete(depositRef);
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        depositDelta: -deposit.amount,
        savingsThroughDelta: includeInTotal ? -deposit.amount : 0,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    await _cascadePotBalancesToFollowingMonths(
      householdId,
      monthId,
      deposit.subcategoryId,
    );
  }

  /// Sets the opening (prior) balance for a pot in [monthId].
  Future<void> setPotOpeningBalance({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double openingBalance,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final potRef = monthRef.collection('potBalances').doc(subcategoryId);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final potSnap = await tx.get(potRef);
      final pot = potSnap.exists
          ? PotBalance.fromMap(subcategoryId, potSnap.data()!)
          : PotBalance(subcategoryId: subcategoryId);
      final next = pot.copyWith(
        openingBalance: openingBalance,
        balance: PotBalance.computeBalance(
          openingBalance: openingBalance,
          deposited: pot.deposited,
          withdrawn: pot.withdrawn,
        ),
      );
      final openingDelta = next.openingBalance - pot.openingBalance;
      final balanceDelta = next.balance - pot.balance;
      tx.set(potRef, next.toMap());
      if (includeInTotal && (openingDelta != 0 || balanceDelta != 0)) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          savingsBeforeDelta: openingDelta,
          savingsThroughDelta: balanceDelta,
        );
      }
    });
    await _cascadePotBalancesToFollowingMonths(
      householdId,
      monthId,
      subcategoryId,
    );
  }

  Future<void> addIncomeEntry({
    required String householdId,
    required String monthId,
    required String sourceId,
    required double amount,
    String? note,
    String? createdBy,
    String? createdByName,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final entryRef = monthRef.collection('incomeEntries').doc();
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(entryRef, {
        'sourceId': sourceId,
        'amount': amount,
        'note': note,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        incomeDelta: amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
  }

  Future<void> updateIncomeEntry({
    required String householdId,
    required String monthId,
    required IncomeEntry entry,
    required IncomeEntry previous,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final entryRef = monthRef.collection('incomeEntries').doc(entry.id);
    final amountDelta = entry.amount - previous.amount;
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(entryRef, entry.toMap(), SetOptions(merge: true));
      if (amountDelta != 0) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          incomeDelta: amountDelta,
        );
      }
    });
    if (amountDelta != 0) {
      await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    }
  }

  Future<void> deleteIncomeEntry({
    required String householdId,
    required String monthId,
    required IncomeEntry entry,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final entryRef = monthRef.collection('incomeEntries').doc(entry.id);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.delete(entryRef);
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        incomeDelta: -entry.amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
  }

  Future<String> addIncomeSource({
    required String householdId,
    required String monthId,
    required String nameEn,
    required String nameRu,
    required int sortOrder,
  }) async {
    final doc = await _monthRef(householdId, monthId)
        .collection('incomeSources')
        .add({'nameEn': nameEn, 'nameRu': nameRu, 'sortOrder': sortOrder});
    return doc.id;
  }

  Future<void> updateIncomeSource({
    required String householdId,
    required String monthId,
    required IncomeSource source,
  }) async {
    await _monthRef(householdId, monthId)
        .collection('incomeSources')
        .doc(source.id)
        .set(source.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteIncomeSource({
    required String householdId,
    required String monthId,
    required String sourceId,
  }) async {
    await _monthRef(
      householdId,
      monthId,
    ).collection('incomeSources').doc(sourceId).delete();
  }

  // —— Loans ——

  Future<String> addLoan({
    required String householdId,
    required Loan loan,
  }) async {
    final ref = _loans(householdId).doc();
    await ref.set({
      ...loan.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ref.id;
  }

  Future<void> updateLoan({
    required String householdId,
    required Loan loan,
  }) async {
    await _loans(householdId).doc(loan.id).set(loan.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteLoan({
    required String householdId,
    required String loanId,
  }) async {
    await _loans(householdId).doc(loanId).delete();
  }

  Future<String> addLoanPayment({
    required String householdId,
    required String monthId,
    required String loanId,
    required double amount,
    required DateTime date,
    String? note,
    bool reducesBalance = true,
    String? createdBy,
    String? createdByName,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final paymentRef = monthRef.collection('loanPayments').doc();
    final loanRef = _loans(householdId).doc(loanId);

    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final loanSnap = await tx.get(loanRef);
      if (!loanSnap.exists) throw StateError('Loan not found');
      final loan = Loan.fromMap(loanSnap.id, loanSnap.data()!);

      tx.set(paymentRef, {
        'loanId': loanId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'reducesBalance': reducesBalance,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });

      if (reducesBalance) {
        final nextRemaining =
            (loan.remainingBalance - amount).clamp(0.0, double.infinity);
        final updates = <String, dynamic>{
          'remainingBalance': nextRemaining,
        };
        if (loan.isInstallment) {
          updates['paidInstallments'] = (loan.paidInstallments ?? 0) + 1;
        }
        if (nextRemaining <= 0) {
          updates['status'] = 'paidOff';
        }
        tx.update(loanRef, updates);
      }

      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        debtPaidDelta: amount,
      );
    });
    return paymentRef.id;
  }

  Future<void> deleteLoanPayment({
    required String householdId,
    required String monthId,
    required LoanPayment payment,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final paymentRef = monthRef.collection('loanPayments').doc(payment.id);
    final loanRef = _loans(householdId).doc(payment.loanId);

    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final loanSnap = await tx.get(loanRef);

      tx.delete(paymentRef);

      if (payment.reducesBalance && loanSnap.exists) {
        final loan = Loan.fromMap(loanSnap.id, loanSnap.data()!);
        final nextRemaining = loan.remainingBalance + payment.amount;
        final updates = <String, dynamic>{
          'remainingBalance': nextRemaining,
          if (loan.status == 'paidOff' && nextRemaining > 0) 'status': 'active',
        };
        if (loan.isInstallment && (loan.paidInstallments ?? 0) > 0) {
          updates['paidInstallments'] = (loan.paidInstallments ?? 1) - 1;
        }
        tx.update(loanRef, updates);
      }

      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        debtPaidDelta: -payment.amount,
      );
    });
  }

  /// Propagate cashLeft → leftoverFromPrior for months after [monthId].
  Future<void> _cascadeLeftoverToFollowingMonths(
    String householdId,
    String monthId,
  ) async {
    final months = await _months(householdId).get();
    final sorted = months.docs.map((d) => d.id).toList()..sort();
    final start = sorted.indexOf(monthId);
    if (start < 0) return;

    for (var i = start; i < sorted.length; i++) {
      final id = sorted[i];
      final ref = _monthRef(householdId, id);
      final snap = await ref.get();
      if (!snap.exists || snap.data() == null) continue;
      final month = BudgetMonth.fromMap(snap.id, snap.data()!);
      final cashLeft = computeMonthCashLeft(
        leftoverFromPrior: month.leftoverFromPrior,
        incomeTotal: month.incomeTotal,
        spentTotal: month.spentTotal,
        depositTotal: month.depositTotal,
      );
      if ((cashLeft - month.cashLeft).abs() > 0.0001) {
        await ref.update({'cashLeft': cashLeft});
      }

      if (i + 1 >= sorted.length) break;
      final nextId = sorted[i + 1];
      // Only cascade into the calendar-next month when it exists in the list;
      // also update any later months that claim this as prior via previousMonthId.
      final nextRef = _monthRef(householdId, nextId);
      final expectedPrior = previousMonthId(nextId);
      if (expectedPrior != id) {
        // Still update leftover for the immediate next calendar month if present.
        final calendarNext = nextMonthId(id);
        if (!sorted.contains(calendarNext)) continue;
        final calRef = _monthRef(householdId, calendarNext);
        final calSnap = await calRef.get();
        if (!calSnap.exists || calSnap.data() == null) continue;
        final cal = BudgetMonth.fromMap(calSnap.id, calSnap.data()!);
        final nextLeftover = leftoverFromPriorCashLeft(cashLeft);
        if ((cal.leftoverFromPrior - nextLeftover).abs() > 0.0001) {
          final newCash = computeMonthCashLeft(
            leftoverFromPrior: nextLeftover,
            incomeTotal: cal.incomeTotal,
            spentTotal: cal.spentTotal,
            depositTotal: cal.depositTotal,
          );
          await calRef.update({
            'leftoverFromPrior': nextLeftover,
            'cashLeft': newCash,
          });
        }
        continue;
      }

      final nextSnap = await nextRef.get();
      if (!nextSnap.exists || nextSnap.data() == null) continue;
      final next = BudgetMonth.fromMap(nextSnap.id, nextSnap.data()!);
      final nextLeftover = leftoverFromPriorCashLeft(cashLeft);
      if ((next.leftoverFromPrior - nextLeftover).abs() <= 0.0001) continue;
      final newCash = computeMonthCashLeft(
        leftoverFromPrior: nextLeftover,
        incomeTotal: next.incomeTotal,
        spentTotal: next.spentTotal,
        depositTotal: next.depositTotal,
      );
      await nextRef.update({
        'leftoverFromPrior': nextLeftover,
        'cashLeft': newCash,
      });
    }
  }

  /// Propagate end balance of [subcategoryId] in [monthId] into following
  /// months' openingBalance / balance (preserving their deposited/withdrawn).
  Future<void> _cascadePotBalancesToFollowingMonths(
    String householdId,
    String monthId,
    String subcategoryId,
  ) async {
    final months = await _months(householdId).get();
    final sorted = months.docs.map((d) => d.id).toList()..sort();
    final start = sorted.indexOf(monthId);
    if (start < 0) return;

    for (var i = start; i < sorted.length - 1; i++) {
      final id = sorted[i];
      final nextId = sorted[i + 1];
      if (previousMonthId(nextId) != id && nextMonthId(id) != nextId) {
        // Only cascade along contiguous calendar chain.
        if (nextMonthId(id) != nextId) continue;
      }
      final curPot = await _monthRef(householdId, id)
          .collection('potBalances')
          .doc(subcategoryId)
          .get();
      if (!curPot.exists || curPot.data() == null) break;
      final endBalance =
          PotBalance.fromMap(subcategoryId, curPot.data()!).balance;

      final nextPotRef = _monthRef(householdId, nextId)
          .collection('potBalances')
          .doc(subcategoryId);
      final nextMonthRef = _monthRef(householdId, nextId);

      await _db.runTransaction((tx) async {
        final nextPotSnap = await tx.get(nextPotRef);
        final monthSnap = await tx.get(nextMonthRef);
        if (!monthSnap.exists) return;

        final existing = nextPotSnap.exists
            ? PotBalance.fromMap(subcategoryId, nextPotSnap.data()!)
            : PotBalance(subcategoryId: subcategoryId);
        final next = existing.copyWith(
          openingBalance: endBalance,
          balance: PotBalance.computeBalance(
            openingBalance: endBalance,
            deposited: existing.deposited,
            withdrawn: existing.withdrawn,
          ),
        );
        final openingDelta = next.openingBalance - existing.openingBalance;
        final balanceDelta = next.balance - existing.balance;
        tx.set(nextPotRef, next.toMap());
        if (openingDelta != 0 || balanceDelta != 0) {
          await _refreshCashLeftInTx(
            tx,
            nextMonthRef,
            monthSnap.data()!,
            savingsBeforeDelta: openingDelta,
            savingsThroughDelta: balanceDelta,
          );
        }
      });
    }
  }
}
