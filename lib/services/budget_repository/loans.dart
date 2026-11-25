part of '../budget_repository.dart';

/// Income sources, loans and loan payments.
extension BudgetRepositoryLoans on BudgetRepository {
  Future<String> addIncomeSource({
    required String householdId,
    required String monthId,
    required String nameEn,
    required String nameRu,
    required int sortOrder,
  }) async {
    final doc = await _monthRef(householdId, monthId)
        .collection('incomeSources')
        .add({'nameEn': nameEn, 'nameRu': nameRu, 'sortOrder': sortOrder});
    return doc.id;
  }

  Future<void> updateIncomeSource({
    required String householdId,
    required String monthId,
    required IncomeSource source,
  }) async {
    await _monthRef(householdId, monthId)
        .collection('incomeSources')
        .doc(source.id)
        .set(source.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteIncomeSource({
    required String householdId,
    required String monthId,
    required String sourceId,
  }) async {
    await _monthRef(
      householdId,
      monthId,
    ).collection('incomeSources').doc(sourceId).delete();
  }

  // —— Loans ——

  Future<String> addLoan({
    required String householdId,
    required Loan loan,
  }) async {
    final ref = _loans(householdId).doc();
    await ref.set({
      ...loan.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ref.id;
  }

  Future<void> updateLoan({
    required String householdId,
    required Loan loan,
  }) async {
    await _loans(
      householdId,
    ).doc(loan.id).set(loan.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteLoan({
    required String householdId,
    required String loanId,
  }) async {
    await _loans(householdId).doc(loanId).delete();
  }

  Future<String> addLoanPayment({
    required String householdId,
    required String monthId,
    required String loanId,
    required double amount,
    required DateTime date,
    String? note,
    bool reducesBalance = true,
    String? createdBy,
    String? createdByName,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final paymentRef = monthRef.collection('loanPayments').doc();
    final loanRef = _loans(householdId).doc(loanId);

    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final loanSnap = await tx.get(loanRef);
      if (!loanSnap.exists) throw StateError('Loan not found');
      final loan = Loan.fromMap(loanSnap.id, loanSnap.data()!);

      tx.set(paymentRef, {
        'loanId': loanId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'reducesBalance': reducesBalance,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      });

      if (reducesBalance) {
        final nextRemaining = (loan.remainingBalance - amount).clamp(
          0.0,
          double.infinity,
        );
        final updates = <String, dynamic>{'remainingBalance': nextRemaining};
        if (loan.isInstallment) {
          updates['paidInstallments'] = (loan.paidInstallments ?? 0) + 1;
        }
        if (nextRemaining <= 0) {
          updates['status'] = 'paidOff';
        }
        tx.update(loanRef, updates);
      }

      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        debtPaidDelta: amount,
      );
    });
    return paymentRef.id;
  }

  Future<void> deleteLoanPayment({
    required String householdId,
    required String monthId,
    required LoanPayment payment,
  }) async {
    final monthRef = _monthRef(householdId, monthId);
    final paymentRef = monthRef.collection('loanPayments').doc(payment.id);
    final loanRef = _loans(householdId).doc(payment.loanId);

    await _db.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) throw StateError('Month not found');
      final loanSnap = await tx.get(loanRef);

      tx.delete(paymentRef);

      if (payment.reducesBalance && loanSnap.exists) {
        final loan = Loan.fromMap(loanSnap.id, loanSnap.data()!);
        final nextRemaining = loan.remainingBalance + payment.amount;
        final updates = <String, dynamic>{
          'remainingBalance': nextRemaining,
          if (loan.status == 'paidOff' && nextRemaining > 0) 'status': 'active',
        };
        if (loan.isInstallment && (loan.paidInstallments ?? 0) > 0) {
          updates['paidInstallments'] = (loan.paidInstallments ?? 1) - 1;
        }
        tx.update(loanRef, updates);
      }

      await _refreshCashLeftInTx(
        tx,
        monthRef,
        monthSnap.data()!,
        debtPaidDelta: -payment.amount,
      );
    });
  }
}
