import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

/// Compact 4-segment overview: spent, remaining budget, unallocated income.
class BudgetOverviewBar extends StatelessWidget {
  const BudgetOverviewBar({
    super.key,
    required this.totals,
  });

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final income = totals.income;
    final planned = totals.planned;
    final spent = totals.actual;
    final unallocated = (income - planned).clamp(0.0, double.infinity);
    final remaining = (planned - spent).clamp(0.0, double.infinity);
    final overSpent = spent > planned ? spent - planned : 0.0;

    final segments = <_Segment>[];
    if (income <= 0) {
      if (spent > 0) {
        segments.add(_Segment(spent, SyncColors.accent, l10n.spentLabel));
      }
    } else {
      final scale = income;
      if (spent <= planned) {
        if (spent > 0) {
          segments.add(
            _Segment(spent / scale, SyncColors.accent, l10n.spentLabel),
          );
        }
        if (remaining > 0) {
          segments.add(
            _Segment(
              remaining / scale,
              SyncColors.primary,
              l10n.remaining,
            ),
          );
        }
        if (unallocated > 0) {
          segments.add(
            _Segment(
              unallocated / scale,
              SyncColors.surfaceMint,
              l10n.unallocated,
            ),
          );
        }
      } else {
        segments.add(
          _Segment(planned / scale, SyncColors.accent, l10n.spentLabel),
        );
        if (overSpent > 0) {
          segments.add(
            _Segment(
              (overSpent / scale).clamp(0.0, 1.0),
              SyncColors.overspend,
              l10n.overspent,
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: l10n.income,
                      amount: totals.income,
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      label: l10n.plannedLabel,
                      amount: totals.planned,
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      label: l10n.spentLabel,
                      amount: totals.actual,
                      highlight: totals.actual > totals.planned &&
                          totals.planned > 0,
                    ),
                  ),
                ],
              ),
              if (segments.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        for (final seg in segments)
                          Expanded(
                            flex: (seg.flex * 1000).round().clamp(1, 100000),
                            child: Container(color: seg.color),
                          ),
                      ],
                    ),
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

class _Segment {
  const _Segment(this.flex, this.color, this.label);

  final double flex;
  final Color color;
  final String label;
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final double amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SyncColors.textMuted,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          formatIls(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? SyncColors.overspend : null,
              ),
        ),
      ],
    );
  }
}
