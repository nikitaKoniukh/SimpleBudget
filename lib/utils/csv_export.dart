import '../models/models.dart';
import '../utils/money.dart';

String buildMonthCsv({
  required String monthId,
  required String householdName,
  required List<IncomeSource> incomeSources,
  required List<IncomeEntry> incomeEntries,
  required List<BudgetCategory> categories,
  required List<LineItem> lineItems,
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
  buf.writeln('EXPENSES');
  buf.writeln('Category,Type,Description,Budget,Actual,Difference,Installment');
  for (final cat in categories) {
    final items = lineItems.where((i) => i.categoryId == cat.id).toList();
    for (final item in items) {
      buf.writeln(
        [
          _csv(cat.localizedName(localeCode)),
          cat.type,
          _csv(item.localizedDescription(localeCode)),
          item.planned,
          item.actual,
          item.difference,
          item.installmentHint ?? '',
        ].join(','),
      );
    }
  }
  final income = incomeEntries.fold<double>(0, (s, e) => s + e.amount);
  final planned = lineItems.fold<double>(0, (s, e) => s + e.planned);
  final actual = lineItems.fold<double>(0, (s, e) => s + e.actual);
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
