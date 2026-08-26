import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/budget/spending_donut_chart.dart';
import '../../widgets/summary_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.statistics)),
          body: Center(child: Text(l10n.noMonthSelected)),
        ),
      );
    }

    final totals = state.totals;
    final compareIds = _monthIdsForRange(state);
    final envelopeCats = state.categories.toList();

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.statistics)),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Text(
                l10n.monthTitle(dateFromMonthId(state.monthId!)),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.7,
                children: [
                  SummaryCard(label: l10n.income, amount: totals.income),
                  SummaryCard(label: l10n.actual, amount: totals.actual),
                  SummaryCard(label: l10n.budget, amount: totals.planned),
                  SummaryCard(
                    label: l10n.savingsHighlight,
                    amount: totals.savedThisMonth,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.spendingByCategory,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              const SpendingDonutChart(),
              const SizedBox(height: 20),
              Text(
                l10n.compareMonths,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.thisVsPrev),
                    selected: _range == _StatsRange.vsPrev,
                    onSelected: (_) {
                      setState(() => _range = _StatsRange.vsPrev);
                      _reload();
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.last3Months),
                    selected: _range == _StatsRange.last3,
                    onSelected: (_) {
                      setState(() => _range = _StatsRange.last3);
                      _reload();
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.last6Months),
                    selected: _range == _StatsRange.last6,
                    onSelected: (_) {
                      setState(() => _range = _StatsRange.last6);
                      _reload();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text('${l10n.errorGeneric}: $_error')
              else if (compareIds.isEmpty)
                Text(l10n.noData)
              else ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          l10n.byCategory,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      for (final id in compareIds)
                        SizedBox(
                          width: 88,
                          child: Text(
                            id,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                for (final cat in envelopeCats) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedCategoryId =
                            _expandedCategoryId == cat.id ? null : cat.id;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CategoryColorIcon(
                            colorValue: cat.colorValue,
                            iconKey: cat.iconKey,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 104,
                            child: Text(
                              cat.localizedName(state.localeCode),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          for (final id in compareIds)
                            SizedBox(
                              width: 88,
                              child: Text(
                                formatIls(
                                  _snapshots[id]?.spentForCategory(
                                        cat.id,
                                        state.subcategories,
                                      ) ??
                                      0,
                                ),
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_expandedCategoryId == cat.id)
                    ...state.subcategoriesFor(cat.id).map((sub) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 112,
                              child: Text(
                                sub.localizedName(state.localeCode),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: SyncColors.textMuted),
                              ),
                            ),
                            for (final id in compareIds)
                              SizedBox(
                                width: 88,
                                child: Text(
                                  formatIls(
                                    _snapshots[id]?.spentForSub(sub.id) ?? 0,
                                  ),
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
