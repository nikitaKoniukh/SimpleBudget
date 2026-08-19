import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../screens/category/categories_screen.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import 'subcategory_budget_row.dart';

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
    final ratio = planned <= 0
        ? (actual > 0 ? 1.0 : 0.0)
        : (actual / planned).clamp(0.0, 1.0);
    final subs = state.subcategoriesFor(cat.id);
    final color = Color(cat.colorValue);

    return Padding(
      key: scrollKey,
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.localizedName(state.localeCode),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _categoryTypeLabel(l10n, cat.type),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: SyncColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatIls(actual)} / ${formatIls(planned)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: overPlan ? overColor : null,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 20),
                    tooltip: l10n.manageCategoriesLink,
                    onSelected: (value) {
                      if (value == 'manage') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'manage',
                        child: Text(l10n.manageCategoriesLink),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: overPlan
                      ? overColor.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.18),
                  color: overPlan ? overColor : color,
                ),
              ),
              const SizedBox(height: 10),
              if (subs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l10n.noSubcategories,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: SyncColors.textMuted),
                  ),
                )
              else
                ...subs.map(
                  (sub) => SubcategoryBudgetRow(
                    subcategory: sub,
                    categoryColor: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _categoryTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'savings':
      return l10n.typeSavings;
    case 'debt':
      return l10n.typeDebt;
    default:
      return l10n.typeExpense;
  }
}
