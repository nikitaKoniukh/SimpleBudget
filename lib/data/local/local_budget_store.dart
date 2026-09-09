import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/models.dart';
import 'database.dart';

const kColHousehold = 'household';
const kColCategories = 'categories';
const kColSubcategories = 'subcategories';
const kColBills = 'recurringBills';
const kColLoans = 'loans';
const kColMonths = 'months';
const kColIncomeSources = 'incomeSources';
const kColIncomeEntries = 'incomeEntries';
const kColPlans = 'plans';
const kColExpenses = 'expenses';
const kColDeposits = 'deposits';
const kColPotBalances = 'potBalances';
const kColLoanPayments = 'loanPayments';

class LocalCatalog {
  const LocalCatalog({
    this.household,
    this.categories = const [],
    this.subcategories = const [],
    this.bills = const [],
    this.loans = const [],
    this.months = const [],
  });

  final Household? household;
  final List<BudgetCategory> categories;
  final List<Subcategory> subcategories;
  final List<RecurringBill> bills;
  final List<Loan> loans;
  final List<BudgetMonth> months;
}

class LocalMonthBundle {
  const LocalMonthBundle({
    this.month,
    this.incomeSources = const [],
    this.incomeEntries = const [],
    this.plans = const [],
    this.expenses = const [],
    this.deposits = const [],
    this.potBalances = const [],
    this.loanPayments = const [],
  });

  final BudgetMonth? month;
  final List<IncomeSource> incomeSources;
  final List<IncomeEntry> incomeEntries;
  final List<MonthPlan> plans;
  final List<Expense> expenses;
  final List<Deposit> deposits;
  final List<PotBalance> potBalances;
  final List<LoanPayment> loanPayments;
}

class LocalBudgetStore {
  LocalBudgetStore(this.db);

  final LocalBudgetDatabase db;

  static LocalBudgetStore? _instance;

  static LocalBudgetStore get instance =>
      _instance ??= LocalBudgetStore(LocalBudgetDatabase());

  static LocalBudgetStore memory() =>
      LocalBudgetStore(LocalBudgetDatabase.memory());

  Future<void> replaceHouseholdCollection({
    required String householdId,
    required String collection,
    required Map<String, Map<String, dynamic>> docs,
  }) async {
    await db.transaction(() async {
      await (db.delete(db.householdDocs)
            ..where(
              (t) =>
                  t.householdId.equals(householdId) &
                  t.collection.equals(collection),
            ))
          .go();
      if (docs.isEmpty) return;
      await db.batch((batch) {
        for (final e in docs.entries) {
          batch.insert(
            db.householdDocs,
            HouseholdDocsCompanion.insert(
              householdId: householdId,
              collection: collection,
              docId: e.key,
              payload: jsonEncode(e.value),
            ),
          );
        }
      });
    });
  }

  Future<void> replaceMonthCollection({
    required String householdId,
    required String monthId,
    required String collection,
    required Map<String, Map<String, dynamic>> docs,
  }) async {
    await db.transaction(() async {
      await (db.delete(db.monthDocs)
            ..where(
              (t) =>
                  t.householdId.equals(householdId) &
                  t.monthId.equals(monthId) &
                  t.collection.equals(collection),
            ))
          .go();
      if (docs.isEmpty) return;
      await db.batch((batch) {
        for (final e in docs.entries) {
          batch.insert(
            db.monthDocs,
            MonthDocsCompanion.insert(
              householdId: householdId,
              monthId: monthId,
              collection: collection,
              docId: e.key,
              payload: jsonEncode(e.value),
            ),
          );
        }
      });
    });
  }

  Future<void> upsertHouseholdDoc({
    required String householdId,
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    return db.into(db.householdDocs).insertOnConflictUpdate(
          HouseholdDocsCompanion.insert(
            householdId: householdId,
            collection: collection,
            docId: docId,
            payload: jsonEncode(data),
          ),
        );
  }

  Future<List<Map<String, dynamic>>> _householdMaps(
    String householdId,
    String collection,
  ) async {
    final rows = await (db.select(db.householdDocs)
          ..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.collection.equals(collection),
          ))
        .get();
    return [
      for (final row in rows)
        {'id': row.docId, ...Map<String, dynamic>.from(jsonDecode(row.payload))},
    ];
  }

