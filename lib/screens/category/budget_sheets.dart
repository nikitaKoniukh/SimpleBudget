import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';
import 'category_sheets.dart';

Future<void> showPlanEditor(
  BuildContext context, {
  required Subcategory subcategory,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (!state.canEditPlan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.viewerReadOnlyPlan)),
    );
    return;
  }
  final plan = state.planFor(subcategory.id);
  final plannedCtrl = TextEditingController(
    text: plan != null && plan.planned > 0
        ? plan.planned.toStringAsFixed(2)
        : '',
  );
  final installmentCtrl = TextEditingController(
    text: plan?.installmentCurrent != null &&
            subcategory.installmentTotal != null
        ? '${plan!.installmentCurrent}/${subcategory.installmentTotal}'
        : '',
  );
  final isDebt =
      state.categoryById(subcategory.categoryId)?.isDebt ?? false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(l10n.editPlan, style: Theme.of(ctx).textTheme.titleLarge),
            Text(subcategory.localizedName(state.localeCode)),
            TextField(
              controller: plannedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.plannedLabel),
              autofocus: true,
            ),
            if (isDebt)
              TextField(
                controller: installmentCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.installment} (1/12)',
                  hintText: l10n.installmentHint,
                  helperText: l10n.installmentHelper,
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return;
  final planned =
      double.tryParse(plannedCtrl.text.replaceAll(',', '')) ?? 0;
  int? instCur;
  int? instTot;
  final inst = installmentCtrl.text.trim();
  if (isDebt && inst.contains('/')) {
    final parts = inst.split('/');
    instCur = int.tryParse(parts[0].trim());
    instTot = int.tryParse(parts[1].trim());
  }
  await state.upsertPlan(
    subcategoryId: subcategory.id,
    planned: planned,
    installmentCurrent: isDebt ? instCur : null,
    clearInstallmentCurrent: !isDebt || inst.isEmpty,
  );
  if (isDebt && instTot != subcategory.installmentTotal) {
    await state.updateSubcategory(
      subcategory.copyWith(
        installmentTotal: instTot,
        clearInstallmentTotal: instTot == null,
      ),
    );
  }
}

Future<String?> showAddSubcategorySheet(
  BuildContext context, {
  required String categoryId,
  Subcategory? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final plan = existing != null ? state.planFor(existing.id) : null;
  final nameCtrl = TextEditingController(
    text: existing?.localizedName(state.localeCode) ?? '',
  );
  final plannedCtrl = TextEditingController(
    text: plan != null && plan.planned > 0
        ? plan.planned.toStringAsFixed(2)
        : '',
  );
  final installmentCtrl = TextEditingController(
    text: plan?.installmentCurrent != null &&
            existing?.installmentTotal != null
        ? '${plan!.installmentCurrent}/${existing!.installmentTotal}'
        : '',
  );
  final isDebt = state.categoryById(categoryId)?.isDebt ?? false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              existing == null ? l10n.addSubcategory : l10n.editSubcategory,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.subcategoryName),
              autofocus: existing == null,
            ),
            TextField(
              controller: plannedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.plannedLabel),
            ),
            if (isDebt)
              TextField(
                controller: installmentCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.installment} (1/12)',
                  hintText: l10n.installmentHint,
                  helperText: l10n.installmentHelper,
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return null;
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return null;
  final planned =
      double.tryParse(plannedCtrl.text.replaceAll(',', '')) ?? 0;
  int? instCur;
  int? instTot;
  final inst = installmentCtrl.text.trim();
  if (isDebt && inst.contains('/')) {
    final parts = inst.split('/');
    instCur = int.tryParse(parts[0].trim());
    instTot = int.tryParse(parts[1].trim());
  }
  if (existing != null) {
    await state.updateSubcategory(
      existing.copyWith(
        nameEn: name,
        nameRu: name,
        installmentTotal: isDebt ? instTot : null,
        clearInstallmentTotal: !isDebt || instTot == null,
      ),
    );
    await state.upsertPlan(
      subcategoryId: existing.id,
      planned: planned,
      installmentCurrent: isDebt ? instCur : null,
      clearInstallmentCurrent: !isDebt || inst.isEmpty,
    );
    return existing.id;
  }
  return state.addSubcategory(
    categoryId: categoryId,
    name: name,
    planned: planned,
    installmentCurrent: isDebt ? instCur : null,
    installmentTotal: isDebt ? instTot : null,
  );
}

Future<String?> addCategoryAndSubcategory(BuildContext context) async {
  final categoryId = await showAddCategoryFlow(context);
  if (categoryId == null || !context.mounted) return null;
  final state = context.read<AppState>();
  if (state.subcategoryById(categoryId) != null) return categoryId;
  final cat = state.categoryById(categoryId);
  if (cat == null) return null;
  return showAddSubcategorySheet(context, categoryId: cat.id);
}

Future<String?> pickCategoryAndAddSubcategory(BuildContext context) async {
  final state = context.read<AppState>();
  final categories =
      state.categories.where((c) => !c.isSavings).toList();
  if (categories.isEmpty) {
    return addCategoryAndSubcategory(context);
  }
  if (categories.length == 1) {
    return showAddSubcategorySheet(context, categoryId: categories.first.id);
  }

  final l10n = AppLocalizations.of(context);
  String categoryId = categories.first.id;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  l10n.addSubcategory,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.localizedName(state.localeCode)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModal(() => categoryId = value);
                  },
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.continueLabel),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return null;
  return showAddSubcategorySheet(context, categoryId: categoryId);
}
