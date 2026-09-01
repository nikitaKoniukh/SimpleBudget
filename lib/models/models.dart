class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.householdIds = const [],
    this.activeHouseholdId,
    this.localeCode = 'en',
  });

  final String id;
  final String email;
  final String? displayName;
  final List<String> householdIds;
  final String? activeHouseholdId;
  final String localeCode;

  bool get hasHouseholds => householdIds.isNotEmpty;

  AppUser copyWith({
    String? displayName,
    List<String>? householdIds,
    String? activeHouseholdId,
    bool clearActiveHouseholdId = false,
    String? localeCode,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      householdIds: householdIds ?? this.householdIds,
      activeHouseholdId: clearActiveHouseholdId
          ? null
          : (activeHouseholdId ?? this.activeHouseholdId),
      localeCode: localeCode ?? this.localeCode,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'householdIds': householdIds,
    if (activeHouseholdId != null) 'activeHouseholdId': activeHouseholdId,
    'localeCode': localeCode,
  };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    final ids = List<String>.from(map['householdIds'] as List? ?? const []);
    var active = map['activeHouseholdId'] as String?;
    if (active != null && active.isNotEmpty && !ids.contains(active)) {
      active = ids.isEmpty ? null : ids.first;
    } else if ((active == null || active.isEmpty) && ids.isNotEmpty) {
      active = ids.first;
    }
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      householdIds: ids,
      activeHouseholdId: active,
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
  const BudgetMonth({
    required this.id,
    this.notes,
    this.status = 'active',
    this.incomeTotal = 0,
    this.spentTotal = 0,
    this.plannedTotal = 0,
    this.depositTotal = 0,
    this.leftoverFromPrior = 0,
    this.cashLeft = 0,
    this.savingsBeforeMonth = 0,
    this.savingsThroughMonth = 0,
    this.debtPaidTotal = 0,
  });

  /// Format: yyyy-MM
  final String id;
  final String? notes;
  final String status;

  final double incomeTotal;
  final double spentTotal;
  final double plannedTotal;
  final double depositTotal;
  final double leftoverFromPrior;
  final double cashLeft;
  final double savingsBeforeMonth;
  final double savingsThroughMonth;
  final double debtPaidTotal;

  BudgetMonth copyWith({
    String? notes,
    String? status,
    double? incomeTotal,
    double? spentTotal,
    double? plannedTotal,
    double? depositTotal,
    double? leftoverFromPrior,
    double? cashLeft,
    double? savingsBeforeMonth,
    double? savingsThroughMonth,
    double? debtPaidTotal,
  }) {
    return BudgetMonth(
      id: id,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      incomeTotal: incomeTotal ?? this.incomeTotal,
      spentTotal: spentTotal ?? this.spentTotal,
      plannedTotal: plannedTotal ?? this.plannedTotal,
      depositTotal: depositTotal ?? this.depositTotal,
      leftoverFromPrior: leftoverFromPrior ?? this.leftoverFromPrior,
      cashLeft: cashLeft ?? this.cashLeft,
      savingsBeforeMonth: savingsBeforeMonth ?? this.savingsBeforeMonth,
      savingsThroughMonth: savingsThroughMonth ?? this.savingsThroughMonth,
      debtPaidTotal: debtPaidTotal ?? this.debtPaidTotal,
    );
  }

  Map<String, dynamic> toMap() => {
    'notes': notes,
    'status': status,
    'incomeTotal': incomeTotal,
    'spentTotal': spentTotal,
    'plannedTotal': plannedTotal,
    'depositTotal': depositTotal,
    'leftoverFromPrior': leftoverFromPrior,
    'cashLeft': cashLeft,
    'savingsBeforeMonth': savingsBeforeMonth,
    'savingsThroughMonth': savingsThroughMonth,
    'debtPaidTotal': debtPaidTotal,
  };

  factory BudgetMonth.fromMap(String id, Map<String, dynamic> map) {
    return BudgetMonth(
      id: id,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'active',
      incomeTotal: (map['incomeTotal'] as num?)?.toDouble() ?? 0,
      spentTotal: (map['spentTotal'] as num?)?.toDouble() ?? 0,
      plannedTotal: (map['plannedTotal'] as num?)?.toDouble() ?? 0,
      depositTotal: (map['depositTotal'] as num?)?.toDouble() ?? 0,
      leftoverFromPrior: (map['leftoverFromPrior'] as num?)?.toDouble() ?? 0,
      cashLeft: (map['cashLeft'] as num?)?.toDouble() ?? 0,
      savingsBeforeMonth: (map['savingsBeforeMonth'] as num?)?.toDouble() ?? 0,
      savingsThroughMonth:
          (map['savingsThroughMonth'] as num?)?.toDouble() ?? 0,
      debtPaidTotal: (map['debtPaidTotal'] as num?)?.toDouble() ?? 0,
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
    required this.iconKey,
    required this.type,
    required this.sortOrder,
    this.targetAmount,
  });

  final String id;
  final String nameEn;
  final String nameRu;
  final int colorValue;
  final String iconKey;

  /// spend | monthly | savings
  final String type;
  final int sortOrder;

  /// Optional lifetime goal for savings pots. Null means no target.
  final double? targetAmount;

  bool get isSpend => type == 'spend';
  bool get isMonthly => type == 'monthly';
  bool get isSavings => type == 'savings';

  /// Non-savings categories (spend, monthly).
  bool get isBudgetEnvelope => !isSavings;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;

  BudgetCategory copyWith({
    String? nameEn,
    String? nameRu,
    int? colorValue,
    String? iconKey,
    String? type,
    int? sortOrder,
    double? targetAmount,
    bool clearTargetAmount = false,
  }) {
    return BudgetCategory(
      id: id,
      nameEn: nameEn ?? this.nameEn,
      nameRu: nameRu ?? this.nameRu,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      targetAmount: clearTargetAmount
          ? null
          : (targetAmount ?? this.targetAmount),
    );
  }

  Map<String, dynamic> toMap() => {
    'nameEn': nameEn,
    'nameRu': nameRu,
    'colorValue': colorValue,
    'iconKey': iconKey,
    'type': type,
    'sortOrder': sortOrder,
    'targetAmount': targetAmount,
  };

  factory BudgetCategory.fromMap(String id, Map<String, dynamic> map) {
    final rawIcon = map['iconKey'] as String? ?? '';
    return BudgetCategory(
      id: id,
      nameEn: map['nameEn'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFBDBDBD,
      iconKey: rawIcon.isEmpty ? 'category' : rawIcon,
      type: map['type'] as String? ?? 'spend',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
    );
  }
}

class Subcategory {
  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameRu,
    this.sortOrder = 0,
    this.archived = false,
    this.targetAmount,
    this.targetDate,
    this.includeInTotal = true,
  });

  final String id;
  final String categoryId;
  final String nameEn;
  final String nameRu;
  final int sortOrder;
  final bool archived;

  /// Optional lifetime goal for a savings pot. Null means no target.
  final double? targetAmount;

  /// Optional deadline for a savings pot.
  final DateTime? targetDate;

  /// When false, pot is listed but excluded from aggregated savings totals.
  final bool includeInTotal;

  String localizedName(String localeCode) =>
      localeCode == 'ru' ? nameRu : nameEn;

  Subcategory copyWith({
    String? categoryId,
    String? nameEn,
    String? nameRu,
    int? sortOrder,
    bool? archived,
    double? targetAmount,
    bool clearTargetAmount = false,
    DateTime? targetDate,
    bool clearTargetDate = false,
    bool? includeInTotal,
  }) {
    return Subcategory(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      nameEn: nameEn ?? this.nameEn,
      nameRu: nameRu ?? this.nameRu,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      targetAmount: clearTargetAmount
          ? null
          : (targetAmount ?? this.targetAmount),
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      includeInTotal: includeInTotal ?? this.includeInTotal,
    );
  }

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'nameEn': nameEn,
    'nameRu': nameRu,
    'sortOrder': sortOrder,
    'archived': archived,
    'targetAmount': targetAmount,
    'targetDate': targetDate?.toIso8601String(),
    'includeInTotal': includeInTotal,
  };

  factory Subcategory.fromMap(String id, Map<String, dynamic> map) {
    return Subcategory(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      nameEn: map['nameEn'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      archived: map['archived'] as bool? ?? false,
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      targetDate: map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'] as String)
          : null,
      includeInTotal: map['includeInTotal'] as bool? ?? true,
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
    this.nameEn,
    this.nameRu,
  });

  final String subcategoryId;
  final double planned;

  /// Optional display name for this month only. Falls back to [Subcategory] name.
  final String? nameEn;
  final String? nameRu;

  String localizedName(String localeCode, Subcategory fallback) {
    final override = localeCode == 'ru'
        ? (nameRu ?? nameEn)
        : (nameEn ?? nameRu);
    if (override != null && override.trim().isNotEmpty) return override;
    return fallback.localizedName(localeCode);
  }

  MonthPlan copyWith({
    double? planned,
    String? nameEn,
    String? nameRu,
    bool clearNameEn = false,
    bool clearNameRu = false,
  }) {
    return MonthPlan(
      subcategoryId: subcategoryId,
      planned: planned ?? this.planned,
      nameEn: clearNameEn ? null : (nameEn ?? this.nameEn),
      nameRu: clearNameRu ? null : (nameRu ?? this.nameRu),
    );
  }

  Map<String, dynamic> toMap() => {
    'planned': planned,
    if (nameEn != null) 'nameEn': nameEn,
    if (nameRu != null) 'nameRu': nameRu,
  };

  factory MonthPlan.fromMap(String subcategoryId, Map<String, dynamic> map) {
    return MonthPlan(
      subcategoryId: subcategoryId,
      planned: (map['planned'] as num?)?.toDouble() ?? 0,
      nameEn: map['nameEn'] as String?,
      nameRu: map['nameRu'] as String?,
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
  });

  final String id;
  final String subcategoryId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;

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
    );
  }
}

