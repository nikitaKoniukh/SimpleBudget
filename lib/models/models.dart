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
  const BudgetMonth({
    required this.id,
    this.notes,
    this.status = 'active',
  });

  /// Format: yyyy-MM
  final String id;
  final String? notes;
  final String status;

  Map<String, dynamic> toMap() => {
        'notes': notes,
        'status': status,
      };

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
  });

  final String id;
  final String nameEn;
  final String nameRu;
  final int colorValue;
  final String type; // expense | savings | debt
  final int sortOrder;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;

  Map<String, dynamic> toMap() => {
        'nameEn': nameEn,
        'nameRu': nameRu,
        'colorValue': colorValue,
        'type': type,
        'sortOrder': sortOrder,
      };

  factory BudgetCategory.fromMap(String id, Map<String, dynamic> map) {
    return BudgetCategory(
      id: id,
      nameEn: map['nameEn'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFBDBDBD,
      type: map['type'] as String? ?? 'expense',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class LineItem {
  const LineItem({
    required this.id,
    required this.categoryId,
    required this.descriptionEn,
    required this.descriptionRu,
    required this.planned,
    required this.actual,
    this.installmentCurrent,
    this.installmentTotal,
    this.sortOrder = 0,
  });

  final String id;
  final String categoryId;
  final String descriptionEn;
  final String descriptionRu;
  final double planned;
  final double actual;
  final int? installmentCurrent;
  final int? installmentTotal;
  final int sortOrder;

  double get difference => planned - actual;

  String localizedDescription(String localeCode) =>
      localeCode == 'ru' ? descriptionRu : descriptionEn;

  String? get installmentHint {
    if (installmentCurrent == null || installmentTotal == null) return null;
    return '$installmentCurrent/$installmentTotal';
  }

  LineItem copyWith({
    double? planned,
    double? actual,
    String? descriptionEn,
    String? descriptionRu,
    int? installmentCurrent,
    int? installmentTotal,
  }) {
    return LineItem(
      id: id,
      categoryId: categoryId,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionRu: descriptionRu ?? this.descriptionRu,
      planned: planned ?? this.planned,
      actual: actual ?? this.actual,
      installmentCurrent: installmentCurrent ?? this.installmentCurrent,
      installmentTotal: installmentTotal ?? this.installmentTotal,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'descriptionEn': descriptionEn,
        'descriptionRu': descriptionRu,
        'planned': planned,
        'actual': actual,
        'installmentCurrent': installmentCurrent,
        'installmentTotal': installmentTotal,
        'sortOrder': sortOrder,
      };

  factory LineItem.fromMap(String id, Map<String, dynamic> map) {
    return LineItem(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      descriptionEn: map['descriptionEn'] as String? ?? '',
      descriptionRu: map['descriptionRu'] as String? ?? '',
      planned: (map['planned'] as num?)?.toDouble() ?? 0,
      actual: (map['actual'] as num?)?.toDouble() ?? 0,
      installmentCurrent: (map['installmentCurrent'] as num?)?.toInt(),
      installmentTotal: (map['installmentTotal'] as num?)?.toInt(),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
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
