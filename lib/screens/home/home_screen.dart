import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/alerts_section.dart';
import '../../widgets/budget/budget_overview_bar.dart';
import '../../widgets/budget/category_budget_section.dart';
import '../../widgets/budget/savings_budget_section.dart';
import '../../widgets/budget/spending_donut_chart.dart';
import '../category/categories_screen.dart';
import '../settings/settings_screen.dart';
import 'create_month_flow.dart';
import 'quick_log_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _categoryKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForCategory(String categoryId) {
    return _categoryKeys.putIfAbsent(categoryId, GlobalKey.new);
  }

  void _scrollToCategory(String categoryId) {
    final key = _categoryKeys[categoryId];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  List<BudgetCategory> _homeBudgetCategories(List<BudgetCategory> all) {
    return all.where((c) => !c.isSavings).toList();
  }

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
    final cashLeft = totals.cashLeft;
    final progress = totals.planned <= 0
        ? 0.0
        : (totals.actual / totals.planned).clamp(0.0, 1.0);
    final watch = state.overspendWatchlist();
    final today = DateTime.now();
    final upcoming = state.recurringBills
        .where((b) => b.dayOfMonth >= today.day)
        .toList()
      ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));

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
          controller: _scrollController,
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
            if (totals.planExceedsIncome) const SizedBox(height: 8),
            _HeroRemaining(
              label: cashLeft < 0 ? l10n.overspent : l10n.remaining,
              amount: cashLeft.abs(),
              negative: cashLeft < 0,
              progress: progress,
              overPlan: totals.actual > totals.planned && totals.planned > 0,
            ),
            const SizedBox(height: 12),
            SpendingDonutChart(onCategoryTap: _scrollToCategory),
            BudgetOverviewBar(totals: totals),
            if (totals.savedThisMonth > 0) ...[
              Text(
                '${l10n.savingsHighlight}: ${formatIls(totals.savedThisMonth)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            AlertsSection(
              watchlist: watch,
              upcomingBills: upcoming.take(5).toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.categories,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    );
                  },
                  child: Text(l10n.manageCategoriesLink),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.categories.isEmpty && state.savingsPots.isEmpty)
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
            else ...[
              ..._homeBudgetCategories(state.categories).map(
                (cat) => CategoryBudgetSection(
                  category: cat,
                  scrollKey: _keyForCategory(cat.id),
                ),
              ),
              const SavingsBudgetSection(),
            ],
          ],
        ),
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
