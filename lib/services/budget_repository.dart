import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../utils/money.dart';

class BudgetRepository {
  BudgetRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _months(String householdId) =>
      _db.collection('households').doc(householdId).collection('months');

  DocumentReference<Map<String, dynamic>> _monthRef(
    String householdId,
    String monthId,
  ) =>
      _months(householdId).doc(monthId);

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
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
    await ref.set(household.toMap());
    await _db.collection('users').doc(creatorUid).update({
      'householdId': household.id,
    });
    // v2: no auto-seeded month or categories
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

  Stream<Household?> watchHousehold(String householdId) {
    return _db.collection('households').doc(householdId).snapshots().map((s) {
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

  /// Creates an empty month (no categories, income, or line items).
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

  /// Copies structure from [fromMonthId] into [toMonthId].
  /// Actuals reset to 0. Income entry amounts are not copied.
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
    final categories = await fromRef.collection('categories').get();
    final items = await fromRef.collection('lineItems').get();

    final batch = _db.batch();
    batch.set(toRef, BudgetMonth(id: toMonthId).toMap());

    for (final doc in sources.docs) {
      batch.set(
        toRef.collection('incomeSources').doc(_uuid.v4()),
        doc.data(),
      );
    }

    final categoryIdMap = <String, String>{};
    for (final doc in categories.docs) {
      final newId = _uuid.v4();
      categoryIdMap[doc.id] = newId;
      batch.set(toRef.collection('categories').doc(newId), doc.data());
    }

    for (final doc in items.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final oldCat = data['categoryId'] as String?;
      data['categoryId'] = categoryIdMap[oldCat] ?? oldCat;
      data['actual'] = 0.0;
      batch.set(toRef.collection('lineItems').doc(_uuid.v4()), data);
    }

    await batch.commit();
  }

  /// Convenience: copy current month into the next calendar month.
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

  Future<void> addCategory({
    required String householdId,
    required String monthId,
    required String nameEn,
    required String nameRu,
    required int colorValue,
    required String type,
    required int sortOrder,
  }) async {
    await _monthRef(householdId, monthId).collection('categories').add({
      'nameEn': nameEn,
      'nameRu': nameRu,
      'colorValue': colorValue,
      'type': type,
      'sortOrder': sortOrder,
    });
  }

  Future<void> updateCategory({
    required String householdId,
    required String monthId,
    required BudgetCategory category,
  }) async {
    await _monthRef(householdId, monthId)
        .collection('categories')
        .doc(category.id)
        .set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCategory({
    required String householdId,
    required String monthId,
    required String categoryId,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final items = await monthRef
        .collection('lineItems')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final batch = _db.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(monthRef.collection('categories').doc(categoryId));
    await batch.commit();
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

  Stream<List<BudgetCategory>> watchCategories(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('categories')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => BudgetCategory.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<LineItem>> watchLineItems(
    String householdId,
    String monthId,
  ) {
    return _monthRef(householdId, monthId)
        .collection('lineItems')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => LineItem.fromMap(d.id, d.data())).toList(),
        );
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

  Future<void> addIncomeSource({
    required String householdId,
    required String monthId,
    required String nameEn,
    required String nameRu,
    required int sortOrder,
  }) async {
    await _monthRef(householdId, monthId).collection('incomeSources').add({
      'nameEn': nameEn,
      'nameRu': nameRu,
      'sortOrder': sortOrder,
    });
  }

  Future<void> upsertLineItem({
    required String householdId,
    required String monthId,
    required LineItem item,
  }) async {
    await _monthRef(householdId, monthId)
        .collection('lineItems')
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> createLineItem({
    required String householdId,
    required String monthId,
    required String categoryId,
    required String descriptionEn,
    required String descriptionRu,
    required double planned,
    double actual = 0,
    int? installmentCurrent,
    int? installmentTotal,
  }) async {
    await _monthRef(householdId, monthId).collection('lineItems').add({
      'categoryId': categoryId,
      'descriptionEn': descriptionEn,
      'descriptionRu': descriptionRu,
      'planned': planned,
      'actual': actual,
      'installmentCurrent': installmentCurrent,
      'installmentTotal': installmentTotal,
      'sortOrder': 999,
    });
  }

  Future<void> deleteLineItem({
    required String householdId,
    required String monthId,
    required String itemId,
  }) async {
    await _monthRef(householdId, monthId)
        .collection('lineItems')
        .doc(itemId)
        .delete();
  }
}
