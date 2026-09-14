import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

/// Month health: Remaining, then Income / Spent / Saved / Budget.
class BudgetOverviewBar extends StatelessWidget {
  const BudgetOverviewBar({
    super.key,
    required this.totals,
  });

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remaining = totals.spendRemaining;
    final isOver = remaining < 0;
    final primaryAmount = isOver ? -remaining : remaining;
    final primaryLabel = isOver ? l10n.overLabel : l10n.remaining;
    final primaryColor = isOver ? SyncColors.overspend : SyncColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                primaryLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                formatIls(primaryAmount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: l10n.income,
                      amount: totals.income,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatTile(
                      label: l10n.spentLabel,
                      amount: totals.actual,
                      highlight: isOver && totals.income > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: l10n.savedLabel,
                      amount: totals.savedThisMonth,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatTile(
                      label: l10n.budget,
                      amount: totals.planned,
                    ),
                  ),
                ],
              ),
              if (totals.planExceedsIncome) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.planExceedsIncome,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SyncColors.warning,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final double amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SyncColors.surfaceMint.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            formatIls(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlight ? SyncColors.overspend : SyncColors.text,
                ),
          ),
        ],
      ),
    );
  }
}
