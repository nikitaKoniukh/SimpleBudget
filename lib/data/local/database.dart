import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class HouseholdDocs extends Table {
  TextColumn get householdId => text()();
  TextColumn get collection => text()();
  TextColumn get docId => text()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {householdId, collection, docId};
}

class MonthDocs extends Table {
  TextColumn get householdId => text()();
  TextColumn get monthId => text()();
  TextColumn get collection => text()();
  TextColumn get docId => text()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {householdId, monthId, collection, docId};
}

class SyncMetaRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class OutboxRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [HouseholdDocs, MonthDocs, SyncMetaRows, OutboxRows])
class LocalBudgetDatabase extends _$LocalBudgetDatabase {
  LocalBudgetDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'sync_month'));

  LocalBudgetDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