  Future<List<Map<String, dynamic>>> _monthMaps(
    String householdId,
    String monthId,
    String collection,
  ) async {
    final rows = await (db.select(db.monthDocs)
          ..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.monthId.equals(monthId) &
                t.collection.equals(collection),
          ))
        .get();
    return [
      for (final row in rows)
        {'id': row.docId, ...Map<String, dynamic>.from(jsonDecode(row.payload))},
    ];
  }

  Future<LocalCatalog> loadCatalog(String householdId) async {
    final householdRows = await _householdMaps(householdId, kColHousehold);
    Household? household;
    if (householdRows.isNotEmpty) {
      final map = Map<String, dynamic>.from(householdRows.first)..remove('id');
      household = Household.fromMap(householdId, map);
    }
    final categories = [
      for (final m in await _householdMaps(householdId, kColCategories))
        BudgetCategory.fromMap(m['id'] as String, m),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final subcategories = [
      for (final m in await _householdMaps(householdId, kColSubcategories))
        Subcategory.fromMap(m['id'] as String, m),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final bills = [
      for (final m in await _householdMaps(householdId, kColBills))
        RecurringBill.fromMap(m['id'] as String, m),
    ];
    final loans = [
      for (final m in await _householdMaps(householdId, kColLoans))
        Loan.fromMap(m['id'] as String, m),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final months = [
      for (final m in await _householdMaps(householdId, kColMonths))
        BudgetMonth.fromMap(m['id'] as String, m),
    ]..sort((a, b) => b.id.compareTo(a.id));
    return LocalCatalog(
      household: household,
      categories: categories,
      subcategories: subcategories,
      bills: bills,
      loans: loans,
      months: months,
    );
  }

  Future<LocalMonthBundle?> loadMonth(String householdId, String monthId) async {
    final monthRows = await _monthMaps(householdId, monthId, kColMonths);
    final synced = await isMonthSynced(householdId, monthId);
    if (monthRows.isEmpty && !synced) return null;

    BudgetMonth? month;
    if (monthRows.isNotEmpty) {
      final map = Map<String, dynamic>.from(monthRows.first)..remove('id');
      month = BudgetMonth.fromMap(monthId, map);
    } else {
      final summaries = await _householdMaps(householdId, kColMonths);
      for (final m in summaries) {
        if (m['id'] == monthId) {
          month = BudgetMonth.fromMap(monthId, m);
          break;
        }
      }
    }

    return LocalMonthBundle(
      month: month,
      incomeSources: [
        for (final m in await _monthMaps(householdId, monthId, kColIncomeSources))
          IncomeSource.fromMap(m['id'] as String, m),
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      incomeEntries: [
        for (final m in await _monthMaps(householdId, monthId, kColIncomeEntries))
          IncomeEntry.fromMap(m['id'] as String, m),
      ],
      plans: [
        for (final m in await _monthMaps(householdId, monthId, kColPlans))
          MonthPlan.fromMap(m['id'] as String, m),
      ],
      expenses: [
        for (final m in await _monthMaps(householdId, monthId, kColExpenses))
          Expense.fromMap(m['id'] as String, m),
      ],
      deposits: [
        for (final m in await _monthMaps(householdId, monthId, kColDeposits))
          Deposit.fromMap(m['id'] as String, m),
      ],
      potBalances: [
        for (final m in await _monthMaps(householdId, monthId, kColPotBalances))
          PotBalance.fromMap(m['id'] as String, m),
      ],
      loanPayments: [
        for (final m in await _monthMaps(householdId, monthId, kColLoanPayments))
          LoanPayment.fromMap(m['id'] as String, m),
      ],
    );
  }

  Future<bool> hasMonthSummary(String householdId, String monthId) async {
    final rows = await (db.select(db.householdDocs)
          ..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.collection.equals(kColMonths) &
                t.docId.equals(monthId),
          ))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> setMeta(String key, String value) {
    return db.into(db.syncMetaRows).insertOnConflictUpdate(
          SyncMetaRowsCompanion.insert(
            key: key,
            value: value,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<String?> getMeta(String key) async {
    final row = await (db.select(db.syncMetaRows)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> markMonthSynced(String householdId, String monthId) {
    return setMeta('month-synced:$householdId:$monthId', '1');
  }

  Future<bool> isMonthSynced(String householdId, String monthId) async {
    return await getMeta('month-synced:$householdId:$monthId') == '1';
  }

  Future<int> enqueueOutbox(String op, Map<String, dynamic> payload) {
    return db.into(db.outboxRows).insert(
          OutboxRowsCompanion.insert(
            op: op,
            payload: jsonEncode(payload),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> markOutboxDone(int id) {
    return (db.update(db.outboxRows)..where((t) => t.id.equals(id))).write(
      const OutboxRowsCompanion(status: Value('done')),
    );
  }

  Future<void> markOutboxFailed(int id) {
    return (db.update(db.outboxRows)..where((t) => t.id.equals(id))).write(
      const OutboxRowsCompanion(status: Value('failed')),
    );
  }

  Future<List<OutboxRow>> pendingOutbox() {
    return (db.select(db.outboxRows)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }
}

List<BudgetMonth> mergeMonthSummaries(
  List<BudgetMonth> local,
  List<BudgetMonth> live,
) {
  final byId = {for (final m in local) m.id: m};
  for (final m in live) {
    byId[m.id] = m;
  }
  return byId.values.toList()..sort((a, b) => b.id.compareTo(a.id));
}
