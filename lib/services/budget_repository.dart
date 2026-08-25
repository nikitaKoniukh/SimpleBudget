import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/default_categories.dart';
import '../models/models.dart';
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
    await ref.set({...household.toMap(), 'catalogVersion': 1});
    await _db.collection('users').doc(creatorUid).update({
      'householdId': household.id,
    });
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
    }
    final profileName = (displayName ?? '').trim().isEmpty
        ? 'Member'
        : displayName!.trim();
    await doc.reference.update({
      'memberIds': members,
      'memberProfiles.$uid': {'name': profileName, 'role': 'editor'},
    });
    await _db.collection('users').doc(uid).update({'householdId': doc.id});
    return Household.fromMap(doc.id, {...data, 'memberIds': members});
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
    const monthSubs = [
      'incomeSources',
      'incomeEntries',
      'plans',
      'expenses',
      'categories',
      'lineItems',
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
    await _deleteQueryDocs(_householdRef(householdId).collection('recurringBills'));
    await _householdRef(householdId).delete();
    await _db.collection('users').doc(ownerUid).update({
      'householdId': FieldValue.delete(),
    });
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
    await _db.collection('users').doc(uid).update({
      'householdId': FieldValue.delete(),
    });
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
  }) async {
    final bills = await _householdRef(
      householdId,
    ).collection('recurringBills').get();
    if (bills.docs.isEmpty) return;
    final plans = await _monthRef(householdId, monthId).collection('plans').get();
    final planned = {
      for (final d in plans.docs)
        d.id: (d.data()['planned'] as num?)?.toDouble() ?? 0,
    };
    final ops = <void Function(WriteBatch)>[];
    for (final doc in bills.docs) {
      final bill = RecurringBill.fromMap(doc.id, doc.data());
      final subId = bill.subcategoryId;
      if (subId == null || subId.isEmpty || bill.amount <= 0) continue;
      final existing = planned[subId] ?? 0;
      if (existing > 0) continue;
      ops.add(
        (batch) => batch.set(
          _monthRef(householdId, monthId).collection('plans').doc(subId),
          {'planned': bill.amount},
          SetOptions(merge: true),
        ),
      );
    }
    if (ops.isNotEmpty) await _commitInChunks(ops);
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

  Future<bool> monthExists(String householdId, String monthId) async {
    final snap = await _monthRef(householdId, monthId).get();
    return snap.exists;
  }

  Future<void> createEmptyMonth({
    required String householdId,
    required String monthId,
  }) async {
    final ref = _monthRef(householdId, monthId);
    final existing = await ref.get();
    if (existing.exists) {
      throw StateError('Month already exists');
    }
    await ref.set(BudgetMonth(id: monthId).toMap());
    await applyRecurringBillsToMonth(
      householdId: householdId,
      monthId: monthId,
    );
  }

  /// Copies income sources, plans, and spend expenses.
  /// Expense dates keep the same day-of-month in [toMonthId].
  /// Deposits / savings pot entries are not copied (lifetime savedTotal).
  /// Installment current ticks up when it is below the subcategory total.
  ///
  /// When [rolloverLeftover] is true, unused plan amounts from copied spend
  /// categories are summed into a dedicated Leftover savings pot plan (not
  /// added back onto each spend envelope).
  ///
  /// When [categoryIds] is non-null, only plans and expenses for subcategories
  /// under those categories are copied. Income sources are always copied.
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
    final expenses = await fromRef.collection('expenses').get();
    final cats = await _categories(householdId).get();
    final savingsCatIds = {
      for (final c in cats.docs)
        if (c.data()['type'] == 'savings') c.id,
    };
    final subs = await _subcategories(householdId).get();
    final savingsIds = <String>{};
    final subTotals = <String, int?>{};
    final subCategoryIds = <String, String>{};
    for (final doc in subs.docs) {
      final data = doc.data();
      final catId = data['categoryId'] as String? ?? '';
      subCategoryIds[doc.id] = catId;
      subTotals[doc.id] = (data['installmentTotal'] as num?)?.toInt();
      if (savingsCatIds.contains(catId)) {
        savingsIds.add(doc.id);
      }
    }

    final spentBySub = <String, double>{};
    String? leftoverPotId;
    if (rolloverLeftover) {
      for (final doc in expenses.docs) {
        final data = doc.data();
        final subId = data['subcategoryId'] as String? ?? '';
        if (subId.isEmpty) continue;
        if (data['isDeposit'] == true || savingsIds.contains(subId)) continue;
        spentBySub[subId] =
            (spentBySub[subId] ?? 0) + ((data['amount'] as num?)?.toDouble() ?? 0);
      }
      final leftoverName = DefaultPots.leftoverNameEn.toLowerCase();
      for (final doc in subs.docs) {
        final data = doc.data();
        if (savingsIds.contains(doc.id) &&
            (data['nameEn'] as String? ?? '').toLowerCase() == leftoverName) {
          leftoverPotId = doc.id;
          break;
        }
      }
    }

    final ops = <void Function(WriteBatch)>[
      (batch) => batch.set(toRef, BudgetMonth(id: toMonthId).toMap()),
    ];

    for (final doc in sources.docs) {
      ops.add(
        (batch) => batch.set(
          toRef.collection('incomeSources').doc(_uuid.v4()),
          doc.data(),
        ),
      );
    }

    var totalLeftover = 0.0;
    for (final doc in plans.docs) {
      // Fresh leftover total is written below; do not copy last month's pot plan.
      if (leftoverPotId != null && doc.id == leftoverPotId) continue;
      if (categoryIds != null) {
        final catId = subCategoryIds[doc.id] ?? '';
        if (!categoryIds.contains(catId)) continue;
      }
      final data = Map<String, dynamic>.from(doc.data());
      final total = subTotals[doc.id];
      final current = (data['installmentCurrent'] as num?)?.toInt();
      if (total != null && current != null && current < total) {
        data['installmentCurrent'] = current + 1;
      }
      if (rolloverLeftover && !savingsIds.contains(doc.id)) {
        final planned = (data['planned'] as num?)?.toDouble() ?? 0;
        final spent = spentBySub[doc.id] ?? 0;
        final leftover = planned - spent;
        if (leftover > 0) {
          totalLeftover += leftover;
        }
      }
      ops.add(
        (batch) => batch.set(toRef.collection('plans').doc(doc.id), data),
      );
    }

    for (final doc in expenses.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final subId = data['subcategoryId'] as String? ?? '';
      if (subId.isEmpty) continue;
      if (data['isDeposit'] == true || savingsIds.contains(subId)) continue;
      if (categoryIds != null) {
        final catId = subCategoryIds[subId] ?? '';
        if (!categoryIds.contains(catId)) continue;
      }
      final rawDate = data['date'] as String?;
      if (rawDate != null) {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) {
          data['date'] = dateFixedToMonth(parsed, toMonthId).toIso8601String();
        }
      }
      ops.add(
        (batch) => batch.set(
          toRef.collection('expenses').doc(_uuid.v4()),
          data,
        ),
      );
    }

    if (rolloverLeftover && totalLeftover > 0) {
      leftoverPotId ??= await _ensureLeftoverPot(
        householdId: householdId,
        categoryDocs: cats.docs,
        subcategoryDocs: subs.docs,
      );
      final potId = leftoverPotId;
      ops.add(
        (batch) => batch.set(
          toRef.collection('plans').doc(potId),
          {'planned': totalLeftover},
          SetOptions(merge: true),
        ),
      );
    }

    await _commitInChunks(ops);
    await applyRecurringBillsToMonth(
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
    required String type,
    required int sortOrder,
    double? targetAmount,
  }) async {
    final doc = await _categories(householdId).add({
      'nameEn': nameEn,
      'nameRu': nameRu,
      'colorValue': colorValue,
      'type': type,
      'sortOrder': sortOrder,
      'targetAmount': targetAmount,
      'savedTotal': 0,
    });
    return doc.id;
  }

  Future<void> incrementSavedTotal({
    required String householdId,
    required String subcategoryId,
    required double delta,
  }) async {
    if (delta == 0) return;
    await _subcategories(
      householdId,
    ).doc(subcategoryId).update({'savedTotal': FieldValue.increment(delta)});
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
          'type': cat.type,
          'sortOrder': sortOrder,
          'savedTotal': 0,
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
              'type': 'savings',
              'sortOrder': sortBase + added,
              'savedTotal': 0,
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
        ops.add(
          (batch) => batch.set(_subcategories(householdId).doc(_uuid.v4()), {
            'categoryId': savingsCatId,
            'nameEn': pot.nameEn,
            'nameRu': pot.nameRu,
            'sortOrder': sort,
            'archived': false,
            'savedTotal': 0,
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
    int? installmentTotal,
    double? targetAmount,
    DateTime? targetDate,
    bool includeInTotal = true,
    double savedTotal = 0,
  }) async {
    final doc = await _subcategories(householdId).add({
      'categoryId': categoryId,
      'nameEn': nameEn,
      'nameRu': nameRu,
      'sortOrder': sortOrder,
      'installmentTotal': installmentTotal,
      'archived': false,
      'targetAmount': targetAmount,
      'targetDate': targetDate?.toIso8601String(),
      'includeInTotal': includeInTotal,
      'savedTotal': savedTotal,
    });
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
  }) async {
    await _monthRef(householdId, monthId)
        .collection('plans')
        .doc(plan.subcategoryId)
        .set(plan.toMap(), SetOptions(merge: true));
  }

  Future<void> deletePlan({
    required String householdId,
    required String monthId,
    required String subcategoryId,
  }) async {
    await _monthRef(
      householdId,
      monthId,
    ).collection('plans').doc(subcategoryId).delete();
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
    bool isDeposit = false,
  }) async {
    final doc = await _monthRef(householdId, monthId)
        .collection('expenses')
        .add({
          'subcategoryId': subcategoryId,
          'amount': amount,
          'date': date.toIso8601String(),
          'note': note,
          'createdAt': DateTime.now().toIso8601String(),
          'createdBy': createdBy,
          'createdByName': createdByName,
          'isDeposit': isDeposit,
        });
    return doc.id;
  }

  Future<void> updateExpense({
    required String householdId,
    required String monthId,
    required Expense expense,
  }) async {
    await _monthRef(householdId, monthId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteExpense({
    required String householdId,
    required String monthId,
    required String expenseId,
  }) async {
    await _monthRef(
      householdId,
      monthId,
    ).collection('expenses').doc(expenseId).delete();
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
    await _monthRef(householdId, monthId).collection('incomeEntries').add({
      'sourceId': sourceId,
      'amount': amount,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
    });
  }

  Future<void> updateIncomeEntry({
    required String householdId,
    required String monthId,
    required IncomeEntry entry,
  }) async {
    await _monthRef(householdId, monthId)
        .collection('incomeEntries')
        .doc(entry.id)
        .set(entry.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteIncomeEntry({
    required String householdId,
    required String monthId,
    required String entryId,
  }) async {
    await _monthRef(
      householdId,
      monthId,
    ).collection('incomeEntries').doc(entryId).delete();
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
}
