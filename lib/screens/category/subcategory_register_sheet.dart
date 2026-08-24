import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';
import '../home/log_entry_sheet.dart';

/// Full subcategory detail: editable plan, target, name + transaction list.
Future<void> showSubcategoryRegisterSheet(
  BuildContext context, {
  required Subcategory subcategory,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (!state.hasMonthSelected) return;

  final cat = state.categoryById(subcategory.categoryId);
  final isSavings = cat?.isSavings ?? false;
  final plan = state.planFor(subcategory.id);

  final nameCtrl = TextEditingController(
    text: subcategory.localizedName(state.localeCode),
  );
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
  final targetCtrl = TextEditingController(
    text: subcategory.targetAmount != null && subcategory.targetAmount! > 0
        ? subcategory.targetAmount!.toStringAsFixed(2)
        : '',
  );
  final categoryTargetCtrl = TextEditingController(
    text: cat?.targetAmount != null && cat!.targetAmount! > 0
        ? cat.targetAmount!.toStringAsFixed(2)
        : '',
  );
  var targetDate = subcategory.targetDate;

  final dateFmt = DateFormat.yMMMd(
    Localizations.localeOf(context).languageCode,
  );

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            final live = ctx.watch<AppState>();
            final sub = live.subcategoryById(subcategory.id) ?? subcategory;
            final category = live.categoryById(sub.categoryId) ?? cat;
            final isPot = category?.isSavings ?? isSavings;
            final expenses = live.expensesFor(sub.id);
            final spent = live.spentFor(sub.id);
            final canEdit = live.canEditPlan;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (category != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(category.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.localizedName(live.localeCode),
                          style: Theme.of(ctx)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: SyncColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  if (category.isSavings ||
                      category.targetAmount != null) ...[
                    const SizedBox(height: 8),
                    if (category.savedTotal > 0)
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.savedLabel,
                        ),
                        child: Text(
                          formatIls(category.savedTotal),
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: categoryTargetCtrl,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.targetAmount,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  enabled: canEdit,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.subcategoryName),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.spentLabel,
                        ),
                        child: Text(
                          formatIls(spent),
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: plannedCtrl,
                        enabled: canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.plannedLabel,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isPot) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: installmentCtrl,
                    enabled: canEdit,
                    decoration: InputDecoration(
                      labelText: '${l10n.installment} (1/12)',
                      hintText: l10n.installmentHint,
                      helperText: l10n.installmentHelper,
                    ),
                  ),
                ],
                if (isPot) ...[
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.savedLabel,
                    ),
                    child: Text(
                      formatIls(sub.savedTotal),
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: targetCtrl,
                    enabled: canEdit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.targetAmount,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.targetDate),
                    subtitle: Text(
                      targetDate == null ? '—' : dateFmt.format(targetDate!),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: canEdit
                        ? () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: targetDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365 * 5),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 30),
                              ),
                            );
                            if (picked == null) return;
                            setModal(() => targetDate = picked);
                          }
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  isPot ? l10n.thisMonthDeposits : l10n.recentExpenses,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      isPot
                          ? l10n.noDepositsThisMonth
                          : l10n.noExpensesYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SyncColors.textMuted),
                    ),
                  )
                else
                  ...expenses.map((expense) {
                    final note = expense.note?.trim();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        note == null || note.isEmpty ? '—' : note,
                      ),
                      subtitle: Text(dateFmt.format(expense.date)),
                      trailing: Text(
                        formatIls(expense.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        Navigator.pop(ctx, 'edit_expense');
                        showLogEntrySheet(
                          context,
                          kind: isPot || expense.isDeposit
                              ? LogKind.save
                              : LogKind.spend,
                          expense: expense,
                        );
                      },
                    );
                  }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx, 'add');
                          showLogEntrySheet(
                            context,
                            kind: isPot ? LogKind.save : LogKind.spend,
                            subcategoryId: sub.id,
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          isPot ? l10n.logDeposit : l10n.addExpense,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: canEdit
                            ? () => Navigator.pop(ctx, 'save')
                            : null,
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );

  if (result == null || result == 'edit_expense' || result == 'add') return;
  if (!context.mounted) return;

  final live = context.read<AppState>();
  if (!live.canEditPlan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.viewerReadOnlyPlan)),
    );
    return;
  }
  final name = sentenceCase(nameCtrl.text);
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

  final currentSub =
      live.subcategoryById(subcategory.id) ?? subcategory;
  final currentCat = live.categoryById(currentSub.categoryId);
  final isPot =
      currentCat?.isSavings ?? isSavings;

  if (currentCat != null &&
      (currentCat.isSavings || currentCat.targetAmount != null)) {
    final parsedCat =
        double.tryParse(categoryTargetCtrl.text.replaceAll(',', ''));
    final catTarget =
        parsedCat != null && parsedCat > 0 ? parsedCat : null;
    await live.updateCategory(
      currentCat.copyWith(
        targetAmount: catTarget,
        clearTargetAmount: catTarget == null,
      ),
    );
  }

  double? target;
  if (isPot) {
    final parsed = double.tryParse(targetCtrl.text.replaceAll(',', ''));
    target = parsed != null && parsed > 0 ? parsed : null;
    await live.updateSubcategory(
      currentSub.copyWith(
        nameEn: name,
        nameRu: name,
        targetAmount: target,
        clearTargetAmount: target == null,
        targetDate: targetDate,
        clearTargetDate: targetDate == null,
      ),
    );
  } else {
    await live.updateSubcategory(
      currentSub.copyWith(
        nameEn: name,
        nameRu: name,
        installmentTotal: instTot,
        clearInstallmentTotal: instTot == null && inst.isEmpty,
      ),
    );
  }

  await live.upsertPlan(
    subcategoryId: currentSub.id,
    planned: planned,
    installmentCurrent: instCur,
    clearInstallmentCurrent: inst.isEmpty,
  );
}
