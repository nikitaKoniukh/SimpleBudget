import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../utils/share_helpers.dart';
import '../../widgets/summary_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.overview)),
        body: Center(child: Text(l10n.noMonthSelected)),
      );
    }

    final overspent = state.subcategories
        .where((s) {
          final cat = state.categoryById(s.categoryId);
          if (cat == null || cat.isSavings) return false;
          return state.spentFor(s.id) > state.plannedFor(s.id) &&
              state.plannedFor(s.id) > 0;
        })
        .toList();
    final underspent = state.subcategories
        .where((s) {
          final cat = state.categoryById(s.categoryId);
          if (cat == null || cat.isSavings) return false;
          final planned = state.plannedFor(s.id);
          final spent = state.spentFor(s.id);
          return planned > spent && planned > 0;
        })
        .toList();
    final savingsCats =
        state.categories.where((c) => c.type == 'savings').toList();
    final savingsTotal = savingsCats.fold<double>(
      0,
      (s, c) => s + state.categoryActual(c.id),
    );
    final savingsPlanned = savingsCats.fold<double>(
      0,
      (s, c) => s + state.categoryPlanned(c.id),
    );
    final totals = state.totals;
    final progress = totals.planned <= 0
        ? 0.0
        : (totals.actual / totals.planned).clamp(0.0, 1.5);

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.overview)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${l10n.actual} / ${l10n.budget}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            color: progress > 1
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '${formatIls(totals.actual)} / ${formatIls(totals.planned)}',
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.35),
            child: ListTile(
              title: Text(l10n.savingsHighlight),
              subtitle: Text(
                '${formatIls(savingsTotal)} / ${formatIls(savingsPlanned)}',
              ),
              leading: const Icon(Icons.savings_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.categories,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...state.categories.where((c) => !c.isSavings).map(
                (c) => ListTile(
                  title: Text(c.localizedName(state.localeCode)),
                  subtitle: Text(
                    '${formatIls(state.categoryActual(c.id))} / ${formatIls(state.categoryPlanned(c.id))}',
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Text(
            l10n.overspent,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (overspent.isEmpty)
            ListTile(title: Text(l10n.noData))
          else
            ...overspent.map(
              (s) => ListTile(
                title: Text(s.localizedName(state.localeCode)),
                trailing: DifferenceText(
                  value: state.plannedFor(s.id) - state.spentFor(s.id),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            l10n.underspent,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (underspent.isEmpty)
            ListTile(title: Text(l10n.noData))
          else
            ...underspent.take(12).map(
                  (s) => ListTile(
                    title: Text(s.localizedName(state.localeCode)),
                    trailing: DifferenceText(
                      value: state.plannedFor(s.id) - state.spentFor(s.id),
                    ),
                  ),
                ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              try {
                final next = await state.duplicateCurrentMonth();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.monthCreated}: $next')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.errorGeneric}: $e')),
                );
              }
            },
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(l10n.duplicateMonth),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => exportAndShareMonthCsv(context),
            icon: const Icon(Icons.table_view_outlined),
            label: Text(l10n.exportCsv),
          ),
        ],
      ),
      ),
    );
  }
}
