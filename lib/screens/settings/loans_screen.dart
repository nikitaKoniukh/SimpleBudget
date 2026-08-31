import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/sync_app_bar.dart';
import '../home/log_entry_sheet.dart';
import 'loan_sheets.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final loans = List.of(state.loans)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.page(title: l10n.loans),
        floatingActionButton: state.canEditPlan
            ? FloatingActionButton.extended(
                onPressed: () => showAddLoanSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addLoan),
              )
            : null,
        body: loans.isEmpty
            ? Center(child: Text(l10n.noData))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  for (final loan in loans)
                    Card(
                      child: ListTile(
                        title: Text(
                          loan.name,
                          style: TextStyle(
                            decoration: loan.isPaidOff
                                ? TextDecoration.lineThrough
                                : null,
                            color: loan.isPaidOff
                                ? SyncColors.textMuted
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          [
                            loan.isInstallment
                                ? l10n.loanTypeInstallment
                                : l10n.loanTypeBalance,
                            if (loan.isInstallment &&
                                loan.totalInstallments != null &&
                                loan.totalInstallments! > 0)
                              l10n.loanPaymentsProgress(
                                loan.paidCount,
                                loan.totalInstallments!,
                              ),
                            if (loan.remainingInstallmentCount != null &&
                                !loan.isPaidOff)
                              l10n.loanPaymentsLeft(
                                loan.remainingInstallmentCount!,
                              ),
                            if (loan.monthlyPayment != null)
                              formatIls(loan.monthlyPayment!),
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatIls(loan.remainingBalance),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (state.hasMonthSelected &&
                                loan.isActive &&
                                !loan.isPaidOff)
                              IconButton(
                                tooltip: l10n.logDebt,
                                icon: const Icon(Icons.payments_outlined),
                                onPressed: () => showLogEntrySheet(
                                  context,
                                  kind: LogKind.loanPayment,
                                  loanId: loan.id,
                                ),
                              ),
                            if (state.canEditPlan)
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => state.deleteLoan(loan.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
