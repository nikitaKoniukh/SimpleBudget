import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

/// Shared loan card for Loans screen (full) and Home (dense).
class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    this.dense = false,
    this.canPay = false,
    this.canEdit = false,
    this.onPay,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final Loan loan;
  final bool dense;
  final bool canPay;
  final bool canEdit;
  final VoidCallback? onPay;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  double? get _progress {
    final installment = loan.installmentProgress;
    if (installment != null) return installment;
    if (loan.originalAmount > 0) {
      final paidFrac =
          1.0 - (loan.remainingBalance / loan.originalAmount);
      return paidFrac.clamp(0.0, 1.0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paidOff = loan.isPaidOff;
    final progress = _progress;
    final typeLabel =
        loan.isInstallment ? l10n.loanTypeInstallment : l10n.loanTypeBalance;

    final meta = <String>[];
    if (loan.isInstallment &&
        loan.totalInstallments != null &&
        loan.totalInstallments! > 0) {
      meta.add(
        l10n.loanPaymentsProgress(loan.paidCount, loan.totalInstallments!),
      );
      final left = loan.remainingInstallmentCount;
      if (left != null && !paidOff) {
        meta.add(l10n.loanPaymentsLeft(left));
      }
    } else if (loan.monthlyPayment != null && loan.monthlyPayment! > 0) {
      meta.add(formatIls(loan.monthlyPayment!));
    }

    final card = Material(
      color: Colors.white.withValues(alpha: paidOff ? 0.72 : 0.92),
      borderRadius: BorderRadius.circular(dense ? 12 : 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? onEdit,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            dense ? 12 : 14,
            dense ? 10 : 14,
            dense ? 8 : 10,
            dense ? 10 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                                loan.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: paidOff
                                          ? SyncColors.textMuted
                                          : null,
                                      decoration: paidOff
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TypeChip(label: typeLabel, muted: paidOff),
                          ],
                        ),
                        SizedBox(height: dense ? 4 : 6),
                        Text(
                          formatIls(loan.remainingBalance),
                          style: (dense
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.titleLarge)
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: paidOff
                                ? SyncColors.textMuted
                                : SyncColors.text,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            meta.join(' · '),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: SyncColors.textMuted,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canPay && onPay != null)
                    IconButton(
                      tooltip: l10n.logDebt,
                      icon: const Icon(Icons.payments_outlined),
                      color: SyncColors.primary,
                      onPressed: onPay,
                    ),
                  if (!dense && canEdit)
                    PopupMenuButton<_LoanAction>(
                      icon: Icon(
                        Icons.more_vert,
                        color: SyncColors.textMuted,
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case _LoanAction.edit:
                            onEdit?.call();
                          case _LoanAction.delete:
                            onDelete?.call();
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: _LoanAction.edit,
                            child: Text(l10n.editLoan),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: _LoanAction.delete,
                            child: Text(l10n.delete),
                          ),
                      ],
                    ),
                ],
              ),
              if (progress != null) ...[
                SizedBox(height: dense ? 8 : 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: dense ? 4 : 6,
                    child: ColoredBox(
                      color: SyncColors.surfaceMint,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: ColoredBox(
                            color: paidOff
                                ? SyncColors.textMuted
                                : SyncColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (dense) return card;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: card,
    );
  }
}

enum _LoanAction { edit, delete }

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SyncColors.surfaceMint.withValues(alpha: muted ? 0.5 : 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: muted ? SyncColors.textMuted : SyncColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
