import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../screens/investments/investments_sheets.dart';
import '../../theme/sync_theme.dart';
import 'subcategory_budget_row.dart';

/// Savings on Home: same section header pattern as Spend / Monthly.
class SavingsBudgetSection extends StatelessWidget {
  const SavingsBudgetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final canEdit = state.canEditPlan;
    final savingsCat = state.savingsCategory;
    final pots = savingsCat == null
        ? const <Subcategory>[]
        : state
            .subcategoriesForMonth(savingsCat.id)
            .where((p) => !DefaultPots.isLeftoverName(p.nameEn))
            .toList(growable: false);
    if (pots.isEmpty && !canEdit) return const SizedBox.shrink();

    final hairline = SyncColors.textMuted.withValues(alpha: 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sectionSavings,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SyncColors.textMuted,
                      ),
                ),
              ),
              if (canEdit)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: SyncColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => showEditPotSheet(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(l10n.addPot),
                ),
            ],
          ),
        ),
        if (pots.isEmpty)
          Material(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.emptyPots,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < pots.length; i++) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: hairline),
                    SubcategoryBudgetRow(subcategory: pots[i]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
