import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import 'investments_sheets.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.savingsHighlight)),
          body: Center(child: Text(l10n.noMonthSelected)),
        ),
      );
    }

    final pots = state.savingsCategories;
    final totalSaved = pots.fold<double>(0, (s, c) => s + c.savedTotal);
    final targeted = pots.where(
      (c) => c.targetAmount != null && c.targetAmount! > 0,
    );
    final totalTarget = targeted.fold<double>(0, (s, c) => s + c.targetAmount!);
    final hasAnyTarget = totalTarget > 0;
    final overallProgress = !hasAnyTarget
        ? 0.0
        : (totalSaved / totalTarget).clamp(0.0, 1.0);

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.savingsHighlight)),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'investments-fab',
          onPressed: () => showSetAsideActionsSheet(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.log),
        ),
        body: pots.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 56,
                        color: SyncColors.primary.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.emptyPots,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => showAddPotFlow(context),
                        child: Text(l10n.addPot),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _SetAsideHero(
                    label: l10n.savedLabel,
                    saved: totalSaved,
                    target: hasAnyTarget ? totalTarget : null,
                    progress: overallProgress,
                  ),
                  const SizedBox(height: 16),
                  ...pots.map((pot) => _PotCard(category: pot)),
                ],
              ),
      ),
    );
  }
}

class _SetAsideHero extends StatelessWidget {
  const _SetAsideHero({
    required this.label,
    required this.saved,
    required this.target,
    required this.progress,
  });

  final String label;
  final double saved;
  final double? target;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SyncColors.text.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            formatIls(saved),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: SyncColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text(
              '${formatIls(saved)} / ${formatIls(target!)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: SyncColors.textMuted,
                  ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: SyncColors.surfaceMint,
                color: SyncColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PotCard extends StatelessWidget {
  const _PotCard({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final cat = category;
    final hasTarget = cat.targetAmount != null && cat.targetAmount! > 0;
    final ratio = !hasTarget
        ? (cat.savedTotal > 0 ? 1.0 : 0.0)
        : (cat.savedTotal / cat.targetAmount!).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showPotDetailSheet(context, category: cat),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.localizedName(state.localeCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatIls(cat.savedTotal),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (hasTarget) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor:
                          Color(cat.colorValue).withValues(alpha: 0.18),
                      color: Color(cat.colorValue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatIls(cat.savedTotal)} / ${formatIls(cat.targetAmount!)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: SyncColors.textMuted),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.savedLabel,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: SyncColors.textMuted),
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
