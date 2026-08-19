import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../utils/money.dart';
import '../../theme/sync_theme.dart';
import '../../widgets/form_sheet.dart';
import '../investments/investments_sheets.dart';
import 'categories_screen.dart';

Future<void> showExpenseEditor(
  BuildContext context, {
  Expense? expense,
  String? subcategoryId,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (!state.hasMonthSelected) return;

  var selectedSubId = expense?.subcategoryId ??
      subcategoryId ??
      state.subcategories.firstOrNull?.id;
  final amountCtrl = TextEditingController(
    text: expense != null ? expense.amount.toStringAsFixed(2) : '',
  );
  final noteCtrl = TextEditingController(text: expense?.note ?? '');
  var date = expense?.date ?? DateTime.now();

  var split = false;
  var splitSubId = state.subcategories
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
            final subs = live.subcategories;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  expense == null ? l10n.addExpense : l10n.save,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                if (subs.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Text(l10n.noSubcategories),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final subId = await _addCategoryAndSubcategory(
                                ctx,
                              );
                              if (subId != null) {
                                setModal(() => selectedSubId = subId);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addCategory),
                          ),
                          if (live.categories.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final subId = await _pickCategoryAndAddSubcategory(
                                  ctx,
                                );
                                if (subId != null) {
                                  setModal(() => selectedSubId = subId);
                                }
                              },
                              icon: const Icon(Icons.account_tree_outlined),
                              label: Text(l10n.addSubcategory),
                            ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedSubId),
                        initialValue: selectedSubId,
                        decoration: InputDecoration(labelText: l10n.subcategory),
                        items: subs.map((sub) {
                          final cat = live.categoryById(sub.categoryId);
                          final catName = cat?.localizedName(live.localeCode);
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final subId = await _addCategoryAndSubcategory(ctx);
                              if (subId != null) {
                                setModal(() => selectedSubId = subId);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addCategory),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final subId = await _pickCategoryAndAddSubcategory(
                                ctx,
                              );
                              if (subId != null) {
                                setModal(() => selectedSubId = subId);
                              }
                            },
                            icon: const Icon(Icons.account_tree_outlined),
                            label: Text(l10n.addSubcategory),
                          ),
                        ],
                      ),
                    ],
                  ),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.amount),
                  autofocus: expense == null,
                ),
                TextField(
                  controller: noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.note),
                ),
                if (expense == null && (subs.length >= 2))
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.splitSpend),
                    value: split,
                    onChanged: (v) => setModal(() => split = v),
                  ),
                if (expense == null && split) ...[
                  DropdownButtonFormField<String>(
                    initialValue: splitSubId,
                    decoration: InputDecoration(labelText: '${l10n.splitPart} 2'),
                    items: subs
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${l10n.splitPart} 2 ${l10n.amount}',
                    ),
                  ),
                ],
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
                  onPressed: selectedSubId == null
                      ? null
                      : () => Navigator.pop(ctx, 'save'),
                  child: Text(l10n.save),
                ),
                if (expense != null)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'delete'),
                    child: Text(
                      l10n.delete,
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
  if (result == 'delete' && expense != null) {
    await state.deleteExpense(expense.id);
    return;
  }

  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  final subId = selectedSubId;
  if (amount <= 0 || subId == null) return;
  final note = sentenceCase(noteCtrl.text);

  if (expense == null) {
    if (split) {
      final part2 = double.tryParse(splitAmountCtrl.text.replaceAll(',', '')) ?? 0;
      final rest = amount - part2;
      final secondId = splitSubId;
      if (secondId == null || part2 <= 0 || rest <= 0) return;
      await state.addSplitExpenses(
        date: date,
        note: note.isEmpty ? null : note,
        parts: [
          (subcategoryId: subId, amount: rest),
          (subcategoryId: secondId, amount: part2),
        ],
      );
    } else {
      await state.addExpense(
        subcategoryId: subId,
        amount: amount,
        date: date,
        note: note.isEmpty ? null : note,
      );
    }
  } else {
    await state.updateExpense(
      Expense(
        id: expense.id,
        subcategoryId: subId,
        amount: amount,
        date: date,
        note: note.isEmpty ? null : note,
        createdAt: expense.createdAt,
        createdBy: expense.createdBy,
        createdByName: expense.createdByName,
        isDeposit: expense.isDeposit,
        splitGroupId: expense.splitGroupId,
      ),
    );
  }
}

