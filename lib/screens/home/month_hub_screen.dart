import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/money.dart';
import '../../widgets/summary_card.dart';
import '../category/category_detail_screen.dart';

class MonthHubScreen extends StatelessWidget {
  const MonthHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final totals = state.totals;
    final monthDate = dateFromMonthId(state.monthId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.monthTitle(monthDate)),
            if (state.household != null)
              Text(
                '${state.household!.name} · ${l10n.synced}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Previous',
            onPressed: () =>
                state.setMonth(previousMonthId(state.monthId)),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed: () => state.setMonth(nextMonthId(state.monthId)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLineItemEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (totals.planExceedsIncome)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                label: Text(l10n.planExceedsIncome),
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer,
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.55,
            children: [
              SummaryCard(label: l10n.income, amount: totals.income),
              SummaryCard(label: l10n.budget, amount: totals.planned),
              SummaryCard(label: l10n.actual, amount: totals.actual),
              SummaryCard(
                label: totals.remaining < 0 ? l10n.overspent : l10n.remaining,
                amount: totals.remaining.abs(),
                negative: totals.remaining < 0,
                emphasis: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...state.categories.map((cat) {
            final planned = state.categoryPlanned(cat.id);
            final actual = state.categoryActual(cat.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: Color(cat.colorValue).withValues(alpha: 0.35),
              child: ListTile(
                title: Text(
                  cat.localizedName(state.localeCode),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${l10n.budget}: ${formatIls(planned)} · ${l10n.actual}: ${formatIls(actual)}',
                ),
                trailing: Text(
                  formatIls(actual),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(categoryId: cat.id),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
