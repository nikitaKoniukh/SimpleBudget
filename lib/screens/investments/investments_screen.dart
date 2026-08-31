import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/sync_app_bar.dart';
import 'investments_sheets.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  var _ensuredLeftover = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ensuredLeftover) return;
    final state = context.read<AppState>();
    if (!state.hasMonthSelected) return;
    _ensuredLeftover = true;
    unawaited(state.ensureLeftoverPot());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.tab(title: l10n.savingsHighlight),
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

    final pots = state.savingsPots;
    final leftoverPot = pots
        .where((p) => DefaultPots.isLeftoverName(p.nameEn))
        .firstOrNull;
    final otherPots =
        pots.where((p) => !DefaultPots.isLeftoverName(p.nameEn)).toList();
    final summable =
        otherPots.where((p) => p.includeInTotal).toList(growable: false);
    final excluded =
        otherPots.where((p) => !p.includeInTotal).toList(growable: false);
    final totalSaved = summable.fold<double>(
      0,
      (s, p) => s + state.potBalanceAmount(p.id),
    );
    final targeted = summable.where(
      (p) => p.targetAmount != null && p.targetAmount! > 0,
    );
    final totalTarget = targeted.fold<double>(0, (s, p) => s + p.targetAmount!);
    final hasAnyTarget = totalTarget > 0;
    final overallProgress = !hasAnyTarget
        ? 0.0
        : (totalSaved / totalTarget).clamp(0.0, 1.0);
    final monthSaved =
        otherPots.fold<double>(0, (s, p) => s + state.depositedFor(p.id));
    final monthPlan =
        otherPots.fold<double>(0, (s, p) => s + state.plannedFor(p.id));

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.tab(title: l10n.savingsHighlight),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'investments-fab',
          onPressed: () => showSetAsideActionsSheet(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.log),
        ),
        body: RefreshIndicator(
          onRefresh: () => context.read<AppState>().refreshBudget(),
          child: pots.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(28),
                  children: [
                    const SizedBox(height: 48),
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
                    Center(
                      child: FilledButton(
                        onPressed: () => showAddPotFlow(context),
                        child: Text(l10n.addPot),
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    _SetAsideHero(
                      label: l10n.savedLabel,
                      saved: totalSaved,
                      target: hasAnyTarget ? totalTarget : null,
                      progress: overallProgress,
                      monthSaved: monthSaved,
                      monthPlan: monthPlan,
                      inTotalCount: summable.length,
                      notInTotalCount: excluded.length,
                    ),
                    if (leftoverPot != null) ...[
                      const SizedBox(height: 12),
                      _PotCard(subcategory: leftoverPot),
                    ],
                    if (summable.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: l10n.sectionInTotal,
                        subtitle: l10n.sectionInTotalHint,
                      ),
                      const SizedBox(height: 8),
                      ...summable.map((pot) => _PotCard(subcategory: pot)),
                    ],
                    if (excluded.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionHeader(
                        title: l10n.sectionNotInTotal,
                        subtitle: l10n.sectionNotInTotalHint,
                      ),
                      const SizedBox(height: 8),
                      ...excluded.map((pot) => _PotCard(subcategory: pot)),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
        ],
      ],
    );
  }
}

class _SetAsideHero extends StatelessWidget {
  const _SetAsideHero({
    required this.label,
    required this.saved,
    required this.target,
    required this.progress,
    required this.monthSaved,
    required this.monthPlan,
    required this.inTotalCount,
    required this.notInTotalCount,
  });

  final String label;
  final double saved;
  final double? target;
  final double progress;
  final double monthSaved;
  final double monthPlan;
  final int inTotalCount;
  final int notInTotalCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metaStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: SyncColors.textMuted,
        );
    final showMonth = monthSaved > 0 || monthPlan > 0;
    final remaining =
        target != null ? (target! - saved).clamp(0.0, double.infinity) : null;

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
              '${formatIls(saved)} / ${formatIls(target!)}'
              ' · ${(progress * 100).round()}%',
              style: metaStyle,
            ),
            if (remaining != null && remaining > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${l10n.remaining}: ${formatIls(remaining)}',
                style: metaStyle,
              ),
            ],
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
          if (showMonth) ...[
            const SizedBox(height: 12),
            Text(
              monthPlan > 0
                  ? '${l10n.thisMonthDeposits}: '
                      '${formatIls(monthSaved)} / ${formatIls(monthPlan)}'
                  : '${l10n.thisMonthDeposits}: ${formatIls(monthSaved)}',
              style: metaStyle,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            notInTotalCount > 0
                ? '${l10n.potsTowardSaved(inTotalCount)} · '
                    '${l10n.potsTrackedSeparately(notInTotalCount)}'
                : l10n.potsTowardSaved(inTotalCount),
            style: metaStyle,
          ),
        ],
      ),
    );
  }
}

class _PotCard extends StatelessWidget {
  const _PotCard({required this.subcategory});

  final Subcategory subcategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final pot = state.subcategoryById(subcategory.id) ?? subcategory;
    final colorValue = state.categoryById(pot.categoryId)?.colorValue ??
        DefaultCategories.savingsColorValue;
    final isLeftover = DefaultPots.isLeftoverName(pot.nameEn);
    final balance = state.potBalanceAmount(pot.id);
    final leftoverAmount =
        isLeftover ? state.leftoverFromPreviousMonth : balance;
    final leftoverSourceId = isLeftover ? state.leftoverSourceMonthId : null;
    final hasTarget =
        !isLeftover && pot.targetAmount != null && pot.targetAmount! > 0;
    final ratio = !hasTarget
        ? (balance > 0 ? 1.0 : 0.0)
        : (balance / pot.targetAmount!).clamp(0.0, 1.0);
    final monthSaved = state.depositedFor(pot.id);
    final monthPlan = state.plannedFor(pot.id);
    final showMonth = !isLeftover && (monthSaved > 0 || monthPlan > 0);
    final metaStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: SyncColors.textMuted,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLeftover
              ? null
              : () => showPotDetailSheet(context, subcategory: pot),
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
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pot.localizedName(state.localeCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatIls(isLeftover ? leftoverAmount : balance),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (isLeftover) ...[
                  const SizedBox(height: 6),
                  Text(
                    leftoverSourceId == null
                        ? l10n.leftoverNoPreviousMonth
                        : l10n.leftoverThroughPeriod(
                            l10n.monthTitle(dateFromMonthId(leftoverSourceId)),
                          ),
                    style: metaStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.leftoverPotHint, style: metaStyle),
                ],
                if (hasTarget) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor:
                          Color(colorValue).withValues(alpha: 0.18),
                      color: Color(colorValue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatIls(balance)} / ${formatIls(pot.targetAmount!)}'
                    ' · ${(ratio * 100).round()}%',
                    style: metaStyle,
                  ),
                ],
                if (showMonth) ...[
                  const SizedBox(height: 4),
                  Text(
                    monthPlan > 0
                        ? '${l10n.thisMonthDeposits}: '
                            '${formatIls(monthSaved)} / ${formatIls(monthPlan)}'
                        : '${l10n.thisMonthDeposits}: ${formatIls(monthSaved)}',
                    style: metaStyle,
                  ),
                ],
                if (!isLeftover && pot.targetDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.targetDate}: '
                    '${DateFormat.yMMMd().format(pot.targetDate!)}',
                    style: metaStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
