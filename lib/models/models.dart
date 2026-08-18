class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.householdId,
    this.localeCode = 'en',
  });

  final String id;
  final String email;
  final String? displayName;
  final String? householdId;
  final String localeCode;

  AppUser copyWith({
    String? displayName,
    String? householdId,
    String? localeCode,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      householdId: householdId ?? this.householdId,
      localeCode: localeCode ?? this.localeCode,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'householdId': householdId,
    'localeCode': localeCode,
  };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      householdId: map['householdId'] as String?,
      localeCode: map['localeCode'] as String? ?? 'en',
    );
  }
}

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.inviteCode,
    this.currency = 'ILS',
    this.createdBy,
  });

  final String id;
  final String name;
  final List<String> memberIds;
  final String inviteCode;
  final String currency;
  final String? createdBy;

  bool isOwnedBy(String uid) {
    if (createdBy == uid) return true;
    final missingOwner = createdBy == null || createdBy!.isEmpty;
    return missingOwner && memberIds.length == 1 && memberIds.contains(uid);
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'memberIds': memberIds,
    'inviteCode': inviteCode,
    'currency': currency,
    'createdBy': createdBy,
  };

  factory Household.fromMap(String id, Map<String, dynamic> map) {
    return Household(
      id: id,
      name: map['name'] as String? ?? 'Household',
      memberIds: List<String>.from(map['memberIds'] as List? ?? const []),
      inviteCode: map['inviteCode'] as String? ?? '',
      currency: map['currency'] as String? ?? 'ILS',
      createdBy: map['createdBy'] as String?,
    );
  }
}

class BudgetMonth {
  const BudgetMonth({required this.id, this.notes, this.status = 'active'});

  /// Format: yyyy-MM
  final String id;
  final String? notes;
  final String status;

  Map<String, dynamic> toMap() => {'notes': notes, 'status': status};

  factory BudgetMonth.fromMap(String id, Map<String, dynamic> map) {
    return BudgetMonth(
      id: id,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'active',
    );
  }
}

class IncomeSource {
  const IncomeSource({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.sortOrder,
  });

  final String id;
  final String nameEn;
  final String nameRu;
  final int sortOrder;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;

  Map<String, dynamic> toMap() => {
    'nameEn': nameEn,
    'nameRu': nameRu,
    'sortOrder': sortOrder,
  };

