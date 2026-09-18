import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/budget_overview_bar.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/budget/spending_donut_chart.dart';
import '../../widgets/sync_app_bar.dart';

enum _StatsRange { vsPrev, last3, last6 }

/// Statistics: Home-aligned month summary, expense mix, multi-month compare.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _StatsRange _range = _StatsRange.last3;
  Map<String, MonthStatsSnapshot> _snapshots = {};
  bool _loading = false;
  String? _error;
  String? _expandedCategoryId;
  String? _loadedRangeKey;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _reload();
    }
  }

  /// Months for the selected range, newest-first, anchored on the selected month.
  List<String> _monthIdsForRange(AppState state) {
    final months = state.months.map((m) => m.id).toList();
    if (months.isEmpty) return [];
    final current = state.monthId ?? months.first;
    final start = months.indexOf(current);
    final from = start >= 0 ? start : 0;

    switch (_range) {
      case _StatsRange.vsPrev:
        final ids = <String>[current];
        final prev = previousMonthId(current);
        if (months.contains(prev)) ids.add(prev);
        return ids;
      case _StatsRange.last3:
        return months.skip(from).take(3).toList();
      case _StatsRange.last6:
        return months.skip(from).take(6).toList();
    }
  }

  Future<void> _reload() async {
    final state = context.read<AppState>();
    if (!state.hasHousehold) return;
    if (!mounted) return;
    final ids = _monthIdsForRange(state);
    final monthId = state.monthId;
    if (ids.isEmpty) {
      setState(() {
        _snapshots = {};
        _loading = false;
        _error = null;
        _loadedRangeKey = '$monthId|${_range.name}|';
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
        _loadedRangeKey = '$monthId|${_range.name}|${ids.join(',')}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _loadedRangeKey = '$monthId|${_range.name}|${ids.join(',')}';
      });
    }
  }

  void _onRangeChanged(_StatsRange range) {
    setState(() => _range = range);
    _reload();
  }

  static String _rangeLabel(AppLocalizations l10n, _StatsRange range) =>
      _statsRangeLabel(l10n, range);

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

    final compareIds = _monthIdsForRange(state);
    final rangeKey = '${state.monthId}|${_range.name}|${compareIds.join(',')}';
    if (widget.isActive &&
        !_loading &&
        rangeKey != _loadedRangeKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _loading) return;
        final latest = context.read<AppState>();
        final ids = _monthIdsForRange(latest);
        final key =
            '${latest.monthId}|${_range.name}|${ids.join(',')}';
        if (key != _loadedRangeKey) _reload();
      });
    }

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
              BudgetOverviewBar(totals: state.totals),
              SpendingDonutChart(
                onCategoryTap: (catId) {
                  setState(() {
                    _expandedCategoryId =
                        _expandedCategoryId == catId ? null : catId;
                  });
                },
              ),
              Material(
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
                            child: Text(
                              l10n.compareMonths,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          _CompareRangeButton(
                            range: _range,
                            label: _rangeLabel(l10n, _range),
                            onChanged: _onRangeChanged,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
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
                                color: SyncColors.textMuted
                                    .withValues(alpha: 0.7),
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
                          categories: state.categories,
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

String _statsRangeLabel(AppLocalizations l10n, _StatsRange range) {
  switch (range) {
    case _StatsRange.vsPrev:
      return l10n.thisVsPrev;
    case _StatsRange.last3:
      return l10n.last3Months;
    case _StatsRange.last6:
      return l10n.last6Months;
  }
}

class _CompareRangeButton extends StatelessWidget {
  const _CompareRangeButton({
    required this.range,
    required this.label,
    required this.onChanged,
  });

  final _StatsRange range;
  final String label;
  final ValueChanged<_StatsRange> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<_StatsRange>(
      context: context,
      backgroundColor: SyncColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Text(
                    l10n.compareMonths,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                for (final option in _StatsRange.values)
                  ListTile(
                    title: Text(_statsRangeLabel(l10n, option)),
                    trailing: option == range
                        ? const Icon(
                            Icons.check_rounded,
                            color: SyncColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(ctx, option),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked != range) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SyncColors.surfaceMint.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SyncColors.primary,
                      ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: SyncColors.primary,
              ),
            ],
          ),
        ),
      ),
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

  double _activityForCat(BudgetCategory cat, String monthId) {
    return snapshots[monthId]?.activityForCategory(
          cat.id,
          state.subcategories,
          isSavings: cat.isSavings,
        ) ??
        0;
  }

  bool _catHasActivity(BudgetCategory cat) {
    for (final id in compareIds) {
      if (_activityForCat(cat, id) > 0) return true;
      final snap = snapshots[id];
      if (snap == null) continue;
      for (final sub in state.subcategoriesFor(cat.id)) {
        if (snap.plans.any((p) => p.subcategoryId == sub.id)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final activeCats = categories.where(_catHasActivity).toList();

    if (activeCats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l10n.noData,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
        ),
      );
    }

    const nameWidth = 128.0;
    final minMonthWidth = compareIds.length <= 2 ? 100.0 : 88.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTotal = nameWidth + minMonthWidth * compareIds.length;
        final totalWidth = constraints.maxWidth > minTotal
            ? constraints.maxWidth
            : minTotal;
        final monthColumnWidth =
            (totalWidth - nameWidth) / compareIds.length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: nameWidth,
                      child: Text(
                        l10n.byCategory,
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
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
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 4),
                for (final cat in activeCats) ...[
                  _CompareCategoryRow(
                    category: cat,
                    compareIds: compareIds,
                    nameWidth: nameWidth,
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
                        if (snap.activityForSub(
                              sub.id,
                              isSavings: cat.isSavings,
                            ) >
                            0) {
                          return true;
                        }
                      }
                      return false;
                    }).map(
                      (sub) => _CompareSubcategoryRow(
                        sub: sub,
                        isSavings: cat.isSavings,
                        compareIds: compareIds,
                        nameWidth: nameWidth,
                        monthColumnWidth: monthColumnWidth,
                        snapshots: snapshots,
                        state: state,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompareCategoryRow extends StatelessWidget {
  const _CompareCategoryRow({
    required this.category,
    required this.compareIds,
    required this.nameWidth,
    required this.monthColumnWidth,
    required this.snapshots,
    required this.state,
    required this.expanded,
    required this.onTap,
  });

  final BudgetCategory category;
  final List<String> compareIds;
  final double nameWidth;
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
        if (snap.activityForSub(sub.id, isSavings: category.isSavings) > 0) {
          return true;
        }
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: nameWidth,
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
                        expanded ? Icons.expand_less : Icons.expand_more,
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
                      snapshots[id]?.activityForCategory(
                            category.id,
                            state.subcategories,
                            isSavings: category.isSavings,
                          ) ??
                          0,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
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

class _CompareSubcategoryRow extends StatelessWidget {
  const _CompareSubcategoryRow({
    required this.sub,
    required this.isSavings,
    required this.compareIds,
    required this.nameWidth,
    required this.monthColumnWidth,
    required this.snapshots,
    required this.state,
  });

  final Subcategory sub;
  final bool isSavings;
  final List<String> compareIds;
  final double nameWidth;
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: nameWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ),
          ),
          for (final id in compareIds)
            SizedBox(
              width: monthColumnWidth,
              child: Text(
                formatIls(
                  snapshots[id]?.activityForSub(sub.id, isSavings: isSavings) ??
                      0,
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
