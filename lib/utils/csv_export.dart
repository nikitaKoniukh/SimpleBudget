import '../models/models.dart';
import '../utils/money.dart';

String buildMonthCsv({
  required String monthId,
  required String householdName,
  required List<IncomeSource> incomeSources,
  required List<IncomeEntry> incomeEntries,
  required List<BudgetCategory> categories,
  required List<Subcategory> subcategories,
  required List<MonthPlan> plans,
  required List<Expense> expenses,
  String localeCode = 'en',
}) {
  final buf = StringBuffer();
  buf.writeln('SyncMonth,$householdName,$monthId');
  buf.writeln();
  buf.writeln('INCOME');
  buf.writeln('Source,Amount,Note');
  for (final source in incomeSources) {
    final entries =
        incomeEntries.where((e) => e.sourceId == source.id).toList();
    if (entries.isEmpty) {
      buf.writeln(
        '${_csv(source.localizedName(localeCode))},0,',
      );
    } else {
      for (final e in entries) {
        buf.writeln(
          '${_csv(source.localizedName(localeCode))},${e.amount},${_csv(e.note ?? '')}',
        );
      }
    }
  }
  buf.writeln();
  buf.writeln('PLANS');
  buf.writeln('Category,Subcategory,Planned,Spent,Installment');
  final planBySub = {for (final p in plans) p.subcategoryId: p};
  for (final cat in categories) {
    final subs = subcategories.where((s) => s.categoryId == cat.id);
    for (final sub in subs) {
      final planned = planBySub[sub.id]?.planned ?? 0;
      final spent = expenses
          .where((e) => e.subcategoryId == sub.id)
          .fold<double>(0, (s, e) => s + e.amount);
      final current = planBySub[sub.id]?.installmentCurrent;
      final installment = current != null && sub.installmentTotal != null
          ? '$current/${sub.installmentTotal}'
          : '';
      buf.writeln(
        [
          _csv(cat.localizedName(localeCode)),
          _csv(sub.localizedName(localeCode)),
          planned,
          spent,
          installment,
        ].join(','),
      );
    }
  }
  buf.writeln();
  buf.writeln('EXPENSES');
  buf.writeln('Category,Subcategory,Date,Amount,Note');
  for (final expense in expenses) {
    final sub = subcategories
        .where((s) => s.id == expense.subcategoryId)
        .firstOrNull;
    final cat = sub == null
        ? null
        : categories.where((c) => c.id == sub.categoryId).firstOrNull;
    buf.writeln(
      [
        _csv(cat?.localizedName(localeCode) ?? ''),
        _csv(sub?.localizedName(localeCode) ?? ''),
        expense.date.toIso8601String().split('T').first,
        expense.amount,
        _csv(expense.note ?? ''),
      ].join(','),
    );
  }
  final income = incomeEntries.fold<double>(0, (s, e) => s + e.amount);
  final planned = plans.fold<double>(0, (s, e) => s + e.planned);
  final actual = expenses.fold<double>(0, (s, e) => s + e.amount);
  buf.writeln();
  buf.writeln('TOTALS');
  buf.writeln('Income,${formatIls(income).replaceAll(',', '')}');
  buf.writeln('Planned,$planned');
  buf.writeln('Actual,$actual');
  buf.writeln('Difference,${planned - actual}');
  return buf.toString();
}

String _csv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
