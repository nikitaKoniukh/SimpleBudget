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

class MemberProfile {
  const MemberProfile({
    required this.uid,
    required this.name,
    this.role = 'editor',
  });

  final String uid;
  final String name;

  /// owner | editor | viewer
  final String role;

  bool get canEditPlan => role != 'viewer';

  Map<String, dynamic> toMap() => {'name': name, 'role': role};

  factory MemberProfile.fromMap(String uid, Map<String, dynamic> map) {
    return MemberProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? 'editor',
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
    this.memberProfiles = const {},
  });

  final String id;
  final String name;
  final List<String> memberIds;
  final String inviteCode;
  final String currency;
  final String? createdBy;
  final Map<String, MemberProfile> memberProfiles;

  bool isOwnedBy(String uid) {
    if (createdBy == uid) return true;
    final missingOwner = createdBy == null || createdBy!.isEmpty;
    return missingOwner && memberIds.length == 1 && memberIds.contains(uid);
  }

  String roleFor(String uid) {
    if (isOwnedBy(uid)) return 'owner';
    return memberProfiles[uid]?.role ?? 'editor';
  }

  bool canEditPlan(String uid) => roleFor(uid) != 'viewer';

  String memberName(String uid) {
    final named = memberProfiles[uid]?.name.trim();
    if (named != null && named.isNotEmpty) return named;
    return uid;
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'memberIds': memberIds,
    'inviteCode': inviteCode,
    'currency': currency,
    'createdBy': createdBy,
    'memberProfiles': {
      for (final e in memberProfiles.entries) e.key: e.value.toMap(),
    },
  };

  factory Household.fromMap(String id, Map<String, dynamic> map) {
    final rawProfiles = map['memberProfiles'];
    final profiles = <String, MemberProfile>{};
    if (rawProfiles is Map) {
      for (final e in rawProfiles.entries) {
        final value = e.value;
        if (value is Map) {
          profiles[e.key.toString()] = MemberProfile.fromMap(
            e.key.toString(),
            Map<String, dynamic>.from(value),
          );
        }
      }
    }
    return Household(
      id: id,
      name: map['name'] as String? ?? 'Household',
      memberIds: List<String>.from(map['memberIds'] as List? ?? const []),
      inviteCode: map['inviteCode'] as String? ?? '',
      currency: map['currency'] as String? ?? 'ILS',
      createdBy: map['createdBy'] as String?,
      memberProfiles: profiles,
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
    this.createdBy,
    this.createdByName,
  });

  final String id;
  final String sourceId;
  final double amount;
  final String? note;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;

  Map<String, dynamic> toMap() => {
    'sourceId': sourceId,
    'amount': amount,
    'note': note,
    'createdAt': createdAt?.toIso8601String(),
    'createdBy': createdBy,
    'createdByName': createdByName,
  };

  IncomeEntry copyWith({String? sourceId, double? amount, String? note}) {
    return IncomeEntry(
      id: id,
      sourceId: sourceId ?? this.sourceId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
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
      createdBy: map['createdBy'] as String?,
      createdByName: map['createdByName'] as String?,
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
  /// spend | monthly | debt | savings
  final String type;
  final int sortOrder;

  /// Optional lifetime goal for savings pots. Null means no target.
  final double? targetAmount;

  /// Cumulative deposits. Written via increment, not [toMap].
  final double savedTotal;

  bool get isSpend => type == 'spend';
  bool get isMonthly => type == 'monthly';
  bool get isDebt => type == 'debt';
  bool get isSavings => type == 'savings';

  /// Counts toward monthly spend/plan totals (not savings pots).
  bool get isBudgetEnvelope => !isSavings;

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
      type: map['type'] as String? ?? 'spend',
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
    this.targetDate,
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

  /// Optional deadline for a savings pot.
  final DateTime? targetDate;

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
    DateTime? targetDate,
    bool clearTargetDate = false,
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
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
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
    'targetDate': targetDate?.toIso8601String(),
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
      targetDate: map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'] as String)
          : null,
    );
  }
}

class RecurringBill {
  const RecurringBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    this.subcategoryId,
  });

  final String id;
  final String name;
  final double amount;
  final int dayOfMonth;
  final String? subcategoryId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'dayOfMonth': dayOfMonth,
    'subcategoryId': subcategoryId,
  };

  factory RecurringBill.fromMap(String id, Map<String, dynamic> map) {
    return RecurringBill(
      id: id,
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dayOfMonth: (map['dayOfMonth'] as num?)?.toInt() ?? 1,
      subcategoryId: map['subcategoryId'] as String?,
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
    this.createdBy,
    this.createdByName,
    this.isDeposit = false,
  });

  final String id;
  final String subcategoryId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;
  final bool isDeposit;

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
      createdBy: createdBy,
      createdByName: createdByName,
      isDeposit: isDeposit,
    );
  }

  Map<String, dynamic> toMap() => {
    'subcategoryId': subcategoryId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'createdAt': createdAt?.toIso8601String(),
    'createdBy': createdBy,
    'createdByName': createdByName,
    'isDeposit': isDeposit,
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
      createdBy: map['createdBy'] as String?,
      createdByName: map['createdByName'] as String?,
      isDeposit: map['isDeposit'] as bool? ?? false,
    );
  }
}

class MonthTotals {
  const MonthTotals({
    required this.income,
    required this.planned,
    required this.actual,
    this.savedThisMonth = 0,
  });

  final double income;
  final double planned;
  final double actual;
  final double savedThisMonth;

  double get remaining => planned - actual;
  double get cashLeft => income - actual;
  double get unallocated => income - planned;
  bool get planExceedsIncome => planned > income;
}

/// Immutable snapshot of one month for Statistics aggregation.
class MonthStatsSnapshot {
  const MonthStatsSnapshot({
    required this.monthId,
    required this.expenses,
    required this.plans,
    required this.income,
  });

  final String monthId;
  final List<Expense> expenses;
  final List<MonthPlan> plans;
  final double income;

  double spentForSub(String subcategoryId) => expenses
      .where((e) => e.subcategoryId == subcategoryId && !e.isDeposit)
      .fold(0, (s, e) => s + e.amount);

  double spentForCategory(
    String categoryId,
    List<Subcategory> allSubs,
  ) {
    final ids =
        allSubs.where((s) => s.categoryId == categoryId).map((s) => s.id);
    return ids.fold<double>(0, (s, id) => s + spentForSub(id));
  }

  double get totalSpent => expenses
      .where((e) => !e.isDeposit)
      .fold(0, (s, e) => s + e.amount);

  double get savedThisMonth => expenses
      .where((e) => e.isDeposit)
      .fold(0, (s, e) => s + e.amount);
}
