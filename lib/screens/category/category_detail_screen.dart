import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/summary_card.dart';
import 'categories_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final cat = state.categories.where((c) => c.id == categoryId).firstOrNull;
    if (cat == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noData)),
      );
    }
    final items = state.itemsForCategory(categoryId);
    final planned = state.categoryPlanned(categoryId);
    final actual = state.categoryActual(categoryId);

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(cat.localizedName(state.localeCode)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  label: Text(
                    cat.type == 'savings'
                        ? l10n.typeSavings
                        : cat.type == 'debt'
                            ? l10n.typeDebt
                            : l10n.typeExpense,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showLineItemEditor(
            context,
            categoryId: categoryId,
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.addItem),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(cat.colorValue).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${l10n.groupTotal}: ${formatIls(actual)} / ${formatIls(planned)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(l10n.noData)
            else
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showLineItemEditor(context, item: item),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.localizedDescription(state.localeCode),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (item.installmentHint != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.installmentHint!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: SyncColors.textMuted),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StackedMetric(
                                    label: l10n.plannedLabel,
                                    value: formatIls(item.planned),
                                  ),
                                ),
                                Expanded(
                                  child: _StackedMetric(
                                    label: l10n.spentLabel,
                                    value: formatIls(item.actual),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.difference,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: SyncColors.textMuted,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      DifferenceText(value: item.difference),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StackedMetric extends StatelessWidget {
  const _StackedMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SyncColors.textMuted,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

Future<void> showLineItemEditor(
  BuildContext context, {
  LineItem? item,
  String? categoryId,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  var categories = List<BudgetCategory>.from(state.categories);
  String? selectedCategoryId =
      item?.categoryId ?? categoryId ?? categories.firstOrNull?.id;

  final descCtrl = TextEditingController(
    text: item?.localizedDescription(state.localeCode) ?? '',
  );
  final plannedCtrl = TextEditingController(
    text: item != null ? item.planned.toStringAsFixed(2) : '',
  );
  final actualCtrl = TextEditingController(
    text: item != null ? item.actual.toStringAsFixed(2) : '',
  );
  final installmentCtrl = TextEditingController(
    text: item?.installmentHint ?? '',
  );

  final result = await showModalBottomSheet<String>(
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
          builder: (ctx, setModalState) {
            Future<void> addCategoryFromList() async {
              final choice = await showCategorySourceSheet(context);
              if (choice == null || !context.mounted) return;
              if (choice.suggested != null) {
                final id = await context
                    .read<AppState>()
                    .addSuggestedCategory(choice.suggested!);
                if (!context.mounted || id == null) return;
                setModalState(() {
                  categories = List<BudgetCategory>.from(
                    context.read<AppState>().categories,
                  );
                  selectedCategoryId = id;
                });
                return;
              }
              if (!choice.wantsCustom) return;
              final nameCtrl = TextEditingController();
              var type = 'expense';
              var colorValue = 0xFF81C784;
              final ok = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (customCtx) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom:
                          MediaQuery.of(customCtx).viewInsets.bottom + 16,
                    ),
                    child: StatefulBuilder(
                      builder: (customCtx, setCustom) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.customCategory,
                                style: Theme.of(customCtx).textTheme.titleLarge,
                              ),
                              TextField(
                                controller: nameCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n.categoryName,
                                ),
                                autofocus: true,
                              ),
                              const SizedBox(height: 8),
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
                                onSelectionChanged: (s) =>
                                    setCustom(() => type = s.first),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(customCtx, true),
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
              final id = await context.read<AppState>().addCategory(
                    name: name,
                    colorValue: colorValue,
                    type: type,
                  );
              if (!context.mounted) return;
              setModalState(() {
                categories = List<BudgetCategory>.from(
                  context.read<AppState>().categories,
                );
                selectedCategoryId = id;
              });
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item == null ? l10n.addExpense : l10n.save,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (categories.isEmpty)
                    OutlinedButton.icon(
                      onPressed: addCategoryFromList,
                      icon: const Icon(Icons.category_outlined),
                      label: Text(l10n.chooseFromList),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedCategoryId),
                      initialValue: selectedCategoryId,
                      decoration: InputDecoration(labelText: l10n.category),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.localizedName(state.localeCode),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => selectedCategoryId = v);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: addCategoryFromList,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.chooseFromList),
                      ),
                    ),
                  ],
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: l10n.description),
                  ),
                  TextField(
                    controller: plannedCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.budget),
                  ),
                  TextField(
                    controller: actualCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.actual),
                  ),
                  TextField(
                    controller: installmentCtrl,
                    decoration: InputDecoration(
                      labelText: '${l10n.installment} (3/14)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: selectedCategoryId == null
                        ? null
                        : () => Navigator.pop(ctx, 'save'),
                    child: Text(l10n.save),
                  ),
                  if (item != null)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'delete'),
                      child: Text(
                        l10n.delete,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  if (result == null || !context.mounted) return;
  final hid = state.appUser!.householdId!;
  final monthId = state.monthId;
  if (monthId == null) return;

  if (result == 'delete' && item != null) {
    await state.repo.deleteLineItem(
      householdId: hid,
      monthId: monthId,
      itemId: item.id,
    );
    return;
  }

  final planned =
      double.tryParse(plannedCtrl.text.replaceAll(',', '')) ?? 0;
  final actual = double.tryParse(actualCtrl.text.replaceAll(',', '')) ?? 0;
  int? instCur;
  int? instTot;
  final inst = installmentCtrl.text.trim();
  if (inst.contains('/')) {
    final parts = inst.split('/');
    instCur = int.tryParse(parts[0].trim());
    instTot = int.tryParse(parts[1].trim());
  }
  final desc = descCtrl.text.trim();
  final catId = selectedCategoryId;
  if (desc.isEmpty || catId == null) return;

  if (item == null) {
    await state.repo.createLineItem(
      householdId: hid,
      monthId: monthId,
      categoryId: catId,
      descriptionEn: desc,
      descriptionRu: desc,
      planned: planned,
      actual: actual,
      installmentCurrent: instCur,
      installmentTotal: instTot,
    );
  } else {
    final updated = item.copyWith(
      planned: planned,
      actual: actual,
      descriptionEn: desc,
      descriptionRu: desc,
      installmentCurrent: instCur,
      installmentTotal: instTot,
    );
    await state.repo.upsertLineItem(
      householdId: hid,
      monthId: monthId,
      item: LineItem(
        id: updated.id,
        categoryId: catId,
        descriptionEn: updated.descriptionEn,
        descriptionRu: updated.descriptionRu,
        planned: updated.planned,
        actual: updated.actual,
        installmentCurrent: updated.installmentCurrent,
        installmentTotal: updated.installmentTotal,
        sortOrder: updated.sortOrder,
      ),
    );
  }
}
