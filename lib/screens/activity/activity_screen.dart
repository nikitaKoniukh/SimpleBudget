import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/sync_app_bar.dart';
import '../home/log_entry_sheet.dart';
import '../home/quick_log_sheet.dart';

enum _ActivityFilter { all, income, expense }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _query = '';
  String? _categoryId;
  _ActivityFilter _filter = _ActivityFilter.all;

  bool _matchesQuery(String haystack) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return haystack.toLowerCase().contains(q);
  }

  List<_FeedItem> _buildFeed({
    required AppState state,
    required AppLocalizations l10n,
  }) {
    final sourcesById = {
      for (final s in state.incomeSources) s.id: s,
    };

    final items = <_FeedItem>[];

    for (final entry in state.incomeEntries) {
      final source = sourcesById[entry.sourceId];
      final title =
          source?.localizedName(state.localeCode) ?? l10n.income;
      final who = entry.createdByName ?? state.memberLabel(entry.createdBy);
      final haystack = '$title ${entry.note ?? ''} $who';
      if (!_matchesQuery(haystack)) continue;
      if (_filter == _ActivityFilter.expense) continue;

      items.add(
        _FeedItem(
          sortDate: entry.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          incomeEntry: entry,
        ),
      );
    }

    for (final expense in state.expenses) {
      if (_categoryId != null) {
        final sub = state.subcategoryById(expense.subcategoryId);
        if (sub == null || sub.categoryId != _categoryId) continue;
      }
      if (_filter == _ActivityFilter.income) continue;

      final sub = state.subcategoryById(expense.subcategoryId);
      final cat =
          sub == null ? null : state.categoryById(sub.categoryId);
      final who =
          expense.createdByName ?? state.memberLabel(expense.createdBy);
      final haystack =
          '${expense.note ?? ''} ${sub != null ? state.localizedSubcategoryName(sub) : ''} ${cat?.localizedName(state.localeCode) ?? ''} $who';
      if (!_matchesQuery(haystack)) continue;

      items.add(
        _FeedItem(
          sortDate: expense.date,
          expense: expense,
        ),
      );
    }

    items.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return items;
  }

  Map<DateTime, List<_FeedItem>> _groupByDay(List<_FeedItem> items) {
    final grouped = <DateTime, List<_FeedItem>>{};
    for (final item in items) {
      final day = DateTime(
        item.sortDate.year,
        item.sortDate.month,
        item.sortDate.day,
      );
      grouped.putIfAbsent(day, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.tab(title: l10n.activity),
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

    final hasAnyActivity =
        state.incomeEntries.isNotEmpty || state.expenses.isNotEmpty;
    final feed = _buildFeed(state: state, l10n: l10n);
    final grouped = _groupByDay(feed);
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.tab(title: l10n.activity),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'activity-log-fab',
          onPressed: () => showQuickLogSheet(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.log),
        ),
        body: RefreshIndicator(
          onRefresh: () => context.read<AppState>().refreshBudget(),
          child: !hasAnyActivity
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
                    _ActivitySummaryBar(totals: state.totals),
                    const SizedBox(height: 12),
                    Material(
                      color: SyncColors.frostedSurface,
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.searchActivity,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_ActivityFilter>(
                      segments: [
                        ButtonSegment(
                          value: _ActivityFilter.all,
                          label: Text(l10n.filterAll),
                        ),
                        ButtonSegment(
                          value: _ActivityFilter.income,
                          label: Text(l10n.income),
                        ),
                        ButtonSegment(
                          value: _ActivityFilter.expense,
                          label: Text(l10n.expense),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (selection) => setState(
                        () => _filter = selection.first,
                      ),
                    ),
                    if (_filter != _ActivityFilter.income &&
                        state.categories.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                                  avatar: CategoryColorIcon(
                                    colorValue: c.colorValue,
                                    iconKey: c.iconKey,
                                    size: 24,
                                  ),
                                  label: Text(
                                    c.localizedName(state.localeCode),
                                  ),
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
                    ],
                    const SizedBox(height: 16),
                    if (feed.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.filter_list_off_outlined,
                              size: 40,
                              color: SyncColors.textMuted.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noData,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: SyncColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final day in sortedDays) ...[
                        _DayHeader(date: day),
                        const SizedBox(height: 8),
                        for (final item in grouped[day]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ActivityFeedTile(
                              item: item,
                              state: state,
                              l10n: l10n,
                            ),
                          ),
                      ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _FeedItem {
  const _FeedItem({
    required this.sortDate,
    this.incomeEntry,
    this.expense,
  }) : assert(
          (incomeEntry != null) ^ (expense != null),
          'Feed item must be income or expense',
        );

  final DateTime sortDate;
  final IncomeEntry? incomeEntry;
  final Expense? expense;

  bool get isIncome => incomeEntry != null;
}

class _ActivitySummaryBar extends StatelessWidget {
  const _ActivitySummaryBar({required this.totals});

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: SyncColors.frostedSurface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCell(
                label: l10n.income,
                amount: totals.income,
                color: SyncColors.primary,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: SyncColors.textMuted.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _SummaryCell(
                label: l10n.spentLabel,
                amount: totals.actual,
                color: totals.actual > totals.planned && totals.planned > 0
                    ? SyncColors.overspend
                    : SyncColors.accent,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.amount,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final double amount;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SyncColors.textMuted,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          formatIls(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = date.year == now.year
        ? DateFormat.MMMd().format(date)
        : DateFormat.yMMMd().format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: SyncColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ActivityFeedTile extends StatelessWidget {
  const _ActivityFeedTile({
    required this.item,
    required this.state,
    required this.l10n,
  });

  final _FeedItem item;
  final AppState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (item.isIncome) {
      return _IncomeTile(
        entry: item.incomeEntry!,
        state: state,
        l10n: l10n,
      );
    }
    return _ExpenseTile(
      expense: item.expense!,
      state: state,
      l10n: l10n,
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({
    required this.entry,
    required this.state,
    required this.l10n,
  });

  final IncomeEntry entry;
  final AppState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final sourcesById = {
      for (final s in state.incomeSources) s.id: s,
    };
    final source = sourcesById[entry.sourceId];
    final title = source?.localizedName(state.localeCode) ?? l10n.income;
    final who = entry.createdByName ?? state.memberLabel(entry.createdBy);
    final subtitleParts = <String>[
      l10n.income,
      if (entry.note != null && entry.note!.trim().isNotEmpty) entry.note!,
      if (who.isNotEmpty) '${l10n.loggedBy} $who',
    ];

    return Material(
      color: SyncColors.frostedSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showLogEntrySheet(
          context,
          kind: LogKind.income,
          incomeEntry: entry,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: SyncColors.surfaceMint,
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: SyncColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitleParts.length > 1) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.skip(1).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${formatIls(entry.amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SyncColors.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.state,
    required this.l10n,
  });

  final Expense expense;
  final AppState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final sub = state.subcategoryById(expense.subcategoryId);
    final cat = sub == null ? null : state.categoryById(sub.categoryId);
    final isDeposit = state.isDepositExpense(expense);
    final title = expense.note?.trim().isNotEmpty == true
        ? expense.note!
        : (sub != null
            ? state.localizedSubcategoryName(sub)
            : l10n.expense);
    final who =
        expense.createdByName ?? state.memberLabel(expense.createdBy);
    final subtitleParts = <String>[
      if (isDeposit) l10n.deposit,
      if (cat != null) cat.localizedName(state.localeCode),
      if (sub != null && expense.note?.trim().isNotEmpty == true)
        state.localizedSubcategoryName(sub),
      if (who.isNotEmpty) '${l10n.loggedBy} $who',
    ];

    final amountColor = isDeposit
        ? SyncColors.primary
        : (cat?.isDebt ?? false)
            ? SyncColors.warning
            : SyncColors.accent;

    return Material(
      color: SyncColors.frostedSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (cat != null)
                CategoryColorIcon(
                  colorValue: cat.colorValue,
                  iconKey: cat.iconKey,
                  size: 40,
                )
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF90A4AE).withValues(alpha: 0.35),
                  child: Icon(
                    isDeposit
                        ? Icons.savings_outlined
                        : Icons.arrow_upward_rounded,
                    color: amountColor,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatIls(expense.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
