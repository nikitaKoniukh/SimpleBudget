// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HouseholdDocsTable extends HouseholdDocs
    with TableInfo<$HouseholdDocsTable, HouseholdDoc> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdDocsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docIdMeta = const VerificationMeta('docId');
  @override
  late final GeneratedColumn<String> docId = GeneratedColumn<String>(
    'doc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    householdId,
    collection,
    docId,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_docs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HouseholdDoc> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('doc_id')) {
      context.handle(
        _docIdMeta,
        docId.isAcceptableOrUnknown(data['doc_id']!, _docIdMeta),
      );
    } else if (isInserting) {
      context.missing(_docIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {householdId, collection, docId};
  @override
  HouseholdDoc map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdDoc(
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      docId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $HouseholdDocsTable createAlias(String alias) {
    return $HouseholdDocsTable(attachedDatabase, alias);
  }
}

class HouseholdDoc extends DataClass implements Insertable<HouseholdDoc> {
  final String householdId;
  final String collection;
  final String docId;
  final String payload;
  const HouseholdDoc({
    required this.householdId,
    required this.collection,
    required this.docId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['household_id'] = Variable<String>(householdId);
    map['collection'] = Variable<String>(collection);
    map['doc_id'] = Variable<String>(docId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  HouseholdDocsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdDocsCompanion(
      householdId: Value(householdId),
      collection: Value(collection),
      docId: Value(docId),
      payload: Value(payload),
    );
  }

  factory HouseholdDoc.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdDoc(
      householdId: serializer.fromJson<String>(json['householdId']),
      collection: serializer.fromJson<String>(json['collection']),
      docId: serializer.fromJson<String>(json['docId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'householdId': serializer.toJson<String>(householdId),
      'collection': serializer.toJson<String>(collection),
      'docId': serializer.toJson<String>(docId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  HouseholdDoc copyWith({
    String? householdId,
    String? collection,
    String? docId,
    String? payload,
  }) => HouseholdDoc(
    householdId: householdId ?? this.householdId,
    collection: collection ?? this.collection,
    docId: docId ?? this.docId,
    payload: payload ?? this.payload,
  );
  HouseholdDoc copyWithCompanion(HouseholdDocsCompanion data) {
    return HouseholdDoc(
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      docId: data.docId.present ? data.docId.value : this.docId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdDoc(')
          ..write('householdId: $householdId, ')
          ..write('collection: $collection, ')
          ..write('docId: $docId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(householdId, collection, docId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdDoc &&
          other.householdId == this.householdId &&
          other.collection == this.collection &&
          other.docId == this.docId &&
          other.payload == this.payload);
}

class HouseholdDocsCompanion extends UpdateCompanion<HouseholdDoc> {
  final Value<String> householdId;
  final Value<String> collection;
  final Value<String> docId;
  final Value<String> payload;
  final Value<int> rowid;
  const HouseholdDocsCompanion({
    this.householdId = const Value.absent(),
    this.collection = const Value.absent(),
    this.docId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdDocsCompanion.insert({
    required String householdId,
    required String collection,
    required String docId,
    required String payload,
    this.rowid = const Value.absent(),
  }) : householdId = Value(householdId),
       collection = Value(collection),
       docId = Value(docId),
       payload = Value(payload);
  static Insertable<HouseholdDoc> custom({
    Expression<String>? householdId,
    Expression<String>? collection,
    Expression<String>? docId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (householdId != null) 'household_id': householdId,
      if (collection != null) 'collection': collection,
      if (docId != null) 'doc_id': docId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdDocsCompanion copyWith({
    Value<String>? householdId,
    Value<String>? collection,
    Value<String>? docId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return HouseholdDocsCompanion(
      householdId: householdId ?? this.householdId,
      collection: collection ?? this.collection,
      docId: docId ?? this.docId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (docId.present) {
      map['doc_id'] = Variable<String>(docId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdDocsCompanion(')
          ..write('householdId: $householdId, ')
          ..write('collection: $collection, ')
          ..write('docId: $docId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthDocsTable extends MonthDocs
    with TableInfo<$MonthDocsTable, MonthDoc> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthDocsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<String> monthId = GeneratedColumn<String>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docIdMeta = const VerificationMeta('docId');
  @override
  late final GeneratedColumn<String> docId = GeneratedColumn<String>(
    'doc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    householdId,
    monthId,
    collection,
    docId,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'month_docs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthDoc> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('doc_id')) {
      context.handle(
        _docIdMeta,
        docId.isAcceptableOrUnknown(data['doc_id']!, _docIdMeta),
      );
    } else if (isInserting) {
      context.missing(_docIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    householdId,
    monthId,
    collection,
    docId,
  };
  @override
  MonthDoc map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthDoc(
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_id'],
      )!,
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      docId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $MonthDocsTable createAlias(String alias) {
    return $MonthDocsTable(attachedDatabase, alias);
  }
}

class MonthDoc extends DataClass implements Insertable<MonthDoc> {
  final String householdId;
  final String monthId;
  final String collection;
  final String docId;
  final String payload;
  const MonthDoc({
    required this.householdId,
    required this.monthId,
    required this.collection,
    required this.docId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['household_id'] = Variable<String>(householdId);
    map['month_id'] = Variable<String>(monthId);
    map['collection'] = Variable<String>(collection);
    map['doc_id'] = Variable<String>(docId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  MonthDocsCompanion toCompanion(bool nullToAbsent) {
    return MonthDocsCompanion(
      householdId: Value(householdId),
      monthId: Value(monthId),
      collection: Value(collection),
      docId: Value(docId),
      payload: Value(payload),
    );
  }

  factory MonthDoc.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthDoc(
      householdId: serializer.fromJson<String>(json['householdId']),
      monthId: serializer.fromJson<String>(json['monthId']),
      collection: serializer.fromJson<String>(json['collection']),
      docId: serializer.fromJson<String>(json['docId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'householdId': serializer.toJson<String>(householdId),
      'monthId': serializer.toJson<String>(monthId),
      'collection': serializer.toJson<String>(collection),
      'docId': serializer.toJson<String>(docId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  MonthDoc copyWith({
    String? householdId,
    String? monthId,
    String? collection,
    String? docId,
    String? payload,
  }) => MonthDoc(
    householdId: householdId ?? this.householdId,
    monthId: monthId ?? this.monthId,
    collection: collection ?? this.collection,
    docId: docId ?? this.docId,
    payload: payload ?? this.payload,
  );
  MonthDoc copyWithCompanion(MonthDocsCompanion data) {
    return MonthDoc(
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      docId: data.docId.present ? data.docId.value : this.docId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthDoc(')
          ..write('householdId: $householdId, ')
          ..write('monthId: $monthId, ')
          ..write('collection: $collection, ')
          ..write('docId: $docId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(householdId, monthId, collection, docId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthDoc &&
          other.householdId == this.householdId &&
          other.monthId == this.monthId &&
          other.collection == this.collection &&
          other.docId == this.docId &&
          other.payload == this.payload);
}

class MonthDocsCompanion extends UpdateCompanion<MonthDoc> {
  final Value<String> householdId;
  final Value<String> monthId;
  final Value<String> collection;
  final Value<String> docId;
  final Value<String> payload;
  final Value<int> rowid;
  const MonthDocsCompanion({
    this.householdId = const Value.absent(),
    this.monthId = const Value.absent(),
    this.collection = const Value.absent(),
    this.docId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthDocsCompanion.insert({
    required String householdId,
    required String monthId,
    required String collection,
    required String docId,
    required String payload,
    this.rowid = const Value.absent(),
  }) : householdId = Value(householdId),
       monthId = Value(monthId),
       collection = Value(collection),
       docId = Value(docId),
       payload = Value(payload);
  static Insertable<MonthDoc> custom({
    Expression<String>? householdId,
    Expression<String>? monthId,
    Expression<String>? collection,
    Expression<String>? docId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (householdId != null) 'household_id': householdId,
      if (monthId != null) 'month_id': monthId,
      if (collection != null) 'collection': collection,
      if (docId != null) 'doc_id': docId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthDocsCompanion copyWith({
    Value<String>? householdId,
    Value<String>? monthId,
    Value<String>? collection,
    Value<String>? docId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return MonthDocsCompanion(
      householdId: householdId ?? this.householdId,
      monthId: monthId ?? this.monthId,
      collection: collection ?? this.collection,
      docId: docId ?? this.docId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<String>(monthId.value);
    }
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (docId.present) {
      map['doc_id'] = Variable<String>(docId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthDocsCompanion(')
          ..write('householdId: $householdId, ')
          ..write('monthId: $monthId, ')
          ..write('collection: $collection, ')
          ..write('docId: $docId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaRowsTable extends SyncMetaRows
    with TableInfo<$SyncMetaRowsTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncMetaRowsTable createAlias(String alias) {
    return $SyncMetaRowsTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SyncMetaRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncMetaRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaRowsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncMetaRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      SyncMetaRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncMetaRow copyWithCompanion(SyncMetaRowsCompanion data) {
    return SyncMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncMetaRowsCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncMetaRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaRowsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SyncMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncMetaRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxRowsTable extends OutboxRows
    with TableInfo<$OutboxRowsTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, op, payload, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxRowsTable createAlias(String alias) {
    return $OutboxRowsTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String op;
  final String payload;
  final String status;
  final DateTime createdAt;
  const OutboxRow({
    required this.id,
    required this.op,
    required this.payload,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxRowsCompanion toCompanion(bool nullToAbsent) {
    return OutboxRowsCompanion(
      id: Value(id),
      op: Value(op),
      payload: Value(payload),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? op,
    String? payload,
    String? status,
    DateTime? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxRowsCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, op, payload, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class OutboxRowsCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> op;
  final Value<String> payload;
  final Value<String> status;
  final Value<DateTime> createdAt;
  const OutboxRowsCompanion({
    this.id = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxRowsCompanion.insert({
    this.id = const Value.absent(),
    required String op,
    required String payload,
    this.status = const Value.absent(),
    required DateTime createdAt,
  }) : op = Value(op),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? op,
    Value<String>? payload,
    Value<String>? status,
    Value<DateTime>? createdAt,
  }) {
    return OutboxRowsCompanion(
      id: id ?? this.id,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRowsCompanion(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalBudgetDatabase extends GeneratedDatabase {
  _$LocalBudgetDatabase(QueryExecutor e) : super(e);
  $LocalBudgetDatabaseManager get managers => $LocalBudgetDatabaseManager(this);
  late final $HouseholdDocsTable householdDocs = $HouseholdDocsTable(this);
  late final $MonthDocsTable monthDocs = $MonthDocsTable(this);
  late final $SyncMetaRowsTable syncMetaRows = $SyncMetaRowsTable(this);
  late final $OutboxRowsTable outboxRows = $OutboxRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    householdDocs,
    monthDocs,
    syncMetaRows,
    outboxRows,
  ];
}

typedef $$HouseholdDocsTableCreateCompanionBuilder =
    HouseholdDocsCompanion Function({
      required String householdId,
      required String collection,
      required String docId,
      required String payload,
      Value<int> rowid,
    });
typedef $$HouseholdDocsTableUpdateCompanionBuilder =
    HouseholdDocsCompanion Function({
      Value<String> householdId,
      Value<String> collection,
      Value<String> docId,
      Value<String> payload,
      Value<int> rowid,
    });

class $$HouseholdDocsTableFilterComposer
    extends Composer<_$LocalBudgetDatabase, $HouseholdDocsTable> {
  $$HouseholdDocsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HouseholdDocsTableOrderingComposer
    extends Composer<_$LocalBudgetDatabase, $HouseholdDocsTable> {
  $$HouseholdDocsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdDocsTableAnnotationComposer
    extends Composer<_$LocalBudgetDatabase, $HouseholdDocsTable> {
  $$HouseholdDocsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get docId =>
      $composableBuilder(column: $table.docId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$HouseholdDocsTableTableManager
    extends
        RootTableManager<
          _$LocalBudgetDatabase,
          $HouseholdDocsTable,
          HouseholdDoc,
          $$HouseholdDocsTableFilterComposer,
          $$HouseholdDocsTableOrderingComposer,
          $$HouseholdDocsTableAnnotationComposer,
          $$HouseholdDocsTableCreateCompanionBuilder,
          $$HouseholdDocsTableUpdateCompanionBuilder,
          (
            HouseholdDoc,
            BaseReferences<
              _$LocalBudgetDatabase,
              $HouseholdDocsTable,
              HouseholdDoc
            >,
          ),
          HouseholdDoc,
          PrefetchHooks Function()
        > {
  $$HouseholdDocsTableTableManager(
    _$LocalBudgetDatabase db,
    $HouseholdDocsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdDocsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdDocsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdDocsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> householdId = const Value.absent(),
                Value<String> collection = const Value.absent(),
                Value<String> docId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdDocsCompanion(
                householdId: householdId,
                collection: collection,
                docId: docId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String householdId,
                required String collection,
                required String docId,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => HouseholdDocsCompanion.insert(
                householdId: householdId,
                collection: collection,
                docId: docId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HouseholdDocsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalBudgetDatabase,
      $HouseholdDocsTable,
      HouseholdDoc,
      $$HouseholdDocsTableFilterComposer,
      $$HouseholdDocsTableOrderingComposer,
      $$HouseholdDocsTableAnnotationComposer,
      $$HouseholdDocsTableCreateCompanionBuilder,
      $$HouseholdDocsTableUpdateCompanionBuilder,
      (
        HouseholdDoc,
        BaseReferences<
          _$LocalBudgetDatabase,
          $HouseholdDocsTable,
          HouseholdDoc
        >,
      ),
      HouseholdDoc,
      PrefetchHooks Function()
    >;
typedef $$MonthDocsTableCreateCompanionBuilder =
    MonthDocsCompanion Function({
      required String householdId,
      required String monthId,
      required String collection,
      required String docId,
      required String payload,
      Value<int> rowid,
    });
typedef $$MonthDocsTableUpdateCompanionBuilder =
    MonthDocsCompanion Function({
      Value<String> householdId,
      Value<String> monthId,
      Value<String> collection,
      Value<String> docId,
      Value<String> payload,
      Value<int> rowid,
    });

class $$MonthDocsTableFilterComposer
    extends Composer<_$LocalBudgetDatabase, $MonthDocsTable> {
  $$MonthDocsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthId => $composableBuilder(
    column: $table.monthId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthDocsTableOrderingComposer
    extends Composer<_$LocalBudgetDatabase, $MonthDocsTable> {
  $$MonthDocsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthId => $composableBuilder(
    column: $table.monthId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthDocsTableAnnotationComposer
    extends Composer<_$LocalBudgetDatabase, $MonthDocsTable> {
  $$MonthDocsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get monthId =>
      $composableBuilder(column: $table.monthId, builder: (column) => column);

  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get docId =>
      $composableBuilder(column: $table.docId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$MonthDocsTableTableManager
    extends
        RootTableManager<
          _$LocalBudgetDatabase,
          $MonthDocsTable,
          MonthDoc,
          $$MonthDocsTableFilterComposer,
          $$MonthDocsTableOrderingComposer,
          $$MonthDocsTableAnnotationComposer,
          $$MonthDocsTableCreateCompanionBuilder,
          $$MonthDocsTableUpdateCompanionBuilder,
          (
            MonthDoc,
            BaseReferences<_$LocalBudgetDatabase, $MonthDocsTable, MonthDoc>,
          ),
          MonthDoc,
          PrefetchHooks Function()
        > {
  $$MonthDocsTableTableManager(_$LocalBudgetDatabase db, $MonthDocsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthDocsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthDocsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthDocsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> householdId = const Value.absent(),
                Value<String> monthId = const Value.absent(),
                Value<String> collection = const Value.absent(),
                Value<String> docId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthDocsCompanion(
                householdId: householdId,
                monthId: monthId,
                collection: collection,
                docId: docId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String householdId,
                required String monthId,
                required String collection,
                required String docId,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => MonthDocsCompanion.insert(
                householdId: householdId,
                monthId: monthId,
                collection: collection,
                docId: docId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthDocsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalBudgetDatabase,
      $MonthDocsTable,
      MonthDoc,
      $$MonthDocsTableFilterComposer,
      $$MonthDocsTableOrderingComposer,
      $$MonthDocsTableAnnotationComposer,
      $$MonthDocsTableCreateCompanionBuilder,
      $$MonthDocsTableUpdateCompanionBuilder,
      (
        MonthDoc,
        BaseReferences<_$LocalBudgetDatabase, $MonthDocsTable, MonthDoc>,
      ),
      MonthDoc,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaRowsTableCreateCompanionBuilder =
    SyncMetaRowsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncMetaRowsTableUpdateCompanionBuilder =
    SyncMetaRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncMetaRowsTableFilterComposer
    extends Composer<_$LocalBudgetDatabase, $SyncMetaRowsTable> {
  $$SyncMetaRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaRowsTableOrderingComposer
    extends Composer<_$LocalBudgetDatabase, $SyncMetaRowsTable> {
  $$SyncMetaRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaRowsTableAnnotationComposer
    extends Composer<_$LocalBudgetDatabase, $SyncMetaRowsTable> {
  $$SyncMetaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncMetaRowsTableTableManager
    extends
        RootTableManager<
          _$LocalBudgetDatabase,
          $SyncMetaRowsTable,
          SyncMetaRow,
          $$SyncMetaRowsTableFilterComposer,
          $$SyncMetaRowsTableOrderingComposer,
          $$SyncMetaRowsTableAnnotationComposer,
          $$SyncMetaRowsTableCreateCompanionBuilder,
          $$SyncMetaRowsTableUpdateCompanionBuilder,
          (
            SyncMetaRow,
            BaseReferences<
              _$LocalBudgetDatabase,
              $SyncMetaRowsTable,
              SyncMetaRow
            >,
          ),
          SyncMetaRow,
          PrefetchHooks Function()
        > {
  $$SyncMetaRowsTableTableManager(
    _$LocalBudgetDatabase db,
    $SyncMetaRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaRowsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaRowsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalBudgetDatabase,
      $SyncMetaRowsTable,
      SyncMetaRow,
      $$SyncMetaRowsTableFilterComposer,
      $$SyncMetaRowsTableOrderingComposer,
      $$SyncMetaRowsTableAnnotationComposer,
      $$SyncMetaRowsTableCreateCompanionBuilder,
      $$SyncMetaRowsTableUpdateCompanionBuilder,
      (
        SyncMetaRow,
        BaseReferences<_$LocalBudgetDatabase, $SyncMetaRowsTable, SyncMetaRow>,
      ),
      SyncMetaRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxRowsTableCreateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> id,
      required String op,
      required String payload,
      Value<String> status,
      required DateTime createdAt,
    });
typedef $$OutboxRowsTableUpdateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> id,
      Value<String> op,
      Value<String> payload,
      Value<String> status,
      Value<DateTime> createdAt,
    });

class $$OutboxRowsTableFilterComposer
    extends Composer<_$LocalBudgetDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxRowsTableOrderingComposer
    extends Composer<_$LocalBudgetDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxRowsTableAnnotationComposer
    extends Composer<_$LocalBudgetDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxRowsTableTableManager
    extends
        RootTableManager<
          _$LocalBudgetDatabase,
          $OutboxRowsTable,
          OutboxRow,
          $$OutboxRowsTableFilterComposer,
          $$OutboxRowsTableOrderingComposer,
          $$OutboxRowsTableAnnotationComposer,
          $$OutboxRowsTableCreateCompanionBuilder,
          $$OutboxRowsTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$LocalBudgetDatabase, $OutboxRowsTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxRowsTableTableManager(
    _$LocalBudgetDatabase db,
    $OutboxRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxRowsCompanion(
                id: id,
                op: op,
                payload: payload,
                status: status,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String op,
                required String payload,
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxRowsCompanion.insert(
                id: id,
                op: op,
                payload: payload,
                status: status,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalBudgetDatabase,
      $OutboxRowsTable,
      OutboxRow,
      $$OutboxRowsTableFilterComposer,
      $$OutboxRowsTableOrderingComposer,
      $$OutboxRowsTableAnnotationComposer,
      $$OutboxRowsTableCreateCompanionBuilder,
      $$OutboxRowsTableUpdateCompanionBuilder,
      (
        OutboxRow,
        BaseReferences<_$LocalBudgetDatabase, $OutboxRowsTable, OutboxRow>,
      ),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $LocalBudgetDatabaseManager {
  final _$LocalBudgetDatabase _db;
  $LocalBudgetDatabaseManager(this._db);
  $$HouseholdDocsTableTableManager get householdDocs =>
      $$HouseholdDocsTableTableManager(_db, _db.householdDocs);
  $$MonthDocsTableTableManager get monthDocs =>
      $$MonthDocsTableTableManager(_db, _db.monthDocs);
  $$SyncMetaRowsTableTableManager get syncMetaRows =>
      $$SyncMetaRowsTableTableManager(_db, _db.syncMetaRows);
  $$OutboxRowsTableTableManager get outboxRows =>
      $$OutboxRowsTableTableManager(_db, _db.outboxRows);
}
