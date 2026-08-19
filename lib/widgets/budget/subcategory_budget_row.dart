import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../screens/category/budget_sheets.dart';
import '../../screens/investments/investments_sheets.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

const _inlineExpenseLimit = 3;

class SubcategoryBudgetRow extends StatelessWidget {
  const SubcategoryBudgetRow({
    super.key,
    required this.subcategory,
    required this.categoryColor,
  });

  final Subcategory subcategory;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final sub = subcategory;
    final planned = state.plannedFor(sub.id);
    final spent = state.spentFor(sub.id);
    final hint = state.installmentHint(sub);
    final isSavings = state.categoryById(sub.categoryId)?.isSavings ?? false;
    final overPlan = spent > planned && planned > 0;
    final overColor = SyncColors.overspend;
    final ratio = planned <= 0
        ? (spent > 0 ? 1.0 : 0.0)
        : (spent / planned).clamp(0.0, 1.0);
    final expenses = state.expensesFor(sub.id);
    final inline = expenses.take(_inlineExpenseLimit).toList();
    final remaining = expenses.length - inline.length;
    final dateFmt = DateFormat.MMMd(state.localeCode);

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (isSavings) {
                  showDepositEditor(context, subcategory: sub);
                  return;
                }
                showExpenseEditor(context, subcategoryId: sub.id);
              },
              onLongPress: () => showPlanEditor(context, subcategory: sub),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.localizedName(state.localeCode),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: overPlan ? overColor : null,
                                    ),
                              ),
                              if (hint != null)
                                Text(
                                  hint,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: SyncColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${formatIls(spent)} / ${formatIls(planned)}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: overPlan ? overColor : SyncColors.text,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor:
                            categoryColor.withValues(alpha: 0.15),
                        color: overPlan ? overColor : categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (inline.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2, bottom: 4),
              child: Text(
                l10n.noExpensesYet,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SyncColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            )
          else
            ...inline.map(
              (expense) => _RecentExpenseRow(
                expense: expense,
                dateLabel: dateFmt.format(expense.date),
                isSavings: isSavings,
              ),
            ),
          if (remaining > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    showSubcategoryExpensesSheet(context, subcategory: sub),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.moreExpenses(remaining)),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentExpenseRow extends StatelessWidget {
  const _RecentExpenseRow({
    required this.expense,
    required this.dateLabel,
    required this.isSavings,
  });

  final Expense expense;
  final String dateLabel;
  final bool isSavings;

  @override
  Widget build(BuildContext context) {
    final note = expense.note?.trim();
    final title = note == null || note.isEmpty ? '—' : note;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isSavings || expense.isDeposit) {
            showDepositEditor(context, expense: expense);
            return;
          }
          showExpenseEditor(context, expense: expense);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SyncColors.textMuted,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                formatIls(expense.amount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
