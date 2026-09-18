import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

/// Expense mix for the selected month (savings pots excluded).
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

    final segments = <_ChartSegment>[];
    for (final cat in state.categories) {
      if (cat.isSavings) continue;
      final spent = state.categoryActual(cat.id);
      if (spent <= 0) continue;
      segments.add(
        _ChartSegment(
          categoryId: cat.id,
          label: cat.localizedName(state.localeCode),
          value: spent,
          color: Color(cat.colorValue),
        ),
      );
    }

    if (segments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: SyncColors.frostedSurface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: Center(
              child: Text(
                l10n.noData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    segments.sort((a, b) => b.value.compareTo(a.value));
    final total = segments.fold<double>(0, (s, e) => s + e.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SyncColors.frostedSurface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.spendingByCategory,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                formatIls(total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SyncColors.accent,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 168,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    startDegreeOffset: -90,
                    sections: segments.map((seg) {
                      final pct = seg.value / total;
                      return PieChartSectionData(
                        value: seg.value,
                        color: seg.color,
                        radius: 48,
                        title: pct >= 0.08
                            ? '${(pct * 100).round()}%'
                            : '',
                        titleStyle:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      );
                    }).toList(),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) return;
                        final idx =
                            response?.touchedSection?.touchedSectionIndex;
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
              const SizedBox(height: 10),
              for (final seg in segments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: onCategoryTap == null
                        ? null
                        : () => onCategoryTap!(seg.categoryId),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: seg.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            seg.label,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          formatIls(seg.value),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${((seg.value / total) * 100).round()}%',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: SyncColors.textMuted,
                                  ),
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
