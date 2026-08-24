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

enum LogKind { spend, save, income, monthly, debt }

/// One add/edit sheet for spend, save, income, monthly, and debt.
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
  var initialKind = kind ??
      (incomeEntry != null
          ? LogKind.income
          : (expense != null && state.isDepositExpense(expense)
              ? LogKind.save
              : LogKind.spend));

  if (!editing && expense != null) {
    final cat = state.categoryById(
      state.subcategoryById(expense.subcategoryId)?.categoryId ?? '',
    );
    if (cat?.isDebt ?? false) initialKind = LogKind.debt;
    if (cat?.isMonthly ?? false) initialKind = LogKind.monthly;
  } else if (!editing && subcategoryId != null && kind == null) {
    final cat = state.categoryById(
      state.subcategoryById(subcategoryId)?.categoryId ?? '',
    );
    if (cat?.isDebt ?? false) {
      initialKind = LogKind.debt;
    } else if (cat?.isMonthly ?? false) {
      initialKind = LogKind.monthly;
    } else if (cat?.isSavings ?? false) {
      initialKind = LogKind.save;
    }
  }

  if (initialKind == LogKind.income &&
      !editing &&
      state.incomeSources.isEmpty) {
    final created = await showAddIncomeSourceDialog(context);
    if (!context.mounted) return;
    if (created == null && state.incomeSources.isEmpty) return;
  }

  final l10n = AppLocalizations.of(context);

  final pinnedSubId = expense?.subcategoryId ?? subcategoryId;
  var selectedKind = initialKind;
  var selectedSubId = pinnedSubId ?? _defaultSubForKind(state, initialKind);
  var selectedCategoryId =
      state.subcategoryById(selectedSubId ?? '')?.categoryId ??
          _catsForKind(state, initialKind).firstOrNull?.id;
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
  var billDay = DateTime.now().day.clamp(1, 28);

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            final live = ctx.watch<AppState>();
            final kindCats = _catsForKind(live, selectedKind);
            final pots = live.savingsPots;
            final sources = live.incomeSources;

            if (selectedKind == LogKind.save) {
              if (selectedSubId != null &&
                  !pots.any((s) => s.id == selectedSubId)) {
                selectedSubId = pots.firstOrNull?.id;
              }
            } else if (selectedKind != LogKind.income) {
              final pinnedSub = pinnedSubId == null
                  ? null
                  : live.subcategoryById(pinnedSubId);
              if (pinnedSub != null) {
                selectedCategoryId = pinnedSub.categoryId;
                selectedSubId = pinnedSub.id;
              } else {
                if (selectedCategoryId != null &&
                    !kindCats.any((c) => c.id == selectedCategoryId)) {
                  selectedCategoryId = kindCats.firstOrNull?.id;
                }
                selectedCategoryId ??= kindCats.firstOrNull?.id;
                final catSubs = selectedCategoryId == null
                    ? const <Subcategory>[]
                    : live.subcategoriesFor(selectedCategoryId!);
                if (selectedSubId != null &&
                    !catSubs.any((s) => s.id == selectedSubId)) {
                  selectedSubId = catSubs.firstOrNull?.id;
                }
                selectedSubId ??= catSubs.firstOrNull?.id;
              }
            }
            if (selectedKind == LogKind.income) {
              if (selectedSourceId != null &&
                  !sources.any((s) => s.id == selectedSourceId)) {
                selectedSourceId = sources.firstOrNull?.id;
              }
              selectedSourceId ??= sources.firstOrNull?.id;
            }

            final catSubs = selectedCategoryId == null
                ? const <Subcategory>[]
                : live.subcategoriesFor(selectedCategoryId!);

            final canSave = switch (selectedKind) {
              LogKind.spend ||
              LogKind.save ||
              LogKind.monthly ||
              LogKind.debt =>
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final k in LogKind.values) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_kindLabel(l10n, k)),
                              selected: selectedKind == k,
                              onSelected: (_) {
                                setModal(() {
                                  selectedKind = k;
                                  selectedSubId =
                                      _defaultSubForKind(live, k);
                                  selectedCategoryId = live
                                          .subcategoryById(
                                              selectedSubId ?? '')
                                          ?.categoryId ??
                                      _catsForKind(live, k).firstOrNull?.id;
                                  selectedSourceId =
                                      live.incomeSources.firstOrNull?.id;
                                });
                                if (k == LogKind.income &&
                                    live.incomeSources.isEmpty) {
                                  () async {
                                    final id =
                                        await showAddIncomeSourceDialog(ctx);
                                    if (id == null || !ctx.mounted) return;
                                    setModal(() => selectedSourceId = id);
                                  }();
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  Text(
                    _kindLabel(l10n, selectedKind),
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
                    selectedKind == LogKind.monthly ||
                    selectedKind == LogKind.debt) ...[
                  if (kindCats.isEmpty)
                    _EmptyPicker(
                      message: l10n.noSubcategories,
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final id = await addCategoryAndSubcategory(ctx);
                            if (id == null) return;
                            final catId = live
                                .subcategoryById(id)
                                ?.categoryId;
                            setModal(() {
                              selectedSubId = id;
                              selectedCategoryId = catId;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addCategory),
                        ),
                      ],
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'cat-${selectedKind.name}-$selectedCategoryId',
                      ),
                      initialValue: selectedCategoryId,
                      decoration: InputDecoration(labelText: l10n.category),
                      items: kindCats
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(
                                cat.localizedName(live.localeCode),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModal(() {
                          selectedCategoryId = v;
                          selectedSubId =
                              live.subcategoriesFor(v).firstOrNull?.id;
                        });
                      },
                    ),
                    if (catSubs.isEmpty)
                      _EmptyPicker(
                        message: l10n.noSubcategories,
                        actions: [
                          OutlinedButton.icon(
                            onPressed: selectedCategoryId == null
                                ? null
                                : () async {
                                    final id = await showAddSubcategorySheet(
                                      ctx,
                                      categoryId: selectedCategoryId!,
                                    );
                                    if (id != null) {
                                      setModal(() => selectedSubId = id);
                                    }
                                  },
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addSubcategory),
                          ),
                        ],
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'sub-$selectedCategoryId-$selectedSubId',
                        ),
                        initialValue: selectedSubId,
                        decoration:
                            InputDecoration(labelText: l10n.subcategory),
                        items: catSubs
                            .map(
                              (sub) => DropdownMenuItem(
                                value: sub.id,
                                child: Text(
                                  sub.localizedName(live.localeCode),
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
                      decoration: InputDecoration(labelText: l10n.sectionSavings),
                      items: pots
                          .map(
                            (sub) => DropdownMenuItem(
                              value: sub.id,
                              child: Text(
                                sub.localizedName(live.localeCode),
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
                  if (sources.isEmpty)
                    _EmptyPicker(
                      message: l10n.emptyIncome,
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final id = await showAddIncomeSourceDialog(ctx);
                            if (id == null || !ctx.mounted) return;
                            setModal(() => selectedSourceId = id);
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addIncomeSource),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey('income-$selectedSourceId'),
                      initialValue: selectedSourceId,
                      decoration: InputDecoration(labelText: l10n.income),
                      items: sources
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.localizedName(live.localeCode)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModal(() => selectedSourceId = v);
                      },
                    ),
                ],
                if (selectedKind == LogKind.monthly) ...[
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
                    labelText: selectedKind == LogKind.monthly
                        ? l10n.description
                        : l10n.note,
                  ),
                ),
                if (selectedKind == LogKind.spend ||
                    selectedKind == LogKind.save ||
                    selectedKind == LogKind.debt)
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
    case LogKind.debt:
      final subId = selectedSubId;
      if (subId == null) return;
      if (expense == null) {
        await live.addExpense(
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
            isDeposit: false,
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
    case LogKind.monthly:
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

String _kindLabel(AppLocalizations l10n, LogKind kind) {
  return switch (kind) {
    LogKind.spend => l10n.logSpend,
    LogKind.save => l10n.logSave,
    LogKind.income => l10n.income,
    LogKind.monthly => l10n.logFixed,
    LogKind.debt => l10n.logDebt,
  };
}

List<BudgetCategory> _catsForKind(AppState state, LogKind kind) {
  return switch (kind) {
    LogKind.spend => state.categoriesOfType('spend'),
    LogKind.monthly => state.categoriesOfType('monthly'),
    LogKind.debt => state.categoriesOfType('debt'),
    LogKind.save || LogKind.income => const [],
  };
}

List<Subcategory> _subsForKind(AppState state, LogKind kind) {
  return switch (kind) {
    LogKind.spend => state.subcategoriesOfType('spend'),
    LogKind.monthly => state.subcategoriesOfType('monthly'),
    LogKind.debt => state.subcategoriesOfType('debt'),
    LogKind.save => state.savingsPots,
    LogKind.income => const [],
  };
}

String? _defaultSubForKind(AppState state, LogKind kind) {
  return _subsForKind(state, kind).firstOrNull?.id;
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
