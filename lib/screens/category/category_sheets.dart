import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/category_icons.dart';
import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../navigation/adaptive_page_route.dart';
import '../../widgets/form_sheet.dart';
import 'category_detail_screen.dart';

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

Widget categoryIconPicker({
  required String iconKey,
  required int colorValue,
  required ValueChanged<String> onSelected,
  bool enabled = true,
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: categoryIconCatalog.map((entry) {
      final selected = entry.key == iconKey;
      return GestureDetector(
        onTap: enabled ? () => onSelected(entry.key) : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(colorValue),
            shape: BoxShape.circle,
            border: selected
                ? Border.all(width: 3, color: Colors.black87)
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            entry.icon,
            size: 20,
            color: Color(colorValue).computeLuminance() > 0.55
                ? Colors.black87
                : Colors.white,
          ),
        ),
      );
    }).toList(),
  );
}

/// Opens picker: choose from suggested list, or create a custom category.
Future<String?> showAddCategoryFlow(
  BuildContext context, {
  String? preferredType,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showCategorySourceSheet(
    context,
    preferredType: preferredType,
  );
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
  BuildContext context, {
  String? preferredType,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final existing = {
    for (final c in state.categories) c.nameEn.toLowerCase(),
  };
  final allowedTypes = preferredType == null
      ? null
      : preferredType == 'spend'
          ? const {'spend', 'monthly'}
          : {preferredType};
  final available = DefaultCategories.all
      .where((c) => !existing.contains(c.nameEn.toLowerCase()))
      .where((c) => allowedTypes == null || allowedTypes.contains(c.type))
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
            maxChildSize: 1,
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
                        avatar: CategoryColorIcon(
                          colorValue: cat.colorValue,
                          iconKey: cat.iconKey,
                          size: 24,
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
  final plannedCtrl = TextEditingController();
  var type = existing?.type ?? preferredType ?? 'spend';
  var colorValue = existing?.colorValue ?? categoryColorPalette.first;
  var iconKey = existing?.iconKey ?? defaultCategoryIconKey;

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
                      'savings',
                    ])
                      ChoiceChip(
                        label: Text(categoryTypeLabel(l10n, t)),
                        selected: type == t,
                        onSelected: (_) => setLocal(() => type = t),
                      ),
                  ],
                ),
                if (type == 'savings') ...[
                  TextField(
                    controller: plannedCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.plannedLabel),
                  ),
                  TextField(
                    controller: targetCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.targetOptional),
                  ),
                ],
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
                  Text(l10n.categoryIcon),
                  categoryIconPicker(
                    iconKey: iconKey,
                    colorValue: colorValue,
                    onSelected: (key) => setLocal(() => iconKey = key),
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
  final parsedTarget = double.tryParse(targetCtrl.text.replaceAll(',', '.'));
  final target = type == 'savings' && parsedTarget != null && parsedTarget > 0
      ? parsedTarget
      : null;
  final planned =
      double.tryParse(plannedCtrl.text.replaceAll(',', '.')) ?? 0;

  try {
    if (existing == null) {
      if (type == 'savings') {
        return await state.addPot(
          name: name,
          targetAmount: target,
          planned: planned,
        );
      }
      return await state.addCategory(
        name: name,
        colorValue: colorValue,
        iconKey: iconKey,
        type: type,
      );
    } else {
      await state.updateCategory(
        existing.copyWith(
          nameEn: name,
          nameRu: name,
          colorValue: colorValue,
          iconKey: iconKey,
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

/// Opens full-screen category detail (view + edit).
Future<void> showCategoryRegisterSheet(
  BuildContext context, {
  required BudgetCategory category,
}) {
  return pushAdaptivePage(
    context,
    CategoryDetailScreen(categoryId: category.id),
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
