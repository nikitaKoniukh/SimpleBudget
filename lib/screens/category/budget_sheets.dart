import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';
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
    await state.addExpense(
      subcategoryId: subId,
      amount: amount,
      date: date,
      note: note.isEmpty ? null : note,
    );
  } else {
    await state.updateExpense(
      Expense(
        id: expense.id,
        subcategoryId: subId,
        amount: amount,
        date: date,
        note: note.isEmpty ? null : note,
        createdAt: expense.createdAt,
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
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final nameCtrl = TextEditingController();
  final plannedCtrl = TextEditingController();
  final installmentCtrl = TextEditingController();

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
              l10n.addSubcategory,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.subcategoryName),
              autofocus: true,
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
  return showAddSubcategorySheet(context, categoryId: categoryId);
}

Future<String?> _pickCategoryAndAddSubcategory(BuildContext context) async {
  final state = context.read<AppState>();
  final categories = state.categories;
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
