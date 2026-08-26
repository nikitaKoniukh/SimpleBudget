import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/money.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/summary_card.dart';
import '../home/log_entry_sheet.dart';
import '../category/category_sheets.dart';
import 'month_actions.dart';

class MonthHubScreen extends StatelessWidget {
  const MonthHubScreen({super.key});

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'savings':
        return l10n.typeSavings;
      case 'debt':
        return l10n.typeDebt;
      case 'monthly':
        return l10n.typeMonthly;
      default:
        return l10n.typeSpend;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.month),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.addMonth,
              onPressed: () => showCreateMonthDialog(context),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(l10n.emptyMonths, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => showCreateMonthDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addMonth),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final monthId = state.monthId!;
    final monthDate = dateFromMonthId(monthId);
    final totals = state.totals;

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
            tooltip: l10n.selectMonth,
            onPressed: () => showSelectMonthSheet(context),
            icon: const Icon(Icons.list),
          ),
          IconButton(
            tooltip: l10n.addMonth,
            onPressed: () => showCreateMonthDialog(context),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: l10n.addCategory,
            onPressed: () => showAddCategoryFlow(context),
            icon: const Icon(Icons.category_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.categories.isEmpty
            ? () => showAddCategoryFlow(context)
            : () => showExpenseEditor(context),
        icon: Icon(state.categories.isEmpty ? Icons.category : Icons.add),
        label: Text(
          state.categories.isEmpty ? l10n.addCategory : l10n.addExpense,
        ),
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
                    const SizedBox(height: 12),
                    FilledButton(
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
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => showAddCategoryFlow(context),
                      child: Text(l10n.addCategory),
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
                  leading: CategoryColorIcon(
                    colorValue: cat.colorValue,
                    iconKey: cat.iconKey,
                    size: 36,
                  ),
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
                  onTap: () => showCategoryRegisterSheet(
                    context,
                    category: cat,
                  ),
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
      case 'monthly':
        bg = const Color(0xFF81C784);
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
