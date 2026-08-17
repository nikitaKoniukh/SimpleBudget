import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/money.dart';
import '../../widgets/summary_card.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.localizedName(state.localeCode)),
        backgroundColor: Color(cat.colorValue).withValues(alpha: 0.5),
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
          Text(
            '${l10n.groupTotal}: ${formatIls(actual)} / ${formatIls(planned)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(l10n.description, style: _headerStyle)),
              SizedBox(
                width: 88,
                child: Text(l10n.budget, style: _headerStyle, textAlign: TextAlign.end),
              ),
              SizedBox(
                width: 88,
                child: Text(l10n.actual, style: _headerStyle, textAlign: TextAlign.end),
              ),
              SizedBox(
                width: 88,
                child: Text(l10n.difference, style: _headerStyle, textAlign: TextAlign.end),
              ),
            ],
          ),
          const Divider(),
          ...items.map((item) {
            return InkWell(
              onTap: () => showLineItemEditor(context, item: item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.localizedDescription(state.localeCode),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (item.installmentHint != null)
                            Text(
                              item.installmentHint!,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: Text(
                        formatIls(item.planned),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: Text(
                        formatIls(item.actual),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DifferenceText(value: item.difference),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

Future<void> showLineItemEditor(
  BuildContext context, {
  LineItem? item,
  String? categoryId,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final categories = state.categories;
  if (categories.isEmpty) return;

  var selectedCategoryId = item?.categoryId ?? categoryId ?? categories.first.id;
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
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item == null ? l10n.addItem : l10n.save,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    decoration: InputDecoration(labelText: l10n.category),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.localizedName(state.localeCode)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setModalState(() => selectedCategoryId = v);
                    },
                  ),
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
                    onPressed: () => Navigator.pop(ctx, 'save'),
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
  if (desc.isEmpty) return;

  if (item == null) {
    await state.repo.createLineItem(
      householdId: hid,
      monthId: monthId,
      categoryId: selectedCategoryId,
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
    // category may change — rebuild map
    await state.repo.upsertLineItem(
      householdId: hid,
      monthId: monthId,
      item: LineItem(
        id: updated.id,
        categoryId: selectedCategoryId,
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
