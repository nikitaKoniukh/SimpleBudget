import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/money.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';

Future<void> showSetAsideActionsSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.add),
                ),
                title: Text(l10n.addPot),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddPotFlow(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.savings_outlined),
                ),
                title: Text(l10n.logDeposit),
                onTap: () {
                  Navigator.pop(ctx);
                  showDepositEditor(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> showAddPotFlow(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final existing = {
    for (final s in state.savingsPots) s.nameEn.toLowerCase(),
  };
  final available = DefaultPots.all
      .where((p) => !existing.contains(p.nameEn.toLowerCase()))
      .toList();

  final choice = await showModalBottomSheet<_PotSourceChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (modalContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addPot,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (available.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: available.map((pot) {
                    return ActionChip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(
                          DefaultCategories.savingsColorValue,
                        ),
                        radius: 8,
                      ),
                      label: Text(pot.localizedName(state.localeCode)),
                      onPressed: () => Navigator.pop(
                        modalContext,
                        _PotSourceChoice.suggested(pot),
                      ),
                    );
                  }).toList(),
                )
              else
                Text(l10n.noSuggestionsLeft),
              const SizedBox(height: 12),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.customCategory),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(
                  modalContext,
                  const _PotSourceChoice.custom(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (choice == null || !context.mounted) return null;
  try {
    if (choice.suggested != null) {
      return context.read<AppState>().addSuggestedPot(choice.suggested!);
    }
    if (choice.wantsCustom) {
      return showEditPotSheet(context);
    }
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
  }
  return null;
}

class _PotSourceChoice {
  const _PotSourceChoice.custom() : suggested = null, wantsCustom = true;
  const _PotSourceChoice.suggested(this.suggested) : wantsCustom = false;

  final DefaultPot? suggested;
  final bool wantsCustom;
}

Future<String?> showEditPotSheet(
  BuildContext context, [
  Subcategory? existing,
]) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final nameCtrl = TextEditingController(
    text: existing?.localizedName(state.localeCode) ?? '',
  );
  final targetCtrl = TextEditingController(
    text: existing?.targetAmount != null && existing!.targetAmount! > 0
        ? existing.targetAmount!.toStringAsFixed(2)
        : '',
  );

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(
              existing == null ? l10n.addPot : l10n.editPot,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.subcategoryName),
              autofocus: existing == null,
            ),
            TextField(
              controller: targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.targetOptional),
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
  final parsed = double.tryParse(targetCtrl.text.replaceAll(',', ''));
  final target = parsed != null && parsed > 0 ? parsed : null;

  try {
    if (existing == null) {
      return await state.addPot(name: name, targetAmount: target);
    }
    await state.updateSubcategory(
      existing.copyWith(
        nameEn: name,
        nameRu: name,
        targetAmount: target,
        clearTargetAmount: target == null,
      ),
    );
    return existing.id;
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
  }
  return null;
}

Future<void> showSetTargetSheet(
  BuildContext context, {
  required Subcategory subcategory,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final targetCtrl = TextEditingController(
    text: subcategory.targetAmount != null && subcategory.targetAmount! > 0
        ? subcategory.targetAmount!.toStringAsFixed(2)
        : '',
  );

  final result = await showModalBottomSheet<String>(
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
            Text(l10n.setTarget, style: Theme.of(ctx).textTheme.titleLarge),
            TextField(
              controller: targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.targetOptional),
              autofocus: true,
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: Text(l10n.save),
            ),
            if (subcategory.targetAmount != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'clear'),
                child: Text(l10n.clearTarget),
              ),
          ],
        ),
      );
    },
  );

  if (result == null || !context.mounted) return;
  if (result == 'clear') {
    await state.updateSubcategory(
      subcategory.copyWith(clearTargetAmount: true),
    );
    return;
  }
  final parsed = double.tryParse(targetCtrl.text.replaceAll(',', ''));
  final target = parsed != null && parsed > 0 ? parsed : null;
  await state.updateSubcategory(
    subcategory.copyWith(
      targetAmount: target,
      clearTargetAmount: target == null,
    ),
  );
}

Future<void> showDepositEditor(
  BuildContext context, {
  Subcategory? subcategory,
  Expense? expense,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (!state.hasMonthSelected) return;

  var selectedSubId = subcategory?.id ??
      expense?.subcategoryId ??
      state.savingsPots.firstOrNull?.id;
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
            final pots = live.savingsPots;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  expense == null ? l10n.logDeposit : l10n.save,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                if (pots.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Text(l10n.emptyPots),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final id = await showAddPotFlow(ctx);
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
                    key: ValueKey(selectedSubId),
                    initialValue: selectedSubId,
                    decoration: InputDecoration(labelText: l10n.subcategory),
                    items: pots
                        .map(
                          (pot) => DropdownMenuItem(
                            value: pot.id,
                            child: Text(pot.localizedName(live.localeCode)),
                          ),
                        )
                        .toList(),
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
    await state.addDeposit(
      subcategoryId: subId,
      amount: amount,
      date: date,
      note: note.isEmpty ? null : note,
    );
    return;
  }

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

int _potColor(AppState state, Subcategory pot) {
  return state.categoryById(pot.categoryId)?.colorValue ??
      DefaultCategories.savingsColorValue;
}

Future<void> showPotDetailSheet(
  BuildContext context, {
  required Subcategory subcategory,
}) async {
  final l10n = AppLocalizations.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            final live = ctx.watch<AppState>();
            final pot = live.subcategoryById(subcategory.id) ?? subcategory;
            final deposits = live.expensesFor(pot.id);
            final color = _potColor(live, pot);
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pot.localizedName(live.localeCode),
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.editPot,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showEditPotSheet(context, pot);
                      },
                    ),
                  ],
                ),
                Text(
                  pot.targetAmount != null && pot.targetAmount! > 0
                      ? '${formatIls(pot.savedTotal)} / ${formatIls(pot.targetAmount!)}'
                      : formatIls(pot.savedTotal),
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDepositEditor(context, subcategory: pot);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.logDeposit),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showSetTargetSheet(context, subcategory: pot);
                      },
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(l10n.setTarget),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.thisMonthDeposits,
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (deposits.isEmpty)
                  Text(l10n.noDepositsThisMonth)
                else
                  ...deposits.map((expense) {
                    final note = expense.note?.trim();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        note == null || note.isEmpty
                            ? DateFormat.MMMd().format(expense.date)
                            : note,
                      ),
                      subtitle: note == null || note.isEmpty
                          ? null
                          : Text(DateFormat.MMMd().format(expense.date)),
                      trailing: Text(
                        formatIls(expense.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDepositEditor(
                          context,
                          subcategory: pot,
                          expense: expense,
                        );
                      },
                    );
                  }),
              ],
            );
          },
        ),
      );
    },
  );
}

