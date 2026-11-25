part of '../budget_repository.dart';

/// Expenses, deposits, savings pots, withdrawals and income entries.
extension BudgetRepositoryLedger on BudgetRepository {
  Future<String> addExpense({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
    String? createdBy,
    String? createdByName,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final expenseRef = monthRef.collection('expenses').doc();
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(expenseRef, {
        'subcategoryId': subcategoryId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        spentDelta: amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    return expenseRef.id;
  }

  Future<void> updateExpense({
    required String householdId,
    required String monthId,
    required Expense expense,
    required Expense previous,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final expenseRef = monthRef.collection('expenses').doc(expense.id);
    final amountDelta = expense.amount - previous.amount;
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(expenseRef, expense.toMap(), SetOptions(merge: true));
      if (amountDelta != 0) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          spentDelta: amountDelta,
        );
      }
    });
    if (amountDelta != 0) {
      await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    }
  }

  Future<void> deleteExpense({
    required String householdId,
    required String monthId,
    required Expense expense,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final expenseRef = monthRef.collection('expenses').doc(expense.id);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.delete(expenseRef);
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        spentDelta: -expense.amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
  }

  Future<String> addDeposit({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double amount,
    required DateTime date,
    String? note,
    String? createdBy,
    String? createdByName,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final depositRef = monthRef.collection('deposits').doc();
    final potRef = monthRef.collection('potBalances').doc(subcategoryId);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final potSnap = await tx.get(potRef);
      final pot = potSnap.exists
          ? PotBalance.fromMap(subcategoryId, potSnap.data()!)
          : PotBalance(subcategoryId: subcategoryId);
      final next = pot.copyWith(
        deposited: pot.deposited + amount,
        balance: pot.balance + amount,
      );
      tx.set(depositRef, {
        'subcategoryId': subcategoryId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });
      tx.set(potRef, next.toMap());
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        depositDelta: amount,
        savingsThroughDelta: includeInTotal ? amount : 0,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    await _cascadePotBalancesToFollowingMonths(
      householdId,
      monthId,
      subcategoryId,
    );
    return depositRef.id;
  }

  Future<void> updateDeposit({
    required String householdId,
    required String monthId,
    required Deposit deposit,
    required Deposit previous,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final depositRef = monthRef.collection('deposits').doc(deposit.id);
    final potRef = monthRef
        .collection('potBalances')
        .doc(deposit.subcategoryId);
    final amountDelta = deposit.amount - previous.amount;
    final potChanged = deposit.subcategoryId != previous.subcategoryId;

    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');

      if (potChanged) {
        final oldPotRef = monthRef
            .collection('potBalances')
            .doc(previous.subcategoryId);
        final oldPotSnap = await tx.get(oldPotRef);
        final newPotSnap = await tx.get(potRef);
        if (oldPotSnap.exists) {
          final oldPot = PotBalance.fromMap(
            previous.subcategoryId,
            oldPotSnap.data()!,
          );
          tx.set(
            oldPotRef,
            oldPot
                .copyWith(
                  deposited: oldPot.deposited - previous.amount,
                  balance: oldPot.balance - previous.amount,
                )
                .toMap(),
          );
        }
        final newPot = newPotSnap.exists
            ? PotBalance.fromMap(deposit.subcategoryId, newPotSnap.data()!)
            : PotBalance(subcategoryId: deposit.subcategoryId);
        tx.set(
          potRef,
          newPot
              .copyWith(
                deposited: newPot.deposited + deposit.amount,
                balance: newPot.balance + deposit.amount,
              )
              .toMap(),
        );
      } else if (amountDelta != 0) {
        final potSnap = await tx.get(potRef);
        if (potSnap.exists) {
          final pot = PotBalance.fromMap(
            deposit.subcategoryId,
            potSnap.data()!,
          );
          tx.set(
            potRef,
            pot
                .copyWith(
                  deposited: pot.deposited + amountDelta,
                  balance: pot.balance + amountDelta,
                )
                .toMap(),
          );
        }
      }

      tx.set(depositRef, deposit.toMap(), SetOptions(merge: true));
      if (amountDelta != 0) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          depositDelta: amountDelta,
          savingsThroughDelta: includeInTotal ? amountDelta : 0,
        );
      }
    });
    if (amountDelta != 0 || potChanged) {
      await _cascadeLeftoverToFollowingMonths(householdId, monthId);
      await _cascadePotBalancesToFollowingMonths(
        householdId,
        monthId,
        deposit.subcategoryId,
      );
      if (potChanged) {
        await _cascadePotBalancesToFollowingMonths(
          householdId,
          monthId,
          previous.subcategoryId,
        );
      }
    }
  }

  Future<void> deleteDeposit({
    required String householdId,
    required String monthId,
    required Deposit deposit,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final depositRef = monthRef.collection('deposits').doc(deposit.id);
    final potRef = monthRef
        .collection('potBalances')
        .doc(deposit.subcategoryId);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final potSnap = await tx.get(potRef);
      if (potSnap.exists) {
        final pot = PotBalance.fromMap(deposit.subcategoryId, potSnap.data()!);
        tx.set(
          potRef,
          pot
              .copyWith(
                deposited: pot.deposited - deposit.amount,
                balance: pot.balance - deposit.amount,
              )
              .toMap(),
        );
      }
      tx.delete(depositRef);
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        depositDelta: -deposit.amount,
        savingsThroughDelta: includeInTotal ? -deposit.amount : 0,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    await _cascadePotBalancesToFollowingMonths(
      householdId,
      monthId,
      deposit.subcategoryId,
    );
  }

  /// Sets the opening (prior) balance for a pot in [monthId].
  Future<void> setPotOpeningBalance({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double openingBalance,
    bool includeInTotal = true,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final potRef = monthRef.collection('potBalances').doc(subcategoryId);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final potSnap = await tx.get(potRef);
      final pot = potSnap.exists
          ? PotBalance.fromMap(subcategoryId, potSnap.data()!)
          : PotBalance(subcategoryId: subcategoryId);
      final next = pot.copyWith(
        openingBalance: openingBalance,
        balance: PotBalance.computeBalance(
          openingBalance: openingBalance,
          deposited: pot.deposited,
          withdrawn: pot.withdrawn,
        ),
      );
      final openingDelta = next.openingBalance - pot.openingBalance;
      final balanceDelta = next.balance - pot.balance;
      tx.set(potRef, next.toMap());
      if (includeInTotal && (openingDelta != 0 || balanceDelta != 0)) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          savingsBeforeDelta: openingDelta,
          savingsThroughDelta: balanceDelta,
        );
      }
    });
    await _cascadePotBalancesToFollowingMonths(
      householdId,
      monthId,
      subcategoryId,
    );
  }

  /// Ensures the fixed "From savings" income source exists for [monthId].
  Future<void> ensureFromSavingsIncomeSource({
    required String householdId,
    required String monthId,
  }) async {
    final ref = _monthRef(
      householdId,
      monthId,
    ).collection('incomeSources').doc(BudgetRepository.fromSavingsIncomeSourceId);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'nameEn': 'From savings',
      'nameRu': 'Из накоплений',
      'sortOrder': 9000,
    });
  }

  /// Withdraws from a savings pot (existing schemas only).
  ///
  /// Always updates [PotBalance.withdrawn]/[PotBalance.balance] and
  /// [savingsThroughMonth] when [includeInTotal].
  /// When [creditIncome] is true, also creates an income entry under
  /// [BudgetRepository.fromSavingsIncomeSourceId] and increases month income / cash left.
  /// Caller should [ensureFromSavingsIncomeSource] first when crediting income.
  Future<String?> addWithdrawal({
    required String householdId,
    required String monthId,
    required String subcategoryId,
    required double amount,
    String? note,
    String? createdBy,
    String? createdByName,
    bool includeInTotal = true,
    bool creditIncome = true,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be positive');
    }
    final monthRef = _monthRef(householdId, monthId);
    final potRef = monthRef.collection('potBalances').doc(subcategoryId);
    final incomeRef = creditIncome
        ? monthRef.collection('incomeEntries').doc()
        : null;
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final potSnap = await tx.get(potRef);
      final pot = potSnap.exists
          ? PotBalance.fromMap(subcategoryId, potSnap.data()!)
          : PotBalance(subcategoryId: subcategoryId);
      if (amount > pot.balance + 1e-9) {
        throw StateError('Insufficient pot balance');
      }
      final next = pot.copyWith(withdrawn: pot.withdrawn + amount);
      if (incomeRef != null) {
        tx.set(incomeRef, {
          'sourceId': BudgetRepository.fromSavingsIncomeSourceId,
          'amount': amount,
          'note': note,
          'createdAt': DateTime.now().toIso8601String(),
          'createdBy': createdBy,
          'createdByName': createdByName,
        });
      }
      tx.set(potRef, next.toMap());
      final savingsDelta = includeInTotal ? -amount : 0.0;
      if (creditIncome || savingsDelta != 0) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          incomeDelta: creditIncome ? amount : null,
          savingsThroughDelta: savingsDelta,
        );
      }
    });
    if (creditIncome) {
      await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    }
    await _cascadePotBalancesToFollowingMonths(
      householdId,
      monthId,
      subcategoryId,
    );
    return incomeRef?.id;
  }

  Future<void> addIncomeEntry({
    required String householdId,
    required String monthId,
    required String sourceId,
    required double amount,
    String? note,
    String? createdBy,
    String? createdByName,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final entryRef = monthRef.collection('incomeEntries').doc();
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(entryRef, {
        'sourceId': sourceId,
        'amount': amount,
        'note': note,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        incomeDelta: amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
  }

  Future<void> updateIncomeEntry({
    required String householdId,
    required String monthId,
    required IncomeEntry entry,
    required IncomeEntry previous,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final entryRef = monthRef.collection('incomeEntries').doc(entry.id);
    final amountDelta = entry.amount - previous.amount;
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.set(entryRef, entry.toMap(), SetOptions(merge: true));
      if (amountDelta != 0) {
        await _refreshCashLeftInTx(
          tx,
          monthRef,
          monthSnap.data()!,
          incomeDelta: amountDelta,
        );
      }
    });
    if (amountDelta != 0) {
      await _cascadeLeftoverToFollowingMonths(householdId, monthId);
    }
  }

  Future<void> deleteIncomeEntry({
    required String householdId,
    required String monthId,
    required IncomeEntry entry,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final entryRef = monthRef.collection('incomeEntries').doc(entry.id);
    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      tx.delete(entryRef);
      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        incomeDelta: -entry.amount,
      );
    });
    await _cascadeLeftoverToFollowingMonths(householdId, monthId);
  }
}
