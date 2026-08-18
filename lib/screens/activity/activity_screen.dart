import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../category/budget_sheets.dart';
import '../home/quick_log_sheet.dart';
import '../income/income_dialogs.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.activity)),
          body: Center(child: Text(l10n.noMonthSelected)),
        ),
      );
    }

    final sourcesById = {
      for (final s in state.incomeSources) s.id: s,
    };
    final entries = List.of(state.incomeEntries)
      ..sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
    final expenses = List.of(state.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    final empty = entries.isEmpty && expenses.isEmpty;

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.activity)),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'activity-log-fab',
          onPressed: () => showQuickLogSheet(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.log),
        ),
        body: empty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 56,
                        color: SyncColors.primary.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.addFirstIncome,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.emptyIncome,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => showAddIncomeEntryFlow(context),
                        child: Text(l10n.addFirstIncome),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  Text(
                    l10n.incomeEntries,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        l10n.noData,
                        style: TextStyle(color: SyncColors.textMuted),
                      ),
                    )
                  else
                    ...entries.map((e) {
                      final source = sourcesById[e.sourceId];
                      final title = source?.localizedName(state.localeCode) ??
                          l10n.income;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: SyncColors.surfaceMint,
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: SyncColors.primary,
                            ),
                          ),
                          title: Text(title),
                          subtitle: e.note != null ? Text(e.note!) : null,
                          trailing: Text(
                            formatIls(e.amount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () => showIncomeEntryEditor(
                            context,
                            sources: state.incomeSources,
                            entry: e,
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text(
                    l10n.recentExpenses,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    Text(
                      l10n.noData,
                      style: TextStyle(color: SyncColors.textMuted),
                    )
                  else
                    ...expenses.map((expense) {
                      final sub = state.subcategoryById(expense.subcategoryId);
                      final cat = sub == null
                          ? null
                          : state.categoryById(sub.categoryId);
                      final title = expense.note?.trim().isNotEmpty == true
                          ? expense.note!
                          : (sub?.localizedName(state.localeCode) ??
                              l10n.expense);
                      final subtitleParts = <String>[
                        if (cat != null) cat.localizedName(state.localeCode),
                        if (sub != null && expense.note?.trim().isNotEmpty == true)
                          sub.localizedName(state.localeCode),
                        DateFormat.MMMd().format(expense.date),
                      ];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(
                              cat?.colorValue ?? 0xFF90A4AE,
                            ).withValues(alpha: 0.35),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: SyncColors.accent,
                            ),
                          ),
                          title: Text(title),
                          subtitle: Text(subtitleParts.join(' · ')),
                          trailing: Text(
                            formatIls(expense.amount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () => showExpenseEditor(
                            context,
                            expense: expense,
                            subcategoryId: expense.subcategoryId,
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.totalIncome}: ${formatIls(state.totals.income)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
