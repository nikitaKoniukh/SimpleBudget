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
  ) =>
      _months(householdId).doc(monthId);

  CollectionReference<Map<String, dynamic>> _categories(String householdId) =>
      _householdRef(householdId).collection('categories');

  CollectionReference<Map<String, dynamic>> _subcategories(
    String householdId,
  ) =>
      _householdRef(householdId).collection('subcategories');

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
  }) async {
    final ref = _db.collection('households').doc();
    final household = Household(
      id: ref.id,
      name: name.trim(),
      memberIds: [creatorUid],
      inviteCode: _generateInviteCode(),
      createdBy: creatorUid,
    );
    await ref.set({
      ...household.toMap(),
      'catalogVersion': 2,
    });
    await _db.collection('users').doc(creatorUid).update({
      'householdId': household.id,
    });
    return household;
  }

  Future<Household> joinHousehold({
    required String inviteCode,
    required String uid,
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
      await doc.reference.update({'memberIds': members});
    }
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
  }

  /// Copies income sources and plans. Expenses are not copied.
  /// Installment current ticks up when it is below the subcategory total.
  Future<void> createMonthFromCopy({
    required String householdId,
    required String fromMonthId,
    required String toMonthId,
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
    final subs = await _subcategories(householdId).get();
    final subTotals = <String, int?>{
      for (final doc in subs.docs)
        doc.id: (doc.data()['installmentTotal'] as num?)?.toInt(),
    };

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

    for (final doc in plans.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final total = subTotals[doc.id];
      final current = (data['installmentCurrent'] as num?)?.toInt();
      if (total != null && current != null && current < total) {
        data['installmentCurrent'] = current + 1;
      }
      ops.add(
        (batch) => batch.set(toRef.collection('plans').doc(doc.id), data),
      );
    }

    await _commitInChunks(ops);
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
    return _categories(householdId).orderBy('sortOrder').snapshots().map(
          (s) => s.docs
              .map((d) => BudgetCategory.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<Subcategory>> watchSubcategories(String householdId) {
    return _subcategories(householdId).orderBy('sortOrder').snapshots().map(
          (s) => s.docs
              .map((d) => Subcategory.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<MonthPlan>> watchPlans(String householdId, String monthId) {
    return _monthRef(householdId, monthId).collection('plans').snapshots().map(
          (s) =>
              s.docs.map((d) => MonthPlan.fromMap(d.id, d.data())).toList(),
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

  Stream<List<IncomeSource>> watchIncomeSources(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('incomeSources')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => IncomeSource.fromMap(d.id, d.data()))
              .toList(),
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
  }) async {
    final doc = await _categories(householdId).add({
      'nameEn': nameEn,
      'nameRu': nameRu,
      'colorValue': colorValue,
      'type': type,
      'sortOrder': sortOrder,
    });
    return doc.id;
  }

  Future<void> updateCategory({
    required String householdId,
    required BudgetCategory category,
  }) async {
    await _categories(householdId)
        .doc(category.id)
        .set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCategory({
    required String householdId,
    required String categoryId,
  }) async {
    final subs = await _subcategories(householdId)
        .where('categoryId', isEqualTo: categoryId)
        .get();
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
    for (final cat in toAdd) {
      if (existingNames.contains(cat.nameEn.toLowerCase())) continue;
      final sortOrder = sortBase + added;
      ops.add(
        (batch) => batch.set(_categories(householdId).doc(_uuid.v4()), {
          'nameEn': cat.nameEn,
          'nameRu': cat.nameRu,
          'colorValue': cat.colorValue,
          'type': cat.type,
          'sortOrder': sortOrder,
        }),
      );
      added++;
    }
    if (ops.isNotEmpty) {
      await _commitInChunks(ops);
    }
    return added;
  }

  Future<String> addSubcategory({
    required String householdId,
    required String categoryId,
    required String nameEn,
    required String nameRu,
    required int sortOrder,
    int? installmentTotal,
  }) async {
    final doc = await _subcategories(householdId).add({
      'categoryId': categoryId,
      'nameEn': nameEn,
      'nameRu': nameRu,
      'sortOrder': sortOrder,
      'installmentTotal': installmentTotal,
      'archived': false,
    });
    return doc.id;
  }

  Future<void> updateSubcategory({
    required String householdId,
    required Subcategory subcategory,
  }) async {
    await _subcategories(householdId)
        .doc(subcategory.id)
        .set(subcategory.toMap(), SetOptions(merge: true));
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
    await _monthRef(householdId, monthId)
        .collection('plans')
        .doc(subcategoryId)
        .delete();
  }

  Future<String> addExpense({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final doc = await _monthRef(householdId, monthId).collection('expenses').add({
      'subcategoryId': subcategoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
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
    await _monthRef(householdId, monthId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Future<void> addIncomeEntry({
    required String householdId,
    required String monthId,
    required String sourceId,
    required double amount,
    String? note,
  }) async {
    await _monthRef(householdId, monthId).collection('incomeEntries').add({
      'sourceId': sourceId,
      'amount': amount,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
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
    await _monthRef(householdId, monthId)
        .collection('incomeEntries')
        .doc(entryId)
        .delete();
  }

  Future<String> addIncomeSource({
    required String householdId,
    required String monthId,
    required String nameEn,
    required String nameRu,
    required int sortOrder,
  }) async {
    final doc =
        await _monthRef(householdId, monthId).collection('incomeSources').add({
      'nameEn': nameEn,
      'nameRu': nameRu,
      'sortOrder': sortOrder,
    });
    return doc.id;
  }

  /// Promotes per-month categories/lineItems into the household catalog.
  Future<void> migrateLegacyCatalogIfNeeded(String householdId) async {
    final householdRef = _householdRef(householdId);
    final householdSnap = await householdRef.get();
    final version =
        (householdSnap.data()?['catalogVersion'] as num?)?.toInt() ?? 0;
    if (version >= 2) return;

    final existingCats = await _categories(householdId).limit(1).get();
    if (existingCats.docs.isNotEmpty) {
      await householdRef.set({'catalogVersion': 2}, SetOptions(merge: true));
      return;
    }

    final monthsSnap = await _months(householdId).get();
    if (monthsSnap.docs.isEmpty) {
      await householdRef.set({'catalogVersion': 2}, SetOptions(merge: true));
      return;
    }

    final monthCats = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    final monthItems = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    var hasLegacy = false;
    for (final monthDoc in monthsSnap.docs) {
      final cats = await monthDoc.reference.collection('categories').get();
      final items = await monthDoc.reference.collection('lineItems').get();
      monthCats[monthDoc.id] = cats.docs;
      monthItems[monthDoc.id] = items.docs;
      if (cats.docs.isNotEmpty || items.docs.isNotEmpty) {
        hasLegacy = true;
      }
    }
    if (!hasLegacy) {
      await householdRef.set({'catalogVersion': 2}, SetOptions(merge: true));
      return;
    }

    final nameToCatId = <String, String>{};
    final oldCatToNew = <String, String>{};
    final ops = <void Function(WriteBatch)>[];
    var catSort = 0;

    for (final monthDoc in monthsSnap.docs) {
      for (final catDoc in monthCats[monthDoc.id] ?? const []) {
        final data = catDoc.data();
        final nameEn = (data['nameEn'] as String? ?? '').trim();
        final key = nameEn.toLowerCase();
        if (key.isEmpty) continue;
        var newId = nameToCatId[key];
        if (newId == null) {
          newId = _uuid.v4();
          nameToCatId[key] = newId;
          final createdId = newId;
          final sort = catSort;
          ops.add(
            (batch) => batch.set(_categories(householdId).doc(createdId), {
              'nameEn': nameEn,
              'nameRu': data['nameRu'] as String? ?? nameEn,
              'colorValue': (data['colorValue'] as num?)?.toInt() ?? 0xFFBDBDBD,
              'type': data['type'] as String? ?? 'expense',
              'sortOrder': sort,
            }),
          );
          catSort++;
        }
        oldCatToNew['${monthDoc.id}:${catDoc.id}'] = newId;
      }
    }

    final subKeyToId = <String, String>{};
    var subSort = 0;

    for (final monthDoc in monthsSnap.docs) {
      final monthStart = dateFromMonthId(monthDoc.id);
      for (final itemDoc in monthItems[monthDoc.id] ?? const []) {
        final data = itemDoc.data();
        final oldCatId = data['categoryId'] as String? ?? '';
        final newCatId = oldCatToNew['${monthDoc.id}:$oldCatId'];
        if (newCatId == null) continue;
        final descEn = (data['descriptionEn'] as String? ?? '').trim();
        final descRu = (data['descriptionRu'] as String? ?? descEn).trim();
        final label = descEn.isEmpty ? 'Item' : descEn;
        final subKey = '$newCatId::${label.toLowerCase()}';
        var subId = subKeyToId[subKey];
        if (subId == null) {
          subId = _uuid.v4();
          subKeyToId[subKey] = subId;
          final createdSubId = subId;
          final sort = subSort;
          ops.add(
            (batch) => batch.set(_subcategories(householdId).doc(createdSubId), {
              'categoryId': newCatId,
              'nameEn': label,
              'nameRu': descRu.isEmpty ? label : descRu,
              'installmentTotal':
                  (data['installmentTotal'] as num?)?.toInt(),
              'sortOrder': sort,
              'archived': false,
            }),
          );
          subSort++;
        }

        final planSubId = subId;
        final planned = (data['planned'] as num?)?.toDouble() ?? 0;
        final installmentCurrent =
            (data['installmentCurrent'] as num?)?.toInt();
        ops.add(
          (batch) => batch.set(
            monthDoc.reference.collection('plans').doc(planSubId),
            {
              'planned': planned,
              'installmentCurrent': installmentCurrent,
            },
          ),
        );

        final actual = (data['actual'] as num?)?.toDouble() ?? 0;
        if (actual > 0) {
          ops.add(
            (batch) => batch.set(
              monthDoc.reference.collection('expenses').doc(_uuid.v4()),
              {
                'subcategoryId': planSubId,
                'amount': actual,
                'date': monthStart.toIso8601String(),
                'note': label,
                'createdAt': DateTime.now().toIso8601String(),
              },
            ),
          );
        }
      }
    }

    await _commitInChunks(ops);
    await householdRef.set({'catalogVersion': 2}, SetOptions(merge: true));
  }
}
