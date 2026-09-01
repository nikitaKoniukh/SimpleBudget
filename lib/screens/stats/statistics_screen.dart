import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/budget/spending_donut_chart.dart';
import '../../widgets/sync_app_bar.dart';

enum _StatsRange { vsPrev, last3, last6 }

/// Statistics: donut for selected month + multi-month category compare.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _StatsRange _range = _StatsRange.last3;
  Map<String, MonthStatsSnapshot> _snapshots = {};
  bool _loading = false;
  String? _error;
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  List<String> _monthIdsForRange(AppState state) {
    final months = state.months.map((m) => m.id).toList();
    if (months.isEmpty) return [];
    final current = state.monthId ?? months.first;
    switch (_range) {
      case _StatsRange.vsPrev:
        final ids = <String>[current];
        final prev = previousMonthId(current);
        if (months.contains(prev)) ids.add(prev);
        return ids;
      case _StatsRange.last3:
        return months.take(3).toList();
      case _StatsRange.last6:
        return months.take(6).toList();
    }
  }

  Future<void> _reload() async {
    final state = context.read<AppState>();
    if (!state.hasHousehold) return;
    await state.refreshBudget();
    if (!mounted) return;
    final ids = _monthIdsForRange(state);
    if (ids.isEmpty) {
      setState(() {
        _snapshots = {};
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await state.loadStatsForMonths(ids);
      if (!mounted) return;
      setState(() {
        _snapshots = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onRangeChanged(_StatsRange range) {
    setState(() => _range = range);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.tab(title: l10n.statistics),
          body: RefreshIndicator(
            onRefresh: _reload,
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

    final totals = state.totals;
    final compareIds = _monthIdsForRange(state);
    final envelopeCats = state.categories.toList();
    final monthLabel = l10n.monthTitle(dateFromMonthId(state.monthId!));

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.tab(title: l10n.statistics),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _MonthHeader(label: monthLabel),
              const SizedBox(height: 12),
              _StatsSummaryPanel(totals: totals, l10n: l10n),
              const SizedBox(height: 12),
              const SpendingDonutChart(),
              const SizedBox(height: 12),
              Material(
                color: SyncColors.frostedSurface,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.compareMonths,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_StatsRange>(
                        segments: [
                          ButtonSegment(
                            value: _StatsRange.vsPrev,
                            label: Text(l10n.thisVsPrev),
                          ),
                          ButtonSegment(
                            value: _StatsRange.last3,
                            label: Text(l10n.last3Months),
                          ),
                          ButtonSegment(
                            value: _StatsRange.last6,
                            label: Text(l10n.last6Months),
                          ),
                        ],
                        selected: {_range},
                        onSelectionChanged: (selection) =>
                            _onRangeChanged(selection.first),
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '${l10n.errorGeneric}: $_error',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        )
                      else if (compareIds.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.bar_chart_outlined,
                                size: 36,
                                color: SyncColors.textMuted.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.noData,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: SyncColors.textMuted),
                              ),
                            ],
                          ),
                        )
                      else
                        _CompareTable(
                          compareIds: compareIds,
                          categories: envelopeCats,
                          snapshots: _snapshots,
                          state: state,
                          l10n: l10n,
                          expandedCategoryId: _expandedCategoryId,
                          onCategoryTap: (catId) {
                            setState(() {
                              _expandedCategoryId =
                                  _expandedCategoryId == catId ? null : catId;
                            });
                          },
                        ),
                    ],
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SyncColors.frostedSurface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: SyncColors.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSummaryPanel extends StatelessWidget {
  const _StatsSummaryPanel({
    required this.totals,
    required this.l10n,
  });

  final MonthTotals totals;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final overBudget =
        totals.planned > 0 && totals.totalSpent > totals.planned;
    final progress = totals.planned > 0
        ? (totals.totalSpent / totals.planned).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: SyncColors.frostedSurface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: l10n.income,
                    amount: totals.income,
                    color: SyncColors.primary,
                  ),
                ),
                _StatDivider(),
                Expanded(
                  child: _StatCell(
                    label: l10n.spentLabel,
                    amount: totals.totalSpent,
                    color: overBudget ? SyncColors.overspend : SyncColors.accent,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: l10n.budget,
                    amount: totals.planned,
                    color: SyncColors.text,
                  ),
                ),
                _StatDivider(),
                Expanded(
                  child: _StatCell(
                    label: l10n.savingsHighlight,
                    amount: totals.savedThisMonth,
                    color: SyncColors.primary,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            if (totals.planned > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: SyncColors.surfaceMint,
                  color: overBudget ? SyncColors.overspend : SyncColors.accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.spentLabel}: ${formatIls(totals.totalSpent)} / ${formatIls(totals.planned)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: SyncColors.textMuted.withValues(alpha: 0.2),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
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

class _CompareTable extends StatelessWidget {
  const _CompareTable({
    required this.compareIds,
    required this.categories,
    required this.snapshots,
    required this.state,
    required this.l10n,
    required this.expandedCategoryId,
    required this.onCategoryTap,
  });

  final List<String> compareIds;
  final List<BudgetCategory> categories;
  final Map<String, MonthStatsSnapshot> snapshots;
  final AppState state;
  final AppLocalizations l10n;
  final String? expandedCategoryId;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final monthColumnWidth = compareIds.length <= 2 ? 96.0 : 80.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 132,
                child: Text(
                  l10n.byCategory,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SyncColors.textMuted,
                      ),
                ),
              ),
              for (final id in compareIds)
                SizedBox(
                  width: monthColumnWidth,
                  child: Text(
                    l10n.monthTitle(dateFromMonthId(id)),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 4),
        for (final cat in categories) ...[
          _CompareCategoryRow(
            category: cat,
            compareIds: compareIds,
            monthColumnWidth: monthColumnWidth,
            snapshots: snapshots,
            state: state,
            expanded: expandedCategoryId == cat.id,
            onTap: () => onCategoryTap(cat.id),
          ),
          if (expandedCategoryId == cat.id)
            ...state.subcategoriesFor(cat.id).where((sub) {
              for (final id in compareIds) {
                final snap = snapshots[id];
                if (snap == null) continue;
                if (snap.plans.any((p) => p.subcategoryId == sub.id)) {
                  return true;
                }
                if (snap.spentForSub(sub.id) > 0) return true;
              }
              return false;
            }).map(
              (sub) => _CompareSubcategoryRow(
                sub: sub,
                compareIds: compareIds,
                monthColumnWidth: monthColumnWidth,
                snapshots: snapshots,
                state: state,
              ),
            ),
        ],
      ],
    );
  }
}

class _CompareCategoryRow extends StatelessWidget {
  const _CompareCategoryRow({
    required this.category,
    required this.compareIds,
    required this.monthColumnWidth,
    required this.snapshots,
    required this.state,
    required this.expanded,
    required this.onTap,
  });

  final BudgetCategory category;
  final List<String> compareIds;
  final double monthColumnWidth;
  final Map<String, MonthStatsSnapshot> snapshots;
  final AppState state;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubcategories = state.subcategoriesFor(category.id).any((sub) {
      for (final id in compareIds) {
        final snap = snapshots[id];
        if (snap == null) continue;
        if (snap.plans.any((p) => p.subcategoryId == sub.id)) return true;
        if (snap.spentForSub(sub.id) > 0) return true;
      }
      return false;
    });

    return Material(
      color: expanded
          ? SyncColors.surfaceMint.withValues(alpha: 0.45)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: hasSubcategories ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 132,
                  child: Row(
                    children: [
                      CategoryColorIcon(
                        colorValue: category.colorValue,
                        iconKey: category.iconKey,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.localizedName(state.localeCode),
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (hasSubcategories)
                        Icon(
                          expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                          color: SyncColors.textMuted,
                        ),
                    ],
                  ),
                ),
                for (final id in compareIds)
                  SizedBox(
                    width: monthColumnWidth,
                    child: Text(
                      formatIls(
                        snapshots[id]?.spentForCategory(
                              category.id,
                              state.subcategories,
                            ) ??
                            0,
                      ),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareSubcategoryRow extends StatelessWidget {
  const _CompareSubcategoryRow({
    required this.sub,
    required this.compareIds,
    required this.monthColumnWidth,
    required this.snapshots,
    required this.state,
  });

  final Subcategory sub;
  final List<String> compareIds;
  final double monthColumnWidth;
  final Map<String, MonthStatsSnapshot> snapshots;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final labelPlan = () {
      for (final id in compareIds) {
        final snap = snapshots[id];
        if (snap == null) continue;
        for (final plan in snap.plans) {
          if (plan.subcategoryId == sub.id) return plan;
        }
      }
      return null;
    }();
    final label = labelPlan?.localizedName(state.localeCode, sub) ??
        sub.localizedName(state.localeCode);

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ),
            for (final id in compareIds)
              SizedBox(
                width: monthColumnWidth,
                child: Text(
                  formatIls(snapshots[id]?.spentForSub(sub.id) ?? 0),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SyncColors.textMuted,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
