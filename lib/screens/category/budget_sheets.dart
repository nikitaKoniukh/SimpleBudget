import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';

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
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            final live = ctx.watch<AppState>();
            final subs = live.subcategories;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expense == null ? l10n.addExpense : l10n.save,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (subs.isEmpty)
                    Text(l10n.noSubcategories)
                  else
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
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.amount),
                    autofocus: expense == null,
                  ),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(labelText: l10n.note),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
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
              ),
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
  final note = noteCtrl.text.trim();

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
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.editPlan, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
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
              ),
            ),
            const SizedBox(height: 16),
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

Future<void> showAddSubcategorySheet(
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
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addSubcategory,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              TextField(
                controller: nameCtrl,
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
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return;
  final name = nameCtrl.text.trim();
  if (name.isEmpty) return;
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
  await state.addSubcategory(
    categoryId: categoryId,
    name: name,
    planned: planned,
    installmentCurrent: instCur,
    installmentTotal: instTot,
  );
}