Future<void> showPlanEditor(
  BuildContext context, {
  required Subcategory subcategory,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (!state.canEditPlan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.viewerReadOnlyPlan)),
    );
    return;
  }
  final plan = state.planFor(subcategory.id);
  final plannedCtrl = TextEditingController(
    text: plan != null && plan.planned > 0
        ? plan.planned.toStringAsFixed(2)
        : '',
  );
  final installmentCtrl = TextEditingController(
    text: plan?.installmentCurrent != null &&
            subcategory.installmentTotal != null
        ? '${plan!.installmentCurrent}/${subcategory.installmentTotal}'
        : '',
  );

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(l10n.editPlan, style: Theme.of(ctx).textTheme.titleLarge),
            Text(subcategory.localizedName(state.localeCode)),
            TextField(
              controller: plannedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.plannedLabel),
              autofocus: true,
            ),
            TextField(
              controller: installmentCtrl,
              decoration: InputDecoration(
                labelText: '${l10n.installment} (1/12)',
                hintText: l10n.installmentHint,
                helperText: l10n.installmentHelper,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return;
  final planned =
      double.tryParse(plannedCtrl.text.replaceAll(',', '')) ?? 0;
  int? instCur;
  int? instTot;
  final inst = installmentCtrl.text.trim();
  if (inst.contains('/')) {
    final parts = inst.split('/');
    instCur = int.tryParse(parts[0].trim());
    instTot = int.tryParse(parts[1].trim());
  }
  await state.upsertPlan(
    subcategoryId: subcategory.id,
    planned: planned,
    installmentCurrent: instCur,
    clearInstallmentCurrent: inst.isEmpty,
  );
  if (instTot != subcategory.installmentTotal) {
    await state.updateSubcategory(
      subcategory.copyWith(
        installmentTotal: instTot,
        clearInstallmentTotal: instTot == null,
      ),
    );
  }
}

Future<String?> showAddSubcategorySheet(
  BuildContext context, {
  required String categoryId,
  Subcategory? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final plan = existing != null ? state.planFor(existing.id) : null;
  final nameCtrl = TextEditingController(
    text: existing?.localizedName(state.localeCode) ?? '',
  );
  final plannedCtrl = TextEditingController(
    text: plan != null && plan.planned > 0
        ? plan.planned.toStringAsFixed(2)
        : '',
  );
  final installmentCtrl = TextEditingController(
    text: plan?.installmentCurrent != null &&
            existing?.installmentTotal != null
        ? '${plan!.installmentCurrent}/${existing!.installmentTotal}'
        : '',
  );

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              existing == null ? l10n.addSubcategory : l10n.editSubcategory,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.subcategoryName),
              autofocus: existing == null,
            ),
            TextField(
              controller: plannedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.plannedLabel),
            ),
            TextField(
              controller: installmentCtrl,
              decoration: InputDecoration(
                labelText: '${l10n.installment} (1/12)',
                hintText: l10n.installmentHint,
                helperText: l10n.installmentHelper,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return null;
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return null;
  final planned =
      double.tryParse(plannedCtrl.text.replaceAll(',', '')) ?? 0;
  int? instCur;
  int? instTot;
  final inst = installmentCtrl.text.trim();
  if (inst.contains('/')) {
    final parts = inst.split('/');
    instCur = int.tryParse(parts[0].trim());
    instTot = int.tryParse(parts[1].trim());
  }
  if (existing != null) {
    await state.updateSubcategory(
      existing.copyWith(
        nameEn: name,
        nameRu: name,
        installmentTotal: instTot,
        clearInstallmentTotal: instTot == null,
      ),
    );
    await state.upsertPlan(
      subcategoryId: existing.id,
      planned: planned,
      installmentCurrent: instCur,
      clearInstallmentCurrent: inst.isEmpty,
    );
    return existing.id;
  }
  return state.addSubcategory(
    categoryId: categoryId,
    name: name,
    planned: planned,
    installmentCurrent: instCur,
    installmentTotal: instTot,
  );
}

Future<String?> _addCategoryAndSubcategory(BuildContext context) async {
  final categoryId = await showAddCategoryFlow(context);
  if (categoryId == null || !context.mounted) return null;
  final state = context.read<AppState>();
  if (state.subcategoryById(categoryId) != null) return categoryId;
  final cat = state.categoryById(categoryId);
  if (cat == null) return null;
  return showAddSubcategorySheet(context, categoryId: cat.id);
}

Future<String?> _pickCategoryAndAddSubcategory(BuildContext context) async {
  final state = context.read<AppState>();
  final categories =
      state.categories.where((c) => !c.isSavings).toList();
  if (categories.isEmpty) {
    return _addCategoryAndSubcategory(context);
  }
  if (categories.length == 1) {
    return showAddSubcategorySheet(context, categoryId: categories.first.id);
  }

  final l10n = AppLocalizations.of(context);
  String categoryId = categories.first.id;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  l10n.addSubcategory,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.localizedName(state.localeCode)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModal(() => categoryId = value);
                  },
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.continueLabel),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return null;
  return showAddSubcategorySheet(context, categoryId: categoryId);
}

Future<void> showSubcategoryExpensesSheet(
  BuildContext context, {
  required Subcategory subcategory,
}) async {
  final l10n = AppLocalizations.of(context);
  final dateFmt = DateFormat.yMMMd(
    Localizations.localeOf(context).languageCode,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
          return FormSheet(
            child: Consumer<AppState>(
              builder: (ctx, state, _) {
                final isSavings =
                    state.categoryById(subcategory.categoryId)?.isSavings ??
                        false;
                final expenses = state.expensesFor(subcategory.id);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      subcategory.localizedName(state.localeCode),
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    Text(
                      '${formatIls(state.spentFor(subcategory.id))} / ${formatIls(state.plannedFor(subcategory.id))}',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: SyncColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: expenses.isEmpty
                          ? Center(child: Text(l10n.noExpensesYet))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: expenses.length,
                              itemBuilder: (ctx, index) {
                                final expense = expenses[index];
                                final note = expense.note?.trim();
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    note == null || note.isEmpty
                                        ? '—'
                                        : note,
                                  ),
                                  subtitle: Text(dateFmt.format(expense.date)),
                                  trailing: Text(
                                    formatIls(expense.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    if (isSavings || expense.isDeposit) {
                                      showDepositEditor(
                                        context,
                                        expense: expense,
                                      );
                                      return;
                                    }
                                    showExpenseEditor(
                                      context,
                                      expense: expense,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (isSavings) {
                          showDepositEditor(
                            context,
                            subcategory: subcategory,
                          );
                          return;
                        }
                        showExpenseEditor(
                          context,
                          subcategoryId: subcategory.id,
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        isSavings ? l10n.logDeposit : l10n.addExpense,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    },
  );
}
