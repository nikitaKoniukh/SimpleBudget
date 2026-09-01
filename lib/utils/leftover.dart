/// Cash left entering next month:
/// max(0, leftoverFromPrior + income − spent − deposits − debt paid).
double computeMonthCashLeft({
  required double leftoverFromPrior,
  required double incomeTotal,
  required double spentTotal,
  required double depositTotal,
  double debtPaidTotal = 0,
}) {
  final cashLeft = leftoverFromPrior +
      incomeTotal -
      spentTotal -
      depositTotal -
      debtPaidTotal;
  return cashLeft > 0 ? cashLeft : 0.0;
}

/// Floor leftover carried into a new month from the prior month's cash left.
double leftoverFromPriorCashLeft(double priorCashLeft) =>
    priorCashLeft > 0 ? priorCashLeft : 0.0;
