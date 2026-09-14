import 'package:flutter/material.dart';

import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

const amountColWidth = 80.0;

/// Shared Spent | Planned (or Deposited | Planned) header for envelope tables.
class BudgetAmountHeaders extends StatelessWidget {
  const BudgetAmountHeaders({
    super.key,
    required this.spentLabel,
    required this.plannedLabel,
    this.leadingInset = 0,
  });

  final String spentLabel;
  final String plannedLabel;
  final double leadingInset;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: SyncColors.textMuted,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(12 + leadingInset, 4, 12, 2),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: amountColWidth,
            child: Text(spentLabel, textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: amountColWidth,
            child: Text(plannedLabel, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

/// Name + spent/planned amounts + optional thin progress under the row.
class EnvelopeAmountRow extends StatelessWidget {
  const EnvelopeAmountRow({
    super.key,
    required this.name,
    required this.spent,
    required this.planned,
    this.leading,
    this.meta,
    this.nameStyle,
    this.showProgress = true,
  });

  final String name;
  final double spent;
  final double planned;
  final Widget? leading;
  final String? meta;
  final TextStyle? nameStyle;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final overPlan = spent > planned && planned > 0;
    final progress = planned > 0
        ? (spent / planned).clamp(0.0, 1.0)
        : (spent > 0 ? 1.0 : 0.0);
    final barColor = overPlan ? SyncColors.overspend : SyncColors.primary;
    final spentColor = overPlan ? SyncColors.overspend : SyncColors.text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: nameStyle ??
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: overPlan ? SyncColors.overspend : null,
                              ),
                    ),
                    if (meta != null && meta!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: amountColWidth,
                child: Text(
                  formatIls(spent),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: spentColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SizedBox(
                width: amountColWidth,
                child: Text(
                  formatIls(planned),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SyncColors.textMuted,
                      ),
                ),
              ),
            ],
          ),
          if (showProgress && (planned > 0 || spent > 0)) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: SyncColors.surfaceMint,
                color: barColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
