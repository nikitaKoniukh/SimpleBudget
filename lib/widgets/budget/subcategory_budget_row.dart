import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../screens/category/subcategory_register_sheet.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

const _amountColWidth = 88.0;

/// One plain table row: name · spent · planned. Tap opens full detail sheet.
class SubcategoryBudgetRow extends StatefulWidget {
  const SubcategoryBudgetRow({
    super.key,
    required this.subcategory,
  });

  final Subcategory subcategory;

  @override
  State<SubcategoryBudgetRow> createState() => _SubcategoryBudgetRowState();
}

class _SubcategoryBudgetRowState extends State<SubcategoryBudgetRow> {
  bool _selected = false;

  Future<void> _openDetail() async {
    setState(() => _selected = true);
    await showSubcategoryRegisterSheet(
      context,
      subcategory: widget.subcategory,
    );
    if (mounted) setState(() => _selected = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sub = widget.subcategory;
    final planned = state.plannedFor(sub.id);
    final spent = state.spentFor(sub.id);
    final hint = state.installmentHint(sub);
    final overPlan = spent > planned && planned > 0;
    final overColor = SyncColors.overspend;
    final cat = state.categoryById(sub.categoryId);
    final accent =
        cat != null ? Color(cat.colorValue) : SyncColors.primary;

    return Material(
      color: _selected
          ? accent.withValues(alpha: 0.14)
          : Colors.transparent,
      child: InkWell(
        onTap: _openDetail,
        child: Container(
          decoration: BoxDecoration(
            border: _selected
                ? Border(
                    left: BorderSide(color: accent, width: 3),
                  )
                : null,
          ),
          padding: EdgeInsets.fromLTRB(
            _selected ? 9 : 12,
            10,
            12,
            10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.localizedName(state.localeCode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                _selected ? FontWeight.w700 : FontWeight.w500,
                            color: overPlan ? overColor : null,
                          ),
                    ),
                    if (hint != null)
                      Text(
                        hint,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: _amountColWidth,
                child: Text(
                  formatIls(spent),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: _selected ? FontWeight.w700 : null,
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
      ),
    );
  }
}
