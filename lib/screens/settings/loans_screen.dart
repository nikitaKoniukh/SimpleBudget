import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/loan_card.dart';
import '../../widgets/sync_app_bar.dart';
import '../home/log_entry_sheet.dart';
import 'loan_sheets.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  Future<void> _delete(BuildContext context, Loan loan) async {
    final ok = await confirmDeleteLoan(context, loan);
    if (!ok || !context.mounted) return;
    try {
      await context.read<AppState>().deleteLoan(loan.id);
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final canEdit = state.canEditPlan;
    final loans = List.of(state.loans)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final active = loans.where((l) => !l.isPaidOff).toList();
    final paidOff = loans.where((l) => l.isPaidOff).toList();
    final remainingDebt = active.fold<double>(
      0,
      (s, l) => s + l.remainingBalance,
    );
    final originalTotal = active.fold<double>(
      0,
      (s, l) => s + l.originalAmount,
    );
    final monthlyTotal = active.fold<double>(
      0,
      (s, l) => s + (l.monthlyPayment ?? 0),
    );

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.page(title: l10n.loans),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: () => showAddLoanSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addLoan),
              )
            : null,
        body: loans.isEmpty
            ? _EmptyLoans(
                canEdit: canEdit,
                onAdd: () => showAddLoanSheet(context),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _DebtHero(
                    remaining: remainingDebt,
                    original: originalTotal,
                    monthly: monthlyTotal,
                  ),
                  if (active.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        l10n.sectionDebt,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SyncColors.textMuted,
                            ),
                      ),
                    ),
                    for (final loan in active)
                      LoanCard(
                        loan: loan,
                        canPay: state.hasMonthSelected &&
                            loan.isActive &&
                            !loan.isPaidOff,
                        canEdit: canEdit,
                        onPay: () => showLogEntrySheet(
                          context,
                          kind: LogKind.loanPayment,
                          loanId: loan.id,
                        ),
                        onEdit: canEdit
                            ? () => showEditLoanSheet(context, loan: loan)
                            : null,
                        onDelete:
                            canEdit ? () => _delete(context, loan) : null,
                      ),
                  ],
                  if (paidOff.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          '${l10n.paidOffSection} (${paidOff.length})',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SyncColors.textMuted,
                                  ),
                        ),
                        children: [
                          for (final loan in paidOff)
                            LoanCard(
                              loan: loan,
                              canEdit: canEdit,
                              onEdit: canEdit
                                  ? () =>
                                      showEditLoanSheet(context, loan: loan)
                                  : null,
                              onDelete: canEdit
                                  ? () => _delete(context, loan)
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _DebtHero extends StatelessWidget {
  const _DebtHero({
    required this.remaining,
    required this.original,
    required this.monthly,
  });

  final double remaining;
  final double original;
  final double monthly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                l10n.remainingDebt,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                formatIls(remaining),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: SyncColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: l10n.originalAmount,
                      amount: original,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _HeroStat(
                      label: l10n.amountMonthly,
                      amount: monthly,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.amount});

  final String label;
  final double amount;

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
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans({required this.canEdit, required this.onAdd});

  final bool canEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 56,
              color: SyncColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyLoans,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: SyncColors.textMuted,
                  ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(l10n.addLoan),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
