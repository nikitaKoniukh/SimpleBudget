import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../screens/category/subcategory_register_sheet.dart';
import 'envelope_progress.dart';

/// Name · spent · planned. Tap opens detail sheet.
class SubcategoryBudgetRow extends StatelessWidget {
  const SubcategoryBudgetRow({
    super.key,
    required this.subcategory,
  });

  final Subcategory subcategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final sub = subcategory;
    final planned = state.plannedFor(sub.id);
    final cat = state.categoryById(sub.categoryId);
    final isSavings = cat?.isSavings ?? false;
    final isMonthly = cat?.isMonthly ?? false;
    final spent =
        isSavings ? state.depositedFor(sub.id) : state.spentFor(sub.id);

    String? meta;
    if (isMonthly) {
      final bill = _billForSub(state, sub.id);
      if (bill != null) {
        meta = '${l10n.billDay} ${bill.dayOfMonth}';
      }
    }

    return InkWell(
      onTap: () => showSubcategoryRegisterSheet(
        context,
        subcategory: sub,
      ),
      child: EnvelopeAmountRow(
        name: state.localizedSubcategoryName(sub),
        spent: spent,
        planned: planned,
        meta: meta,
        showProgress: false,
      ),
    );
  }

  RecurringBill? _billForSub(AppState state, String subcategoryId) {
    for (final bill in state.recurringBills) {
      if (bill.subcategoryId == subcategoryId) return bill;
    }
    return null;
  }
}
