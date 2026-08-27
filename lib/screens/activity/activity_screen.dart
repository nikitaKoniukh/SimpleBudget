import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../home/log_entry_sheet.dart';
import '../home/quick_log_sheet.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _query = '';
  String? _categoryId;

  bool _matchesQuery(String haystack) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return haystack.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.activity)),
          body: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshBudget(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.4,
                  child: Center(child: Text(l10n.noMonthSelected)),
                ),
              ],
            ),
          ),
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

    final filteredEntries = entries.where((e) {
      final source = sourcesById[e.sourceId];
      final title = source?.localizedName(state.localeCode) ?? l10n.income;
      final who = e.createdByName ?? state.memberLabel(e.createdBy);
      return _matchesQuery('$title ${e.note ?? ''} $who');
    }).toList();

    final filteredExpenses = expenses.where((expense) {
      if (_categoryId != null) {
        final sub = state.subcategoryById(expense.subcategoryId);
        if (sub == null || sub.categoryId != _categoryId) return false;
      }
      final sub = state.subcategoryById(expense.subcategoryId);
      final cat = sub == null ? null : state.categoryById(sub.categoryId);
      final who = expense.createdByName ?? state.memberLabel(expense.createdBy);
      final hay =
          '${expense.note ?? ''} ${sub != null ? state.localizedSubcategoryName(sub) : ''} ${cat?.localizedName(state.localeCode) ?? ''} $who';
      return _matchesQuery(hay);
    }).toList();

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
        body: RefreshIndicator(
          onRefresh: () => context.read<AppState>().refreshBudget(),
          child: empty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(28),
                  children: [
                    const SizedBox(height: 48),
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
                    Center(
                      child: FilledButton(
                        onPressed: () => showAddIncomeEntryFlow(context),
                        child: Text(l10n.addFirstIncome),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton(
                        onPressed: () =>
                            showLogEntrySheet(context, kind: LogKind.spend),
                        child: Text(l10n.addFirstExpense),
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.searchActivity,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text(l10n.filterAll),
                            selected: _categoryId == null,
                            onSelected: (_) =>
                                setState(() => _categoryId = null),
                          ),
                          const SizedBox(width: 8),
                          ...state.categories.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(c.localizedName(state.localeCode)),
                                selected: _categoryId == c.id,
                                onSelected: (_) => setState(
                                  () => _categoryId =
                                      _categoryId == c.id ? null : c.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.incomeEntries,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (filteredEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          l10n.noData,
                          style: TextStyle(color: SyncColors.textMuted),
                        ),
                      )
                    else
                      ...filteredEntries.map((e) {
                        final source = sourcesById[e.sourceId];
                        final title =
                            source?.localizedName(state.localeCode) ??
                                l10n.income;
                        final who =
                            e.createdByName ?? state.memberLabel(e.createdBy);
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
                            subtitle: Text(
                              [
                                if (e.note != null) e.note!,
                                if (who.isNotEmpty) '${l10n.loggedBy} $who',
                              ].join(' · '),
                            ),
                            trailing: Text(
                              formatIls(e.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onTap: () => showLogEntrySheet(
                              context,
                              kind: LogKind.income,
                              incomeEntry: e,
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
                    if (filteredExpenses.isEmpty)
                      Text(
                        l10n.noData,
                        style: TextStyle(color: SyncColors.textMuted),
                      )
                    else
                      ...filteredExpenses.map((expense) {
                        final sub =
                            state.subcategoryById(expense.subcategoryId);
                        final cat = sub == null
                            ? null
                            : state.categoryById(sub.categoryId);
                        final isDeposit = state.isDepositExpense(expense);
                        final title = expense.note?.trim().isNotEmpty == true
                            ? expense.note!
                            : (sub != null
                                ? state.localizedSubcategoryName(sub)
                                : l10n.expense);
                        final who = expense.createdByName ??
                            state.memberLabel(expense.createdBy);
                        final subtitleParts = <String>[
                          if (isDeposit) l10n.deposit,
                          if (cat != null) cat.localizedName(state.localeCode),
                          if (sub != null &&
                              expense.note?.trim().isNotEmpty == true)
                            state.localizedSubcategoryName(sub),
                          DateFormat.MMMd().format(expense.date),
                          if (who.isNotEmpty) '${l10n.loggedBy} $who',
                        ];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: cat != null
                                ? CategoryColorIcon(
                                    colorValue: cat.colorValue,
                                    iconKey: cat.iconKey,
                                    size: 40,
                                  )
                                : CircleAvatar(
                                    backgroundColor: Color(
                                      0xFF90A4AE,
                                    ).withValues(alpha: 0.35),
                                    child: Icon(
                                      isDeposit
                                          ? Icons.savings_outlined
                                          : Icons.arrow_upward_rounded,
                                      color: SyncColors.accent,
                                    ),
                                  ),
                            title: Text(title),
                            subtitle: Text(subtitleParts.join(' · ')),
                            trailing: Text(
                              formatIls(expense.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onTap: () => showLogEntrySheet(
                              context,
                              kind: isDeposit
                                  ? LogKind.save
                                  : (cat?.isDebt ?? false)
                                      ? LogKind.debt
                                      : LogKind.spend,
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
      ),
    );
  }
}
