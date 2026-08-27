import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../screens/category/budget_sheets.dart';
import '../../screens/category/category_sheets.dart';
import 'category_color_icon.dart';
import 'subcategory_budget_row.dart';

const _amountColWidth = 88.0;

/// Sheet-like category block: tappable header + Name | Spent | Planned rows.
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
    final subs = state.subcategoriesForMonth(cat.id);
    final canEdit = state.canEditPlan;
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
            InkWell(
              onTap: () => showCategoryRegisterSheet(
                context,
                category: cat,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    CategoryColorIcon(
                      colorValue: cat.colorValue,
                      iconKey: cat.iconKey,
                      size: 28,
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
            ),
            if (subs.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.noSubcategories,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SyncColors.textMuted,
                          ),
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: SyncColors.textMuted,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => showAddSubcategorySheet(
                          context,
                          categoryId: cat.id,
                        ),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(l10n.addSubcategory),
                      ),
                    ],
                  ],
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
