import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import 'subcategory_budget_row.dart';

/// Flat savings block on Home: pot rows only, no parent category header row.
class SavingsBudgetSection extends StatelessWidget {
  const SavingsBudgetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final savingsCat = state.savingsCategory;
    final pots = savingsCat == null
        ? const <Subcategory>[]
        : state
            .subcategoriesForMonth(savingsCat.id)
            .where((p) => !DefaultPots.isLeftoverName(p.nameEn))
            .toList(growable: false);
    if (pots.isEmpty) return const SizedBox.shrink();

    final hairline = SyncColors.textMuted.withValues(alpha: 0.12);
    final saved =
        pots.fold<double>(0, (s, p) => s + state.spentFor(p.id));
    final planned =
        pots.fold<double>(0, (s, p) => s + state.plannedFor(p.id));

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(DefaultCategories.savingsColorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.sectionSavings,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    formatIls(saved),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatIls(planned),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: SyncColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < pots.length; i++) ...[
              Divider(height: 1, thickness: 1, color: hairline),
              SubcategoryBudgetRow(subcategory: pots[i]),
            ],
          ],
        ),
      ),
    );
  }
}
