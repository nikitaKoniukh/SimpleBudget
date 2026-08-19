import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

class AlertsSection extends StatelessWidget {
  const AlertsSection({
    super.key,
    required this.watchlist,
    required this.upcomingBills,
  });

  final List<BudgetCategory> watchlist;
  final List<RecurringBill> upcomingBills;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final count = watchlist.length + upcomingBills.length;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          initiallyExpanded: false,
          leading: Icon(
            Icons.notifications_outlined,
            color: SyncColors.warning,
            size: 22,
          ),
          title: Text(
            '${l10n.alerts} ($count)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          children: [
            if (watchlist.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.watchlist,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: SyncColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in watchlist)
                    Chip(
                      avatar: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: SyncColors.warning,
                      ),
                      label: Text(
                        '${cat.localizedName(state.localeCode)} · ${l10n.overspendAlert}',
                      ),
                      backgroundColor:
                          SyncColors.warning.withValues(alpha: 0.15),
                    ),
                ],
              ),
            ],
            if (watchlist.isNotEmpty && upcomingBills.isNotEmpty)
              const SizedBox(height: 12),
            if (upcomingBills.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.upcomingBills,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: SyncColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              for (final bill in upcomingBills.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(bill.name),
                  subtitle: Text('${l10n.billDay} ${bill.dayOfMonth}'),
                  trailing: Text(formatIls(bill.amount)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
