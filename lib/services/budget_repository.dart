import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/seed_template.dart';
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
    final monthId = monthIdFromDate(DateTime.now());
    await seedMonth(household.id, monthId);
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

  Future<void> seedMonth(String householdId, String monthId) async {
    final monthRef = _monthRef(householdId, monthId);
    final existing = await monthRef.get();
    if (existing.exists) return;

    final batch = _db.batch();
    batch.set(monthRef, BudgetMonth(id: monthId).toMap());

    for (var i = 0; i < SeedTemplate.incomeSources.length; i++) {
      final source = SeedTemplate.incomeSources[i];
      final id = _uuid.v4();
      batch.set(monthRef.collection('incomeSources').doc(id), {
        'nameEn': source.nameEn,
        'nameRu': source.nameRu,
        'sortOrder': i,
      });
    }

    for (var c = 0; c < SeedTemplate.categories.length; c++) {
      final cat = SeedTemplate.categories[c];
      final catId = _uuid.v4();
      batch.set(monthRef.collection('categories').doc(catId), {
        'nameEn': cat.nameEn,
        'nameRu': cat.nameRu,
        'colorValue': cat.colorValue,
        'type': cat.type,
        'sortOrder': c,
      });
      for (var i = 0; i < cat.items.length; i++) {
        final item = cat.items[i];
        final itemId = _uuid.v4();
        batch.set(monthRef.collection('lineItems').doc(itemId), {
          'categoryId': catId,
          'descriptionEn': item.nameEn,
          'descriptionRu': item.nameRu,
          'planned': item.planned,
          'actual': 0.0,
          'installmentCurrent': item.installmentCurrent,
          'installmentTotal': item.installmentTotal,
          'sortOrder': i,
        });
      }
    }

    await batch.commit();
  }

  /// Copies planned amounts (and structure) from [fromMonthId] into [toMonthId].
  /// Actuals reset to 0. Income entries are not copied.
  Future<String> duplicateMonth({
    required String householdId,
    required String fromMonthId,
  }) async {
    final toMonthId = nextMonthId(fromMonthId);
    final fromRef = _monthRef(householdId, fromMonthId);
    final toRef = _monthRef(householdId, toMonthId);

    final existing = await toRef.get();
    if (existing.exists) {
      return toMonthId;
    }

    final sources = await fromRef.collection('incomeSources').get();
    final categories = await fromRef.collection('categories').get();
    final items = await fromRef.collection('lineItems').get();

    final batch = _db.batch();
    batch.set(toRef, BudgetMonth(id: toMonthId).toMap());

    final sourceIdMap = <String, String>{};
    for (final doc in sources.docs) {
      final newId = _uuid.v4();
      sourceIdMap[doc.id] = newId;
      batch.set(toRef.collection('incomeSources').doc(newId), doc.data());
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

    // silence unused
    sourceIdMap;

    await batch.commit();
    return toMonthId;
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

  Future<void> ensureMonthExists(String householdId, String monthId) async {
    final ref = _monthRef(householdId, monthId);
    final snap = await ref.get();
    if (!snap.exists) {
      await seedMonth(householdId, monthId);
    }
  }
}
