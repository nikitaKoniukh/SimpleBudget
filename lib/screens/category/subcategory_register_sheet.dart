import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../utils/text_format.dart';
import '../../widgets/budget/category_color_icon.dart';
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
    text: state.localizedSubcategoryName(subcategory),
  );
  final plannedCtrl = TextEditingController(
    text: plan != null && plan.planned > 0
        ? plan.planned.toStringAsFixed(2)
        : '',
  );
  final installmentCurrentCtrl = TextEditingController(
    text: plan?.installmentCurrent != null
        ? '${plan!.installmentCurrent}'
        : '',
  );
  final installmentTotalCtrl = TextEditingController(
    text: subcategory.installmentTotal != null
        ? '${subcategory.installmentTotal}'
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
                      CategoryColorIcon(
                        colorValue: category.colorValue,
                        iconKey: category.iconKey,
                        size: 22,
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
                    if (category?.isDebt ?? false) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: installmentCurrentCtrl,
                              enabled: canEdit,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.installmentCurrent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: installmentTotalCtrl,
                              enabled: canEdit,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.installmentTotal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.installmentHelper,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: SyncColors.textMuted,
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
                        final editKind = isPot || expense.isDeposit
                            ? LogKind.save
                            : (category?.isDebt ?? false)
                                ? LogKind.debt
                                : LogKind.spend;
                        showLogEntrySheet(
                          context,
                          kind: editKind,
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
                          final addKind = isPot
                              ? LogKind.save
                              : (category?.isDebt ?? false)
                                  ? LogKind.debt
                                  : LogKind.spend;
                          showLogEntrySheet(
                            context,
                            kind: addKind,
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
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: Text(l10n.removeFromMonth),
                          content: Text(l10n.removeFromMonthConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: Text(l10n.removeFromMonth),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && ctx.mounted) {
                        Navigator.pop(ctx, 'delete');
                      }
                    },
                    child: Text(l10n.removeFromMonth),
                  ),
                ],
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
  if (result == 'delete') {
    await live.removeSubcategoryFromMonth(subcategory.id);
    return;
  }
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
  final curText = installmentCurrentCtrl.text.trim();
  final totText = installmentTotalCtrl.text.trim();
  final instCur = int.tryParse(curText);
  final instTot = int.tryParse(totText);

  final currentSub =
      live.subcategoryById(subcategory.id) ?? subcategory;
  final currentCat = live.categoryById(currentSub.categoryId);
  final isPot = currentCat?.isSavings ?? isSavings;
  final isDebt = currentCat?.isDebt ?? false;

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
        targetAmount: target,
        clearTargetAmount: target == null,
        targetDate: targetDate,
        clearTargetDate: targetDate == null,
      ),
    );
  } else if (isDebt) {
    await live.updateSubcategory(
      currentSub.copyWith(
        installmentTotal: instTot,
        clearInstallmentTotal: totText.isEmpty,
      ),
    );
  }

  final nameEnOverride = name == currentSub.nameEn ? null : name;
  final nameRuOverride = name == currentSub.nameRu ? null : name;
  await live.upsertPlan(
    subcategoryId: currentSub.id,
    planned: planned,
    installmentCurrent: isDebt ? instCur : null,
    clearInstallmentCurrent: !isDebt || curText.isEmpty,
    nameEn: nameEnOverride,
    nameRu: nameRuOverride,
    clearNameEn: nameEnOverride == null,
    clearNameRu: nameRuOverride == null,
  );
}
