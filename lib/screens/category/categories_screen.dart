import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';

const _palette = <int>[
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

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.manageCategories)),
        body: Center(child: Text(l10n.noMonthSelected)),
      );
    }

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.manageCategories),
          actions: [
            if (state.categories.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final n = await state.addDefaultCategories();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        n > 0
                            ? l10n.defaultsAdded
                            : l10n.defaultsAlreadyPresent,
                      ),
                    ),
                  );
                },
                child: Text(l10n.addDefaultCategories),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showAddCategoryFlow(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.addCategory),
        ),
        body: state.categories.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.emptyCategories, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => showAddCategoryFlow(context),
                        child: Text(l10n.addCategory),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          final n = await state.addDefaultCategories();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                n > 0
                                    ? l10n.defaultsAdded
                                    : l10n.defaultsAlreadyPresent,
                              ),
                            ),
                          );
                        },
                        child: Text(l10n.addDefaultCategories),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final cat = state.categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Color(cat.colorValue).withValues(alpha: 0.35),
                    child: ListTile(
                      title: Text(cat.localizedName(state.localeCode)),
                      subtitle: Text(_typeLabel(l10n, cat.type)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editCategory(context, cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.delete),
                                  content: Text(
                                    cat.localizedName(state.localeCode),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && context.mounted) {
                                await state.deleteCategory(cat.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'savings':
        return l10n.typeSavings;
      case 'debt':
        return l10n.typeDebt;
      default:
        return l10n.typeExpense;
    }
  }
}

/// Opens picker: choose from suggested list, or create a custom category.
Future<void> showAddCategoryFlow(BuildContext context) async {
  final choice = await showCategorySourceSheet(context);
  if (choice == null || !context.mounted) return;

  if (choice.suggested != null) {
    await context.read<AppState>().addSuggestedCategory(choice.suggested!);
    return;
  }

  if (choice.wantsCustom) {
    await _editCategory(context);
  }
}

/// Sheet to pick a suggested category or request custom entry.
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
    builder: (ctx) {
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  l10n.chooseFromList,
                  style: Theme.of(ctx).textTheme.titleLarge,
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
                        label: Text(cat.localizedName(state.localeCode)),
                        onPressed: () => Navigator.pop(
                          ctx,
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
                    ctx,
                    const CategorySourceChoice.custom(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<void> _editCategory(
  BuildContext context, [
  BudgetCategory? existing,
]) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final nameCtrl = TextEditingController(
    text: existing?.localizedName(state.localeCode) ?? '',
  );
  var type = existing?.type ?? 'expense';
  var colorValue = existing?.colorValue ?? _palette.first;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null ? l10n.customCategory : l10n.save,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l10n.categoryName),
                    autofocus: existing == null,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.categoryType),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'expense',
                        label: Text(l10n.typeExpense),
                      ),
                      ButtonSegment(
                        value: 'savings',
                        label: Text(l10n.typeSavings),
                      ),
                      ButtonSegment(
                        value: 'debt',
                        label: Text(l10n.typeDebt),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) => setLocal(() => type = s.first),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.categoryColor),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _palette.map((c) {
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
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return;
  final name = nameCtrl.text.trim();
  if (name.isEmpty) return;

  if (existing == null) {
    await state.addCategory(
      name: name,
      colorValue: colorValue,
      type: type,
    );
  } else {
    await state.updateCategory(
      BudgetCategory(
        id: existing.id,
        nameEn: name,
        nameRu: name,
        colorValue: colorValue,
        type: type,
        sortOrder: existing.sortOrder,
      ),
    );
  }
}

class CategorySourceChoice {
  const CategorySourceChoice.custom()
      : suggested = null,
        wantsCustom = true;
  const CategorySourceChoice.suggested(this.suggested) : wantsCustom = false;

  final DefaultCategory? suggested;
  final bool wantsCustom;
}
