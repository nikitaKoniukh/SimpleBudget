import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';
import 'budget_sheets.dart';
import 'subcategory_register_sheet.dart';

const categoryColorPalette = <int>[
  0xFF81C784,
  0xFF4DB6AC,
  0xFFFFF176,
  0xFFAED581,
  0xFF80CBC4,
  0xFFFFB74D,
  0xFFCE93D8,
  0xFFE57373,
  0xFF9CCC65,
  0xFFD7CCC8,
  0xFFBA68C8,
  0xFFFFF59D,
  0xFF90CAF9,
  0xFFFFAB91,
  0xFFF48FB1,
  0xFF7986CB,
  0xFF4FC3F7,
  0xFFFF8A65,
];

String categoryTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'savings':
      return l10n.typeSavings;
    case 'debt':
      return l10n.typeDebt;
    case 'monthly':
      return l10n.typeMonthly;
    default:
      return l10n.typeSpend;
  }
}

/// Opens picker: choose from suggested list, or create a custom category.
Future<String?> showAddCategoryFlow(
  BuildContext context, {
  String? preferredType,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showCategorySourceSheet(context);
  if (choice == null || !context.mounted) return null;

  try {
    if (choice.suggested != null) {
      return context.read<AppState>().addSuggestedCategory(choice.suggested!);
    }

    if (choice.wantsCustom) {
      return showCategoryEditor(context, preferredType: preferredType);
    }
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
  }
  return null;
}

Future<CategorySourceChoice?> showCategorySourceSheet(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final existing = {
    for (final c in state.categories) c.nameEn.toLowerCase(),
  };
  final available = DefaultCategories.all
      .where((c) => !existing.contains(c.nameEn.toLowerCase()))
      .toList();

  return showModalBottomSheet<CategorySourceChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (modalContext) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: sheetMaxHeight(modalContext)),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  l10n.chooseFromList,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.noSuggestionsLeft),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: available.map((cat) {
                      return ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: Color(cat.colorValue),
                          radius: 8,
                        ),
                        label: Text(
                          '${cat.localizedName(state.localeCode)} · ${categoryTypeLabel(l10n, cat.type)}',
                        ),
                        onPressed: () => Navigator.pop(
                          modalContext,
                          CategorySourceChoice.suggested(cat),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.customCategory),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(
                    modalContext,
                    const CategorySourceChoice.custom(),
                  ),
                ),
              ],
            );
          },
          ),
        ),
      );
    },
  );
}

