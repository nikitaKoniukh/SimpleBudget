import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../navigation/adaptive_page_route.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/budget_overview_bar.dart';
import '../../widgets/budget/category_budget_section.dart';
import '../../widgets/budget/savings_budget_section.dart';
import '../../widgets/sync_app_bar.dart';
import '../category/category_sheets.dart';
import '../settings/loan_sheets.dart';
import '../settings/loans_screen.dart';
import 'create_month_flow.dart';
import 'log_entry_sheet.dart';
import 'quick_log_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.home(),
          body: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshBudget(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(28),
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: SyncColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.emptyMonths,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: SyncColors.textMuted,
                      ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: FilledButton(
                    onPressed: () => openCreateMonthFlow(context),
                    child: Text(l10n.createThisMonth),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final spendCats = state.categoriesOfType('spend');
    final monthlyCats = state.categoriesOfType('monthly');
    final loans = List.of(state.activeLoans)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final hasAny =
        spendCats.isNotEmpty ||
        monthlyCats.isNotEmpty ||
        loans.isNotEmpty ||
        state.savingsPots.isNotEmpty;

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.home(),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'home-log-fab',
          onPressed: () => showQuickLogSheet(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.log),
        ),
        body: RefreshIndicator(
          onRefresh: () => context.read<AppState>().refreshBudget(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              BudgetOverviewBar(totals: state.totals),
              if (!hasAny)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.emptyCategories,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => showAddCategoryFlow(context),
                          child: Text(l10n.addCategory),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            final n = await state.addDefaultCategories();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  n > 0
                                      ? l10n.defaultsAdded
                                      : l10n.defaultsAlreadyPresent,
                                ),
                              ),
                            );
                          },
                          child: Text(l10n.addDefaultCategories),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _TypedSection(
                  title: l10n.sectionSpend,
                  categories: spendCats,
                  preferredType: 'spend',
                ),
                _TypedSection(
                  title: l10n.sectionMonthly,
                  categories: monthlyCats,
                  preferredType: 'monthly',
                ),
                _LoansSection(loans: loans),
                const SavingsBudgetSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypedSection extends StatelessWidget {
  const _TypedSection({
    required this.title,
    required this.categories,
    required this.preferredType,
  });

  final String title;
  final List<BudgetCategory> categories;
  final String preferredType;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final canEdit = context.watch<AppState>().canEditPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SyncColors.textMuted,
                      ),
                ),
              ),
              if (canEdit)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: SyncColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => showAddCategoryFlow(
                    context,
                    preferredType: preferredType,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(l10n.addCategory),
                ),
            ],
          ),
        ),
        ...categories.map((cat) => CategoryBudgetSection(category: cat)),
      ],
    );
  }
}

class _LoansSection extends StatelessWidget {
  const _LoansSection({required this.loans});

  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = context.watch<AppState>().canEditPlan;
    if (loans.isEmpty && !canEdit) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sectionDebt,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SyncColors.textMuted,
                      ),
                ),
              ),
              if (canEdit)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: SyncColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => showAddLoanSheet(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(l10n.addLoan),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: SyncColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    pushAdaptivePage(context, const LoansScreen()),
                child: Text(l10n.seeAll),
              ),
            ],
          ),
        ),
        if (loans.isEmpty)
          Material(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.noData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ),
          )
        else
          Material(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < loans.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: SyncColors.textMuted.withValues(alpha: 0.12),
                    ),
                  _LoanHomeRow(loan: loans[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _LoanHomeRow extends StatelessWidget {
  const _LoanHomeRow({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: SyncColors.textMuted,
    );
    final paidOff = loan.isPaidOff;
    final progress = loan.installmentProgress;
    final total = loan.totalInstallments;
    final left = loan.remainingInstallmentCount;
    final canPay = loan.isActive && !paidOff;

    final progressLine = <String>[];
    if (loan.isInstallment && total != null && total > 0) {
      progressLine.add(l10n.loanPaymentsProgress(loan.paidCount, total));
      if (left != null && !paidOff) {
        progressLine.add(l10n.loanPaymentsLeft(left));
      }
    } else {
      progressLine.add(
        loan.isInstallment
            ? l10n.loanTypeInstallment
            : l10n.loanTypeBalance,
      );
      if (loan.monthlyPayment != null && loan.monthlyPayment! > 0) {
        progressLine.add(formatIls(loan.monthlyPayment!));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: paidOff ? SyncColors.textMuted : null,
                    decoration: paidOff ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.remainingBalance}: ${formatIls(loan.remainingBalance)}',
                  style: muted,
                ),
                if (progressLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(progressLine.join(' · '), style: muted),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          SyncColors.textMuted.withValues(alpha: 0.15),
                      color: paidOff ? SyncColors.textMuted : SyncColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canPay)
            IconButton(
              tooltip: l10n.logDebt,
              icon: const Icon(Icons.payments_outlined),
              onPressed: () => showLogEntrySheet(
                context,
                kind: LogKind.loanPayment,
                loanId: loan.id,
              ),
            )
          else if (paidOff)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.check_circle_outline,
                color: SyncColors.textMuted,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}
