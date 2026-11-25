part of '../app_state.dart';

/// Recurring bills, loans and loan payments.
extension AppStateBillsAndLoans on AppState {
  Future<void> addRecurringBill({
    required String name,
    required double amount,
    required int dayOfMonth,
    String? subcategoryId,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.addRecurringBill(
      householdId: hid,
      name: name,
      amount: amount,
      dayOfMonth: dayOfMonth,
      subcategoryId: subcategoryId,
    );
  }

  Future<void> updateRecurringBill(RecurringBill bill) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateRecurringBill(householdId: hid, bill: bill);
  }

  Future<void> deleteRecurringBill(String billId) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.deleteRecurringBill(householdId: hid, billId: billId);
  }

  Future<String> addLoan({
    required String name,
    required String type,
    required double originalAmount,
    double? remainingBalance,
    double? monthlyPayment,
    int? totalInstallments,
    int? paidInstallments,
    int? dueDayOfMonth,
    double? interestRate,
    String? note,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    final remaining = remainingBalance ?? originalAmount;
    final paid = type == 'installment'
        ? (paidInstallments ?? 0).clamp(0, totalInstallments ?? 999999)
        : 0;
    final loan = Loan(
      id: '',
      name: name.trim(),
      type: type,
      originalAmount: originalAmount,
      remainingBalance: remaining,
      monthlyPayment: monthlyPayment,
      totalInstallments: totalInstallments,
      paidInstallments: paid,
      dueDayOfMonth: dueDayOfMonth,
      interestRate: interestRate,
      note: note,
      sortOrder: _loans.length,
      status: remaining <= 0 ? 'paidOff' : 'active',
    );
    return _repo.addLoan(householdId: hid, loan: loan);
  }

  Future<void> updateLoan(Loan loan) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateLoan(householdId: hid, loan: loan);
  }

  Future<void> deleteLoan(String loanId) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.deleteLoan(householdId: hid, loanId: loanId);
  }

  Future<void> addLoanPayment({
    required String loanId,
    required double amount,
    required DateTime date,
    String? note,
    bool reducesBalance = true,
  }) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    await _repo.addLoanPayment(
      householdId: hid,
      monthId: mid,
      loanId: loanId,
      amount: amount,
      date: date,
      note: note,
      reducesBalance: reducesBalance,
      createdBy: currentUid,
      createdByName: currentDisplayName,
    );
  }

  Future<void> deleteLoanPayment(String paymentId) async {
    final hid = _activeHid;
    final mid = _monthId;
    if (hid == null || mid == null) throw StateError('No month selected');
    LoanPayment? old;
    for (final p in _loanPayments) {
      if (p.id == paymentId) {
        old = p;
        break;
      }
    }
    if (old == null) return;
    await _repo.deleteLoanPayment(householdId: hid, monthId: mid, payment: old);
  }
}