  factory IncomeSource.fromMap(String id, Map<String, dynamic> map) {
    return IncomeSource(
      id: id,
      nameEn: map['nameEn'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class IncomeEntry {
  const IncomeEntry({
    required this.id,
    required this.sourceId,
    required this.amount,
    this.note,
    this.createdAt,
  });

  final String id;
  final String sourceId;
  final double amount;
  final String? note;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'sourceId': sourceId,
    'amount': amount,
    'note': note,
    'createdAt': createdAt?.toIso8601String(),
  };

  IncomeEntry copyWith({String? sourceId, double? amount, String? note}) {
    return IncomeEntry(
      id: id,
      sourceId: sourceId ?? this.sourceId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  factory IncomeEntry.fromMap(String id, Map<String, dynamic> map) {
    return IncomeEntry(
      id: id,
      sourceId: map['sourceId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }
}

class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.colorValue,
    required this.type,
    required this.sortOrder,
    this.targetAmount,
    this.savedTotal = 0,
  });

  final String id;
  final String nameEn;
  final String nameRu;
  final int colorValue;
  final String type; // expense | savings | debt
  final int sortOrder;

  /// Optional lifetime goal for savings pots. Null means no target.
  final double? targetAmount;

  /// Cumulative deposits. Written via increment, not [toMap].
  final double savedTotal;

  bool get isSavings => type == 'savings';

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;

  BudgetCategory copyWith({
    String? nameEn,
    String? nameRu,
    int? colorValue,
    String? type,
    int? sortOrder,
    double? targetAmount,
    bool clearTargetAmount = false,
    double? savedTotal,
  }) {
    return BudgetCategory(
      id: id,
      nameEn: nameEn ?? this.nameEn,
      nameRu: nameRu ?? this.nameRu,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      targetAmount: clearTargetAmount
          ? null
          : (targetAmount ?? this.targetAmount),
      savedTotal: savedTotal ?? this.savedTotal,
    );
  }

  /// Does not include [savedTotal] so merge-updates cannot clobber increments.
  Map<String, dynamic> toMap() => {
    'nameEn': nameEn,
    'nameRu': nameRu,
    'colorValue': colorValue,
    'type': type,
    'sortOrder': sortOrder,
    'targetAmount': targetAmount,
  };

  factory BudgetCategory.fromMap(String id, Map<String, dynamic> map) {
    return BudgetCategory(
      id: id,
      nameEn: map['nameEn'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFBDBDBD,
      type: map['type'] as String? ?? 'expense',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      savedTotal: (map['savedTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Subcategory {
  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameRu,
    this.installmentTotal,
    this.sortOrder = 0,
    this.archived = false,
    this.targetAmount,
    this.savedTotal = 0,
  });

  final String id;
  final String categoryId;
  final String nameEn;
  final String nameRu;
  final int? installmentTotal;
  final int sortOrder;
  final bool archived;

  /// Optional lifetime goal for a savings pot. Null means no target.
  final double? targetAmount;

  /// Cumulative deposits. Written via increment, not [toMap].
  final double savedTotal;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;

  Subcategory copyWith({
    String? categoryId,
    String? nameEn,
    String? nameRu,
    int? installmentTotal,
    bool clearInstallmentTotal = false,
    int? sortOrder,
    bool? archived,
    double? targetAmount,
    bool clearTargetAmount = false,
    double? savedTotal,
  }) {
    return Subcategory(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      nameEn: nameEn ?? this.nameEn,
      nameRu: nameRu ?? this.nameRu,
      installmentTotal: clearInstallmentTotal
          ? null
          : (installmentTotal ?? this.installmentTotal),
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      targetAmount: clearTargetAmount
          ? null
          : (targetAmount ?? this.targetAmount),
      savedTotal: savedTotal ?? this.savedTotal,
    );
  }

  /// Does not include [savedTotal] so merge-updates cannot clobber increments.
  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'nameEn': nameEn,
    'nameRu': nameRu,
    'installmentTotal': installmentTotal,
    'sortOrder': sortOrder,
    'archived': archived,
    'targetAmount': targetAmount,
  };

  factory Subcategory.fromMap(String id, Map<String, dynamic> map) {
    return Subcategory(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      nameEn: map['nameEn'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      installmentTotal: (map['installmentTotal'] as num?)?.toInt(),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      archived: map['archived'] as bool? ?? false,
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      savedTotal: (map['savedTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MonthPlan {
  const MonthPlan({
    required this.subcategoryId,
    required this.planned,
    this.installmentCurrent,
  });

  final String subcategoryId;
  final double planned;
  final int? installmentCurrent;

  MonthPlan copyWith({
    double? planned,
    int? installmentCurrent,
    bool clearInstallmentCurrent = false,
  }) {
    return MonthPlan(
      subcategoryId: subcategoryId,
      planned: planned ?? this.planned,
      installmentCurrent: clearInstallmentCurrent
          ? null
          : (installmentCurrent ?? this.installmentCurrent),
    );
  }

  Map<String, dynamic> toMap() => {
    'planned': planned,
    'installmentCurrent': installmentCurrent,
  };

  factory MonthPlan.fromMap(String subcategoryId, Map<String, dynamic> map) {
    return MonthPlan(
      subcategoryId: subcategoryId,
      planned: (map['planned'] as num?)?.toDouble() ?? 0,
      installmentCurrent: (map['installmentCurrent'] as num?)?.toInt(),
    );
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.subcategoryId,
    required this.amount,
    required this.date,
    this.note,
    this.createdAt,
  });

  final String id;
  final String subcategoryId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime? createdAt;

  Expense copyWith({
    String? subcategoryId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'subcategoryId': subcategoryId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      subcategoryId: map['subcategoryId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }
}

class MonthTotals {
  const MonthTotals({
    required this.income,
    required this.planned,
    required this.actual,
  });

  final double income;
  final double planned;
  final double actual;

  double get remaining => planned - actual;
  double get unallocated => income - planned;
  bool get planExceedsIncome => planned > income;
}
