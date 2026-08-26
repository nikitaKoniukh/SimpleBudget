import '../models/models.dart';

/// Cash left: max(0, income − spent).
double computeUnspentLeftover({
  required double income,
  required Iterable<Expense> expenses,
}) {
  var totalSpent = 0.0;
  for (final e in expenses) {
    totalSpent += e.amount;
  }
  final leftover = income - totalSpent;
  return leftover > 0 ? leftover : 0.0;
}
