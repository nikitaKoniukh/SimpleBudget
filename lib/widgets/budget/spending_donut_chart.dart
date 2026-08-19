import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

class SpendingDonutChart extends StatelessWidget {
  const SpendingDonutChart({
    super.key,
    this.onCategoryTap,
  });

  final void Function(String categoryId)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final totals = state.totals;

    final segments = <_ChartSegment>[];
    for (final cat in state.categories.where((c) => !c.isSavings)) {
      final spent = state.categoryActual(cat.id);
      final planned = state.categoryPlanned(cat.id);
      final value = spent > 0 ? spent : planned;
      if (value <= 0) continue;
      segments.add(
        _ChartSegment(
          categoryId: cat.id,
          label: cat.localizedName(state.localeCode),
          value: value,
          color: Color(cat.colorValue),
        ),
      );
    }

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = segments.fold<double>(0, (s, e) => s + e.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.spendingByCategory,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 44,
                          startDegreeOffset: -90,
                          sections: segments.map((seg) {
                            final pct = seg.value / total;
                            return PieChartSectionData(
                              value: seg.value,
                              color: seg.color,
                              radius: 52,
                              title: pct >= 0.08
                                  ? '${(pct * 100).round()}%'
                                  : '',
                              titleStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            );
                          }).toList(),
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions) return;
                              final idx = response?.touchedSection?.touchedSectionIndex;
                              if (idx == null ||
                                  idx < 0 ||
                                  idx >= segments.length) {
                                return;
                              }
                              onCategoryTap?.call(segments[idx].categoryId);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cashLeft,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: SyncColors.textMuted),
                          ),
                          Text(
                            formatIls(totals.cashLeft.abs()),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: totals.cashLeft < 0
                                      ? SyncColors.accent
                                      : SyncColors.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${formatIls(totals.actual)} / ${formatIls(totals.planned)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: SyncColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (final seg in segments)
                    _LegendChip(
                      color: seg.color,
                      label: seg.label,
                      onTap: onCategoryTap == null
                          ? null
                          : () => onCategoryTap!(seg.categoryId),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartSegment {
  const _ChartSegment({
    required this.categoryId,
    required this.label,
    required this.value,
    required this.color,
  });

  final String categoryId;
  final String label;
  final double value;
  final Color color;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    this.onTap,
  });

  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: child,
      ),
    );
  }
}
