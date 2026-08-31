import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../screens/category/subcategory_register_sheet.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

const _amountColWidth = 88.0;

/// One plain table row: name · spent · planned. Tap opens full detail sheet.
class SubcategoryBudgetRow extends StatelessWidget {
  const SubcategoryBudgetRow({
    super.key,
    required this.subcategory,
  });

  final Subcategory subcategory;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sub = subcategory;
    final planned = state.plannedFor(sub.id);
    final isSavings =
        state.categoryById(sub.categoryId)?.isSavings ?? false;
    // Savings activity is deposits; spend/monthly use expenses.
    final spent =
        isSavings ? state.depositedFor(sub.id) : state.spentFor(sub.id);
    final overPlan = spent > planned && planned > 0;
    final overColor = SyncColors.overspend;

    return InkWell(
      onTap: () => showSubcategoryRegisterSheet(
        context,
        subcategory: sub,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.localizedSubcategoryName(sub),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: overPlan ? overColor : null,
                    ),
              ),
            ),
            SizedBox(
              width: _amountColWidth,
              child: Text(
                formatIls(spent),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: overPlan ? overColor : SyncColors.text,
                    ),
              ),
            ),
            SizedBox(
              width: _amountColWidth,
              child: Text(
                formatIls(planned),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
