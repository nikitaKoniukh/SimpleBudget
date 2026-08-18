import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../category/budget_sheets.dart';
import '../category/categories_screen.dart';
import '../investments/investments_sheets.dart';
import '../settings/settings_screen.dart';
import 'create_month_flow.dart';
import 'quick_log_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(l10n.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.settings,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  FilledButton(
                    onPressed: () => openCreateMonthFlow(context),
                    child: Text(l10n.createThisMonth),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final monthId = state.monthId!;
    final monthDate = dateFromMonthId(monthId);
    final totals = state.totals;
    final cashLeft = totals.income - totals.actual;
    final progress = totals.planned <= 0
        ? 0.0
        : (totals.actual / totals.planned).clamp(0.0, 1.0);

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  l10n.monthTitle(monthDate),
                  key: ValueKey(monthId),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (state.household != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    state.household!.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: SyncColors.textMuted,
                        ),
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: l10n.selectMonth,
              onPressed: () => showSelectMonthSheet(context),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            IconButton(
              tooltip: l10n.settings,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'home-log-fab',
          onPressed: () => showQuickLogSheet(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.log),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (totals.planExceedsIncome)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: SyncColors.warning,
                  ),
                  label: Text(l10n.planExceedsIncome),
                  backgroundColor: SyncColors.warning.withValues(alpha: 0.15),
                ),
              ),
            const SizedBox(height: 8),
            _HeroRemaining(
              label: cashLeft < 0 ? l10n.overspent : l10n.remaining,
              amount: cashLeft.abs(),
              negative: cashLeft < 0,
              progress: progress,
              overPlan: totals.actual > totals.planned && totals.planned > 0,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: l10n.income,
                    amount: totals.income,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: l10n.plannedLabel,
                    amount: totals.planned,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: l10n.spentLabel,
                    amount: totals.actual,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (state.categories.isEmpty)
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
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoriesScreen(),
                            ),
                          );
                        },
                        child: Text(l10n.addCategory),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...state.categories.map(
                (cat) => _CategoryTreeCard(category: cat),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTreeCard extends StatelessWidget {
  const _CategoryTreeCard({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final cat = category;
    final planned = state.categoryPlanned(cat.id);
    final actual = state.categoryActual(cat.id);
    final ratio = planned <= 0
        ? (actual > 0 ? 1.0 : 0.0)
        : (actual / planned).clamp(0.0, 1.0);
    final subs = state.subcategoriesFor(cat.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.localizedName(state.localeCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatIls(actual),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor:
                        Color(cat.colorValue).withValues(alpha: 0.18),
                    color: Color(cat.colorValue),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatIls(actual)} / ${formatIls(planned)}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: SyncColors.textMuted),
                ),
              ],
            ),
            children: [
              if (subs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Text(
                    l10n.noSubcategories,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: SyncColors.textMuted),
                  ),
                )
              else
                ...subs.map((sub) => _SubcategoryTile(subcategory: sub)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => cat.isSavings
                      ? showAddPotFlow(context)
                      : showAddSubcategorySheet(
                          context,
                          categoryId: cat.id,
                        ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    cat.isSavings ? l10n.addPot : l10n.addSubcategory,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  const _SubcategoryTile({required this.subcategory});

  final Subcategory subcategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final sub = subcategory;
    final planned = state.plannedFor(sub.id);
    final spent = state.spentFor(sub.id);
    final hint = state.installmentHint(sub);
    final expenses = state.expensesFor(sub.id);
    final isSavings = state.categoryById(sub.categoryId)?.isSavings ?? false;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
        childrenPadding: const EdgeInsets.only(left: 12, right: 4, bottom: 8),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.localizedName(state.localeCode),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
            InkWell(
              onTap: () => showPlanEditor(context, subcategory: sub),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  '${formatIls(spent)} / ${formatIls(planned)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: spent > planned && planned > 0
                            ? SyncColors.accent
                            : SyncColors.text,
                      ),
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: l10n.editPlan,
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: () => showPlanEditor(context, subcategory: sub),
        ),
        children: [
          if (expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                l10n.noData,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: SyncColors.textMuted),
              ),
            )
          else
            ...expenses.map((expense) {
              final note = expense.note?.trim();
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 8, right: 4),
                title: Text(
                  note == null || note.isEmpty
                      ? DateFormat.MMMd().format(expense.date)
                      : note,
                ),
                subtitle: note == null || note.isEmpty
                    ? null
                    : Text(DateFormat.MMMd().format(expense.date)),
                trailing: Text(
                  formatIls(expense.amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => isSavings
                    ? showDepositEditor(
                        context,
                        subcategory: sub,
                        expense: expense,
                      )
                    : showExpenseEditor(
                        context,
                        expense: expense,
                        subcategoryId: sub.id,
                      ),
              );
            }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => isSavings
                  ? showDepositEditor(context, subcategory: sub)
                  : showExpenseEditor(
                      context,
                      subcategoryId: sub.id,
                    ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(isSavings ? l10n.logDeposit : l10n.addExpense),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRemaining extends StatelessWidget {
  const _HeroRemaining({
    required this.label,
    required this.amount,
    required this.negative,
    required this.progress,
    required this.overPlan,
  });

  final String label;
  final double amount;
  final bool negative;
  final double progress;
  final bool overPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SyncColors.text.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            formatIls(amount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: negative ? SyncColors.accent : SyncColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: SyncColors.surfaceMint,
                  color: overPlan ? SyncColors.accent : SyncColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatIls(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