Future<String?> showCategoryEditor(
  BuildContext context, {
  BudgetCategory? existing,
  String? preferredType,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final nameCtrl = TextEditingController(
    text: existing?.localizedName(state.localeCode) ?? '',
  );
  final targetCtrl = TextEditingController(
    text: existing?.targetAmount != null && existing!.targetAmount! > 0
        ? existing.targetAmount!.toStringAsFixed(2)
        : '',
  );
  var type = existing?.type ?? preferredType ?? 'spend';
  var colorValue = existing?.colorValue ?? categoryColorPalette.first;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  existing == null ? l10n.customCategory : l10n.editCategory,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.categoryName),
                  autofocus: existing == null,
                ),
                Text(l10n.categoryType),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in const [
                      'spend',
                      'monthly',
                      'debt',
                      'savings',
                    ])
                      ChoiceChip(
                        label: Text(categoryTypeLabel(l10n, t)),
                        selected: type == t,
                        onSelected: (_) => setLocal(() => type = t),
                      ),
                  ],
                ),
                if (type == 'savings')
                  TextField(
                    controller: targetCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.targetOptional),
                  ),
                if (existing != null || type != 'savings') ...[
                  Text(l10n.categoryColor),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryColorPalette.map((c) {
                      final selected = c == colorValue;
                      return GestureDetector(
                        onTap: () => setLocal(() => colorValue = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(width: 3, color: Colors.black87)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return null;
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return null;
  final parsedTarget = double.tryParse(targetCtrl.text.replaceAll(',', ''));
  final target = type == 'savings' && parsedTarget != null && parsedTarget > 0
      ? parsedTarget
      : null;

  try {
    if (existing == null) {
      if (type == 'savings') {
        return await state.addPot(name: name, targetAmount: target);
      }
      return await state.addCategory(
        name: name,
        colorValue: colorValue,
        type: type,
      );
    } else {
      await state.updateCategory(
        existing.copyWith(
          nameEn: name,
          nameRu: name,
          colorValue: colorValue,
          type: type,
          targetAmount: target,
          clearTargetAmount: target == null,
        ),
      );
      return existing.id;
    }
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
  }
  return null;
}

/// Full category detail: edit fields + subcategory list.
Future<void> showCategoryRegisterSheet(
  BuildContext context, {
  required BudgetCategory category,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final nameCtrl = TextEditingController(
    text: category.localizedName(state.localeCode),
  );
  final targetCtrl = TextEditingController(
    text: category.targetAmount != null && category.targetAmount! > 0
        ? category.targetAmount!.toStringAsFixed(2)
        : '',
  );
  var type = category.type;
  var colorValue = category.colorValue;

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            final live = ctx.watch<AppState>();
            final cat = live.categoryById(category.id) ?? category;
            final subs = live.subcategoriesFor(cat.id);
            final canEdit = live.canEditPlan;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  enabled: canEdit,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.categoryName),
                ),
                const SizedBox(height: 8),
                Text(l10n.categoryType),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in const [
                      'spend',
                      'monthly',
                      'debt',
                      'savings',
                    ])
                      ChoiceChip(
                        label: Text(categoryTypeLabel(l10n, t)),
                        selected: type == t,
                        onSelected: canEdit
                            ? (_) => setModal(() => type = t)
                            : null,
                      ),
                  ],
                ),
                if (type == 'savings') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: targetCtrl,
                    enabled: canEdit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l10n.targetAmount),
                  ),
                ],
                if (type != 'savings') ...[
                  const SizedBox(height: 8),
                  Text(l10n.categoryColor),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryColorPalette.map((c) {
                      final selected = c == colorValue;
                      return GestureDetector(
                        onTap: canEdit
                            ? () => setModal(() => colorValue = c)
                            : null,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(width: 3, color: Colors.black87)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  cat.isSavings ? l10n.sectionSavings : l10n.subcategory,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.noSubcategories),
                  )
                else
                  ...subs.map(
                    (sub) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(sub.localizedName(live.localeCode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(ctx, 'open_sub');
                        showSubcategoryRegisterSheet(
                          context,
                          subcategory: sub,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: canEdit
                            ? () async {
                                Navigator.pop(ctx, 'add_sub');
                                final subId = await showAddSubcategorySheet(
                                  context,
                                  categoryId: cat.id,
                                );
                                if (subId == null || !context.mounted) return;
                                final sub =
                                    context.read<AppState>().subcategoryById(
                                          subId,
                                        );
                                if (sub != null) {
                                  showSubcategoryRegisterSheet(
                                    context,
                                    subcategory: sub,
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          cat.isSavings ? l10n.addPot : l10n.addSubcategory,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: canEdit
                            ? () => Navigator.pop(ctx, 'save')
                            : null,
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: Text(l10n.delete),
                          content: Text(cat.localizedName(live.localeCode)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && ctx.mounted) {
                        Navigator.pop(ctx, 'delete');
                      }
                    },
                    child: Text(l10n.delete),
                  ),
                ],
              ],
            );
          },
        ),
      );
    },
  );

  if (!context.mounted) return;
  final live = context.read<AppState>();
  if (result == 'delete') {
    await live.deleteCategory(category.id);
    return;
  }
  if (result == null || result == 'open_sub' || result == 'add_sub') return;
  if (!live.canEditPlan) return;

  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return;
  final parsedTarget = double.tryParse(targetCtrl.text.replaceAll(',', ''));
  final target = type == 'savings' && parsedTarget != null && parsedTarget > 0
      ? parsedTarget
      : null;
  final current = live.categoryById(category.id) ?? category;
  await live.updateCategory(
    current.copyWith(
      nameEn: name,
      nameRu: name,
      colorValue: colorValue,
      type: type,
      targetAmount: target,
      clearTargetAmount: target == null,
    ),
  );
}

class CategorySourceChoice {
  const CategorySourceChoice.custom()
      : suggested = null,
        wantsCustom = true;
  const CategorySourceChoice.suggested(this.suggested) : wantsCustom = false;

  final DefaultCategory? suggested;
  final bool wantsCustom;
}
