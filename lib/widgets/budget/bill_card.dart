import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

/// Frosted card for a recurring bill on the Recurring bills screen.
class BillCard extends StatelessWidget {
  const BillCard({
    super.key,
    required this.bill,
    required this.dueSoon,
    this.subcategoryLabel,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  final RecurringBill bill;
  final bool dueSoon;
  final String? subcategoryLabel;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = <String>[
      '${l10n.billDay} ${bill.dayOfMonth}',
      if (subcategoryLabel != null && subcategoryLabel!.isNotEmpty)
        subcategoryLabel!,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              bill.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (dueSoon) ...[
                            const SizedBox(width: 8),
                            _DueSoonChip(label: l10n.dueSoon),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatIls(bill.amount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SyncColors.text,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  PopupMenuButton<_BillAction>(
                    icon: Icon(
                      Icons.more_vert,
                      color: SyncColors.textMuted,
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _BillAction.edit:
                          onEdit?.call();
                        case _BillAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: _BillAction.edit,
                          child: Text(l10n.editBill),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: _BillAction.delete,
                          child: Text(l10n.delete),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _BillAction { edit, delete }

class _DueSoonChip extends StatelessWidget {
  const _DueSoonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SyncColors.warning.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: SyncColors.warning,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
