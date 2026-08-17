import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/money.dart';
import '../../widgets/summary_card.dart';
import '../category/category_detail_screen.dart';

class MonthHubScreen extends StatelessWidget {
  const MonthHubScreen({super.key});

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'savings':
        return l10n.typeSavings;
      case 'debt':
        return l10n.typeDebt;
      default:
        return l10n.typeExpense;
    }
  }

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
            onPressed: () async {
              await state.setMonth(previousMonthId(state.monthId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.monthTitle(
                    dateFromMonthId(state.monthId),
                  )),
                  duration: const Duration(milliseconds: 900),
                ),
              );
            },
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed: () async {
              await state.setMonth(nextMonthId(state.monthId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.monthTitle(
                    dateFromMonthId(state.monthId),
                  )),
                  duration: const Duration(milliseconds: 900),
                ),
              );
            },
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
          if (state.categories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.emptyCategories,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.categories.map((cat) {
              final planned = state.categoryPlanned(cat.id);
              final actual = state.categoryActual(cat.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: Color(cat.colorValue).withValues(alpha: 0.35),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.localizedName(state.localeCode),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _CategoryTypeChip(
                        label: _typeLabel(l10n, cat.type),
                        type: cat.type,
                      ),
                    ],
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
                        builder: (_) =>
                            CategoryDetailScreen(categoryId: cat.id),
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

class _CategoryTypeChip extends StatelessWidget {
  const _CategoryTypeChip({required this.label, required this.type});

  final String label;
  final String type;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    switch (type) {
      case 'savings':
        bg = const Color(0xFFFFB74D);
      case 'debt':
        bg = const Color(0xFFE57373);
      default:
        bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