class Deposit {
  const Deposit({
    required this.id,
    required this.subcategoryId,
    required this.amount,
    required this.date,
    this.note,
    this.createdAt,
    this.createdBy,
    this.createdByName,
  });

  final String id;
  final String subcategoryId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;

  Deposit copyWith({
    String? subcategoryId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return Deposit(
      id: id,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
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
  };

  factory Deposit.fromMap(String id, Map<String, dynamic> map) {
    return Deposit(
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
    );
  }
}

class PotBalance {
  const PotBalance({
    required this.subcategoryId,
    this.openingBalance = 0,
    this.deposited = 0,
    this.withdrawn = 0,
    this.balance = 0,
  });

  final String subcategoryId;
  final double openingBalance;
  final double deposited;
  final double withdrawn;
  final double balance;

  static double computeBalance({
    required double openingBalance,
    required double deposited,
    required double withdrawn,
  }) =>
      openingBalance + deposited - withdrawn;

  PotBalance copyWith({
    double? openingBalance,
    double? deposited,
    double? withdrawn,
    double? balance,
  }) {
    final nextOpening = openingBalance ?? this.openingBalance;
    final nextDeposited = deposited ?? this.deposited;
    final nextWithdrawn = withdrawn ?? this.withdrawn;
    return PotBalance(
      subcategoryId: subcategoryId,
      openingBalance: nextOpening,
      deposited: nextDeposited,
      withdrawn: nextWithdrawn,
      balance: balance ??
          computeBalance(
            openingBalance: nextOpening,
            deposited: nextDeposited,
            withdrawn: nextWithdrawn,
          ),
    );
  }

  Map<String, dynamic> toMap() => {
    'openingBalance': openingBalance,
    'deposited': deposited,
    'withdrawn': withdrawn,
    'balance': balance,
  };

  factory PotBalance.fromMap(String subcategoryId, Map<String, dynamic> map) {
    final opening = (map['openingBalance'] as num?)?.toDouble() ?? 0;
    final deposited = (map['deposited'] as num?)?.toDouble() ?? 0;
    final withdrawn = (map['withdrawn'] as num?)?.toDouble() ?? 0;
    final stored = (map['balance'] as num?)?.toDouble();
    return PotBalance(
      subcategoryId: subcategoryId,
      openingBalance: opening,
      deposited: deposited,
      withdrawn: withdrawn,
      balance: stored ??
          computeBalance(
            openingBalance: opening,
            deposited: deposited,
            withdrawn: withdrawn,
          ),
    );
  }
}

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.type,
    required this.originalAmount,
    required this.remainingBalance,
    this.monthlyPayment,
    this.totalInstallments,
    this.paidInstallments,
    this.dueDayOfMonth,
    this.interestRate,
    this.note,
    this.status = 'active',
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String name;

  /// installment | balance
  final String type;
  final double originalAmount;
  final double remainingBalance;
  final double? monthlyPayment;
  final int? totalInstallments;
  final int? paidInstallments;
  final int? dueDayOfMonth;
  final double? interestRate;
  final String? note;

  /// active | paidOff | archived
  final String status;
  final int sortOrder;
  final DateTime? createdAt;

  bool get isInstallment => type == 'installment';
  bool get isBalance => type == 'balance';
  bool get isActive => status == 'active';
  bool get isPaidOff =>
      status == 'paidOff' ||
      remainingBalance <= 0 ||
      (isInstallment &&
          totalInstallments != null &&
          totalInstallments! > 0 &&
          paidCount >= totalInstallments!);
  bool get isArchived => status == 'archived';

  int get paidCount => paidInstallments ?? 0;

  /// Payments still owed for installment loans (`total − paid`).
  int? get remainingInstallmentCount {
    final total = totalInstallments;
    if (total == null || total <= 0) return null;
    final left = total - paidCount;
    return left < 0 ? 0 : left;
  }

  double? get installmentProgress {
    final total = totalInstallments;
    if (total == null || total <= 0) return null;
    return (paidCount / total).clamp(0.0, 1.0);
  }

  Loan copyWith({
    String? name,
    String? type,
    double? originalAmount,
    double? remainingBalance,
    double? monthlyPayment,
    bool clearMonthlyPayment = false,
    int? totalInstallments,
    bool clearTotalInstallments = false,
    int? paidInstallments,
    bool clearPaidInstallments = false,
    int? dueDayOfMonth,
    bool clearDueDayOfMonth = false,
    double? interestRate,
    bool clearInterestRate = false,
    String? note,
    bool clearNote = false,
    String? status,
    int? sortOrder,
  }) {
    return Loan(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      monthlyPayment: clearMonthlyPayment
          ? null
          : (monthlyPayment ?? this.monthlyPayment),
      totalInstallments: clearTotalInstallments
          ? null
          : (totalInstallments ?? this.totalInstallments),
      paidInstallments: clearPaidInstallments
          ? null
          : (paidInstallments ?? this.paidInstallments),
      dueDayOfMonth: clearDueDayOfMonth
          ? null
          : (dueDayOfMonth ?? this.dueDayOfMonth),
      interestRate:
          clearInterestRate ? null : (interestRate ?? this.interestRate),
      note: clearNote ? null : (note ?? this.note),
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'originalAmount': originalAmount,
    'remainingBalance': remainingBalance,
    'monthlyPayment': monthlyPayment,
    'totalInstallments': totalInstallments,
    'paidInstallments': paidInstallments,
    'dueDayOfMonth': dueDayOfMonth,
    'interestRate': interestRate,
    'note': note,
    'status': status,
    'sortOrder': sortOrder,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Loan.fromMap(String id, Map<String, dynamic> map) {
    return Loan(
      id: id,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'balance',
      originalAmount: (map['originalAmount'] as num?)?.toDouble() ?? 0,
      remainingBalance: (map['remainingBalance'] as num?)?.toDouble() ?? 0,
      monthlyPayment: (map['monthlyPayment'] as num?)?.toDouble(),
      totalInstallments: (map['totalInstallments'] as num?)?.toInt(),
      paidInstallments: (map['paidInstallments'] as num?)?.toInt(),
      dueDayOfMonth: (map['dueDayOfMonth'] as num?)?.toInt(),
      interestRate: (map['interestRate'] as num?)?.toDouble(),
      note: map['note'] as String?,
      status: map['status'] as String? ?? 'active',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }
}

class LoanPayment {
  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.note,
    this.reducesBalance = true,
    this.createdAt,
    this.createdBy,
    this.createdByName,
  });

  final String id;
  final String loanId;
  final double amount;
  final DateTime date;
  final String? note;
  final bool reducesBalance;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;

  LoanPayment copyWith({
    double? amount,
    DateTime? date,
    String? note,
    bool? reducesBalance,
  }) {
    return LoanPayment(
      id: id,
      loanId: loanId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      reducesBalance: reducesBalance ?? this.reducesBalance,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
    );
  }

  Map<String, dynamic> toMap() => {
    'loanId': loanId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'reducesBalance': reducesBalance,
    'createdAt': createdAt?.toIso8601String(),
    'createdBy': createdBy,
    'createdByName': createdByName,
  };

  factory LoanPayment.fromMap(String id, Map<String, dynamic> map) {
    return LoanPayment(
      id: id,
      loanId: map['loanId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
      reducesBalance: map['reducesBalance'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      createdBy: map['createdBy'] as String?,
      createdByName: map['createdByName'] as String?,
    );
  }
}

class MonthTotals {
  const MonthTotals({
    required this.income,
    required this.planned,
    required this.actual,
    this.savedThisMonth = 0,
    this.debtPaidThisMonth = 0,
    this.leftoverFromPrior = 0,
  });

  final double income;
  final double planned;
  final double actual;
  final double savedThisMonth;
  final double debtPaidThisMonth;
  final double leftoverFromPrior;

  /// Expenses only (spend + monthly categories).
  /// Use [totalSpent] for month-level outflow including savings and loans.
  double get totalSpent =>
      actual + savedThisMonth + debtPaidThisMonth;

  double get remaining => planned - totalSpent;
  double get cashLeft => income - totalSpent;
  double get unallocated => income - planned;
  bool get planExceedsIncome => planned > income;
}

/// Immutable snapshot of one month for Statistics aggregation.
class MonthStatsSnapshot {
  const MonthStatsSnapshot({
    required this.monthId,
    required this.expenses,
    required this.deposits,
    required this.plans,
    required this.income,
    this.debtPaid = 0,
  });

  final String monthId;
  final List<Expense> expenses;
  final List<Deposit> deposits;
  final List<MonthPlan> plans;
  final double income;
  final double debtPaid;

  double spentForSub(String subcategoryId) => expenses
      .where((e) => e.subcategoryId == subcategoryId)
      .fold(0, (s, e) => s + e.amount);

  double spentForCategory(
    String categoryId,
    List<Subcategory> allSubs,
  ) {
    final ids =
        allSubs.where((s) => s.categoryId == categoryId).map((s) => s.id);
    return ids.fold<double>(0, (s, id) => s + spentForSub(id));
  }

  double get totalSpent => expenses.fold(0, (s, e) => s + e.amount);

  /// Deposits this month. When [includeSubcategoryIds] is set, only those pots.
  double savedThisMonth([Set<String>? includeSubcategoryIds]) => deposits
      .where((d) {
        if (includeSubcategoryIds == null) return true;
        return includeSubcategoryIds.contains(d.subcategoryId);
      })
      .fold(0, (s, d) => s + d.amount);
}
