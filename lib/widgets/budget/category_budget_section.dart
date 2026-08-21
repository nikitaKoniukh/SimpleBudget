import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import 'subcategory_budget_row.dart';

const _amountColWidth = 88.0;

/// Sheet-like category block: header + Name | Spent | Planned rows.
class CategoryBudgetSection extends StatelessWidget {
  const CategoryBudgetSection({
    super.key,
    required this.category,
    this.scrollKey,
  });

  final BudgetCategory category;
  final Key? scrollKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final cat = category;
    final planned = state.categoryPlanned(cat.id);
    final actual = state.categoryActual(cat.id);
    final overPlan = actual > planned && planned > 0;
    final overColor = SyncColors.overspend;
    final subs = state.subcategoriesFor(cat.id);
    final color = Color(cat.colorValue);
    final hairline = SyncColors.textMuted.withValues(alpha: 0.12);

    return Padding(
      key: scrollKey,
      padding: const EdgeInsets.only(bottom: 10),
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
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.localizedName(state.localeCode),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: _amountColWidth,
                    child: Text(
                      formatIls(actual),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: overPlan ? overColor : null,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: _amountColWidth,
                    child: Text(
                      formatIls(planned),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: SyncColors.textMuted,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (subs.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  l10n.noSubcategories,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SyncColors.textMuted,
                      ),
                ),
              )
            else
              for (var i = 0; i < subs.length; i++) ...[
                Divider(height: 1, thickness: 1, color: hairline),
                SubcategoryBudgetRow(subcategory: subs[i]),
              ],
          ],
        ),
      ),
    );
  }
}
