import 'package:flutter/material.dart';

import '../../models/models.dart';

export 'log_entry_flow.dart'
    show
        LogKind,
        openLogEntryFlow,
        kindLabel,
        iconForLogKind;

import 'log_entry_flow.dart';

Future<void> showLogEntrySheet(
  BuildContext context, {
  LogKind? kind,
  Expense? expense,
  IncomeEntry? incomeEntry,
  String? subcategoryId,
  String? incomeSourceId,
}) {
  return openLogEntryFlow(
    context,
    kind: kind,
    expense: expense,
    incomeEntry: incomeEntry,
    subcategoryId: subcategoryId,
    incomeSourceId: incomeSourceId,
  );
}

Future<void> showExpenseEditor(
  BuildContext context, {
  Expense? expense,
  String? subcategoryId,
}) {
  return showLogEntrySheet(
    context,
    kind: expense == null ? LogKind.spend : null,
    expense: expense,
    subcategoryId: subcategoryId,
  );
}

Future<void> showDepositEditor(
  BuildContext context, {
  Subcategory? subcategory,
  Expense? expense,
}) {
  return showLogEntrySheet(
    context,
    kind: expense == null ? LogKind.save : null,
    expense: expense,
    subcategoryId: subcategory?.id ?? expense?.subcategoryId,
  );
}

Future<void> showAddIncomeEntryFlow(BuildContext context) {
  return showLogEntrySheet(context, kind: LogKind.income);
}

Future<void> showIncomeEntryEditor(
  BuildContext context, {
  List<IncomeSource>? sources,
  IncomeEntry? entry,
}) {
  return showLogEntrySheet(
    context,
    kind: LogKind.income,
    incomeEntry: entry,
    incomeSourceId: entry?.sourceId ?? sources?.firstOrNull?.id,
  );
}

Future<void> showQuickLogSheet(BuildContext context) {
  return showLogEntrySheet(context);
}
