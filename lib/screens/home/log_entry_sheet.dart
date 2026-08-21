import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../theme/sync_theme.dart';
import '../../widgets/form_sheet.dart';
import '../category/budget_sheets.dart';
import '../income/income_dialogs.dart';

enum LogKind { spend, save, income, fixed }

/// One add/edit sheet for spend, save (deposit), income, and monthly fixed.
Future<void> showLogEntrySheet(
  BuildContext context, {
  LogKind? kind,
  Expense? expense,
  IncomeEntry? incomeEntry,
  String? subcategoryId,
  String? incomeSourceId,
}) async {
  final state = context.read<AppState>();
  if (!state.hasMonthSelected) return;

  final editing = expense != null || incomeEntry != null;
  final initialKind = kind ??
      (incomeEntry != null
          ? LogKind.income
          : (expense != null && state.isDepositExpense(expense)
              ? LogKind.save
              : LogKind.spend));

  if (initialKind == LogKind.income &&
      !editing &&
      state.incomeSources.isEmpty) {
    final created = await showAddIncomeSourceDialog(context);
    if (!context.mounted) return;
    if (created == null && state.incomeSources.isEmpty) return;
  }

  final l10n = AppLocalizations.of(context);

  var selectedKind = initialKind;
  var selectedSubId = expense?.subcategoryId ??
      subcategoryId ??
      (initialKind == LogKind.save
          ? state.savingsPots.firstOrNull?.id
          : _spendSubs(state).firstOrNull?.id);
  var selectedSourceId =
      incomeEntry?.sourceId ?? incomeSourceId ?? state.incomeSources.firstOrNull?.id;

  final amountCtrl = TextEditingController(
    text: expense != null
        ? expense.amount.toStringAsFixed(2)
        : incomeEntry != null
            ? incomeEntry.amount.toStringAsFixed(2)
            : '',
  );
  final noteCtrl = TextEditingController(
    text: expense?.note ?? incomeEntry?.note ?? '',
  );
  var date = expense?.date ?? DateTime.now();

  var showMore = false;
  var split = false;
  var billDay = DateTime.now().day.clamp(1, 28);
  var splitSubId = _spendSubs(state)
      .where((s) => s.id != selectedSubId)
      .firstOrNull
      ?.id;
  final splitAmountCtrl = TextEditingController();

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            final live = ctx.watch<AppState>();
            final spendSubs = _spendSubs(live);
            final pots = live.savingsPots;
            final sources = live.incomeSources;

            if (selectedKind == LogKind.spend ||
                selectedKind == LogKind.fixed) {
              if (selectedSubId != null &&
                  !spendSubs.any((s) => s.id == selectedSubId)) {
                selectedSubId = spendSubs.firstOrNull?.id;
              }
            }
            if (selectedKind == LogKind.save &&
                selectedSubId != null &&
                !pots.any((s) => s.id == selectedSubId)) {
              selectedSubId = pots.firstOrNull?.id;
            }
            if (selectedKind == LogKind.income &&
                selectedSourceId != null &&
                !sources.any((s) => s.id == selectedSourceId)) {
              selectedSourceId = sources.firstOrNull?.id;
            }

            final canSave = switch (selectedKind) {
              LogKind.spend || LogKind.save || LogKind.fixed =>
                selectedSubId != null,
              LogKind.income => selectedSourceId != null,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  editing ? l10n.editLog : l10n.log,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                if (!editing)
                  SegmentedButton<LogKind>(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: [
                      ButtonSegment(
                        value: LogKind.spend,
                        label: Text(l10n.logSpend),
                      ),
                      ButtonSegment(
                        value: LogKind.save,
                        label: Text(l10n.logSave),
                      ),
                      ButtonSegment(
                        value: LogKind.income,
                        label: Text(l10n.income),
                      ),
                      ButtonSegment(
                        value: LogKind.fixed,
                        label: Text(l10n.logFixed),
                      ),
                    ],
                    selected: {selectedKind},
                    onSelectionChanged: (next) {
                      final k = next.first;
                      setModal(() {
                        selectedKind = k;
                        split = false;
                        showMore = false;
                        selectedSubId = k == LogKind.save
                            ? live.savingsPots.firstOrNull?.id
                            : _spendSubs(live).firstOrNull?.id;
                        selectedSourceId =
                            live.incomeSources.firstOrNull?.id;
                      });
                    },
                  )
                else
                  Text(
                    switch (selectedKind) {
                      LogKind.spend => l10n.logSpend,
                      LogKind.save => l10n.logSave,
                      LogKind.income => l10n.income,
                      LogKind.fixed => l10n.logFixed,
                    },
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          color: SyncColors.textMuted,
                        ),
                  ),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.amount),
                  autofocus: !editing,
                ),
                if (selectedKind == LogKind.spend ||
                    selectedKind == LogKind.fixed) ...[
                  if (spendSubs.isEmpty)
                    _EmptyPicker(
                      message: l10n.noSubcategories,
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final id = await addCategoryAndSubcategory(ctx);
                            if (id != null) {
                              setModal(() => selectedSubId = id);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addCategory),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey('spend-$selectedSubId'),
                      initialValue: selectedSubId,
                      decoration:
                          InputDecoration(labelText: l10n.subcategory),
                      items: spendSubs.map((sub) {
                        final cat = live.categoryById(sub.categoryId);
                        final catName =
                            cat?.localizedName(live.localeCode);
                        final label = catName == null
                            ? sub.localizedName(live.localeCode)
                            : '$catName · ${sub.localizedName(live.localeCode)}';
                        return DropdownMenuItem(
                          value: sub.id,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModal(() => selectedSubId = v);
                      },
                    ),
                ],
                if (selectedKind == LogKind.save) ...[
                  if (pots.isEmpty)
                    _EmptyPicker(
                      message: l10n.emptyPots,
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final id = await _promptAddPot(ctx);
                            if (id != null) {
                              setModal(() => selectedSubId = id);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addPot),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey('save-$selectedSubId'),
                      initialValue: selectedSubId,
                      decoration:
                          InputDecoration(labelText: l10n.subcategory),
                      items: pots
                          .map(
                            (pot) => DropdownMenuItem(
                              value: pot.id,
                              child: Text(
                                pot.localizedName(live.localeCode),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModal(() => selectedSubId = v);
                      },
                    ),
                ],
                if (selectedKind == LogKind.income) ...[
                  if (sources.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: ValueKey('income-$selectedSourceId'),
                      initialValue: selectedSourceId,
                      decoration: InputDecoration(labelText: l10n.income),
                      items: sources
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.localizedName(live.localeCode),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModal(() => selectedSourceId = v);
                      },
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final id = await showAddIncomeSourceDialog(ctx);
                        if (id != null) {
                          setModal(() => selectedSourceId = id);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addIncomeSource),
                    ),
                  ),
                ],
                if (selectedKind == LogKind.fixed) ...[
                  DropdownButtonFormField<int>(
                    initialValue: billDay,
                    decoration: InputDecoration(labelText: l10n.billDay),
                    items: [
                      for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModal(() => billDay = v);
                    },
                  ),
                  Text(
                    l10n.logFixedHint,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: SyncColors.textMuted,
                        ),
                  ),
                ],
                TextField(
                  controller: noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: selectedKind == LogKind.fixed
                        ? l10n.description
                        : l10n.note,
                  ),
                ),
                if (selectedKind == LogKind.spend ||
                    selectedKind == LogKind.save)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.date),
                    subtitle: Text(DateFormat.yMMMd().format(date)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(date.year - 2),
                        lastDate: DateTime(date.year + 2),
                      );
                      if (picked == null) return;
                      setModal(() => date = picked);
                    },
                  ),
                if (!editing && selectedKind == LogKind.spend) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setModal(() => showMore = !showMore),
                      child: Text(
                        showMore
                            ? l10n.done
                            : l10n.logMoreOptions,
                      ),
                    ),
                  ),
                  if (showMore && spendSubs.length >= 2) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.splitSpend),
                      value: split,
                      onChanged: (v) => setModal(() => split = v),
                    ),
                    if (split) ...[
                      DropdownButtonFormField<String>(
                        initialValue: splitSubId,
                        decoration: InputDecoration(
                          labelText: '${l10n.splitPart} 2',
                        ),
                        items: spendSubs
                            .where((s) => s.id != selectedSubId)
                            .map((sub) {
                          final cat = live.categoryById(sub.categoryId);
                          return DropdownMenuItem(
                            value: sub.id,
                            child: Text(
                              '${cat?.localizedName(live.localeCode) ?? ''} · ${sub.localizedName(live.localeCode)}',
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setModal(() => splitSubId = v),
                      ),
                      TextField(
                        controller: splitAmountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '${l10n.splitPart} 2 ${l10n.amount}',
                        ),
                      ),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final id = await addCategoryAndSubcategory(ctx);
                            if (id != null) {
                              setModal(() => selectedSubId = id);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addCategory),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final id =
                                await pickCategoryAndAddSubcategory(ctx);
                            if (id != null) {
                              setModal(() => selectedSubId = id);
                            }
                          },
                          icon: const Icon(Icons.account_tree_outlined),
                          label: Text(l10n.addSubcategory),
                        ),
                      ],
                    ),
                  ],
                ],
                FilledButton(
                  onPressed:
                      canSave ? () => Navigator.pop(ctx, 'save') : null,
                  child: Text(l10n.save),
                ),
                if (editing)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'delete'),
                    child: Text(
                      selectedKind == LogKind.income
                          ? l10n.deleteIncome
                          : l10n.delete,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );

  if (result == null || !context.mounted) return;
  final live = context.read<AppState>();

  if (result == 'delete') {
    if (expense != null) {
      await live.deleteExpense(expense.id);
    } else if (incomeEntry != null) {
      final hid = live.appUser?.householdId;
      final monthId = live.monthId;
      if (hid != null && monthId != null) {
        await live.repo.deleteIncomeEntry(
          householdId: hid,
          monthId: monthId,
          entryId: incomeEntry.id,
        );
      }
    }
    return;
  }

  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  if (amount <= 0) return;
  final note = sentenceCase(noteCtrl.text);
  final noteOrNull = note.isEmpty ? null : note;

  switch (selectedKind) {
    case LogKind.spend:
      final subId = selectedSubId;
      if (subId == null) return;
      if (expense == null) {
        if (split) {
          final part2 =
              double.tryParse(splitAmountCtrl.text.replaceAll(',', '')) ?? 0;
          final rest = amount - part2;
          final secondId = splitSubId;
          if (secondId == null || part2 <= 0 || rest <= 0) return;
          await live.addSplitExpenses(
            date: date,
            note: noteOrNull,
            parts: [
              (subcategoryId: subId, amount: rest),
              (subcategoryId: secondId, amount: part2),
            ],
          );
        } else {
          await live.addExpense(
            subcategoryId: subId,
            amount: amount,
            date: date,
            note: noteOrNull,
          );
        }
      } else {
        await live.updateExpense(
          Expense(
            id: expense.id,
            subcategoryId: subId,
            amount: amount,
            date: date,
            note: noteOrNull,
            createdAt: expense.createdAt,
            createdBy: expense.createdBy,
            createdByName: expense.createdByName,
            isDeposit: false,
            splitGroupId: expense.splitGroupId,
          ),
        );
      }
    case LogKind.save:
      final subId = selectedSubId;
      if (subId == null) return;
      if (expense == null) {
        await live.addDeposit(
          subcategoryId: subId,
          amount: amount,
          date: date,
          note: noteOrNull,
        );
      } else {
        await live.updateExpense(
          Expense(
            id: expense.id,
            subcategoryId: subId,
            amount: amount,
            date: date,
            note: noteOrNull,
            createdAt: expense.createdAt,
            createdBy: expense.createdBy,
            createdByName: expense.createdByName,
            isDeposit: true,
            splitGroupId: expense.splitGroupId,
          ),
        );
      }
    case LogKind.income:
      final sourceId = selectedSourceId;
      if (sourceId == null) return;
      if (incomeEntry == null) {
        await live.addIncomeEntry(
          sourceId: sourceId,
          amount: amount,
          note: noteOrNull,
        );
      } else {
        final hid = live.appUser?.householdId;
        final monthId = live.monthId;
        if (hid == null || monthId == null) return;
        await live.repo.updateIncomeEntry(
          householdId: hid,
          monthId: monthId,
          entry: incomeEntry.copyWith(
            sourceId: sourceId,
            amount: amount,
            note: noteOrNull,
          ),
        );
      }
    case LogKind.fixed:
      final subId = selectedSubId;
      if (subId == null) return;
      if (!live.canEditPlan) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.viewerReadOnlyPlan)),
          );
        }
        return;
      }
      final sub = live.subcategoryById(subId);
      final billName = noteOrNull ??
          sub?.localizedName(live.localeCode) ??
          l10n.logFixed;
      await live.addRecurringBill(
        name: billName,
        amount: amount,
        dayOfMonth: billDay,
        subcategoryId: subId,
      );
      await live.upsertPlan(
        subcategoryId: subId,
        planned: amount,
      );
  }
}

List<Subcategory> _spendSubs(AppState state) {
  return state.subcategories.where((sub) {
    final cat = state.categoryById(sub.categoryId);
    return cat != null && !cat.isSavings;
  }).toList();
}

Future<String?> _promptAddPot(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final nameCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.addPot),
      content: TextField(
        controller: nameCtrl,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.subcategoryName),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return null;
  return context.read<AppState>().addPot(name: name);
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({required this.message, required this.actions});

  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text(message),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}

/// Thin wrappers so existing call sites keep working.
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
