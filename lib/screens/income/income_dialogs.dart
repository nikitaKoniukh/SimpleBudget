import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';

Future<String?> showAddIncomeSourceDialog(BuildContext context) async {
  final source = await _createIncomeSource(context);
  return source?.id;
}

Future<IncomeSource?> _createIncomeSource(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final nameCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.addIncomeSource),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: TextField(
        controller: nameCtrl,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.description),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return null;
  final state = context.read<AppState>();
  final sortOrder = state.incomeSources.length;
  final id = await state.repo.addIncomeSource(
    householdId: state.appUser!.householdId!,
    monthId: state.monthId!,
    nameEn: name,
    nameRu: name,
    sortOrder: sortOrder,
  );
  return IncomeSource(
    id: id,
    nameEn: name,
    nameRu: name,
    sortOrder: sortOrder,
  );
}

Future<void> _editIncomeSource(
  BuildContext context,
  IncomeSource source,
) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final hid = state.appUser?.householdId;
  final monthId = state.monthId;
  if (hid == null || monthId == null) return;
  final nameCtrl = TextEditingController(
    text: source.localizedName(state.localeCode),
  );
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.editIncomeSource),
      content: TextField(
        controller: nameCtrl,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.description),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'delete'),
          child: Text(
            l10n.deleteIncomeSource,
            style: TextStyle(color: Theme.of(ctx).colorScheme.error),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'save'),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (result == null || !context.mounted) return;
  if (result == 'delete') {
    await state.repo.deleteIncomeSource(
      householdId: hid,
      monthId: monthId,
      sourceId: source.id,
    );
    return;
  }
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return;
  await state.repo.updateIncomeSource(
    householdId: hid,
    monthId: monthId,
    source: IncomeSource(
      id: source.id,
      nameEn: name,
      nameRu: name,
      sortOrder: source.sortOrder,
    ),
  );
}

Future<void> showAddIncomeEntryFlow(BuildContext context) async {
  IncomeSource? created;
  if (context.read<AppState>().incomeSources.isEmpty) {
    created = await _createIncomeSource(context);
    if (!context.mounted) return;
    if (created == null && context.read<AppState>().incomeSources.isEmpty) {
      return;
    }
  }
  await showIncomeEntryEditor(
    context,
    sources: created == null ? null : [created],
  );
}

Future<void> showIncomeEntryEditor(
  BuildContext context, {
  List<IncomeSource>? sources,
  IncomeEntry? entry,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final initialSources = sources ?? state.incomeSources;

  var sourceId = entry?.sourceId ?? initialSources.firstOrNull?.id;
  IncomeSource? pendingSource = initialSources
      .where((s) => !state.incomeSources.any((live) => live.id == s.id))
      .firstOrNull;
  final amountCtrl = TextEditingController(
    text: entry != null ? entry.amount.toStringAsFixed(2) : '',
  );
  final noteCtrl = TextEditingController(text: entry?.note ?? '');

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            final live = ctx.watch<AppState>();
            var liveSources = List<IncomeSource>.of(live.incomeSources);
            if (pendingSource != null &&
                !liveSources.any((s) => s.id == pendingSource!.id)) {
              liveSources = [...liveSources, pendingSource!];
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  entry == null ? l10n.addEntry : l10n.editIncome,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                if (liveSources.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: ValueKey(sourceId),
                    initialValue: sourceId,
                    decoration: InputDecoration(labelText: l10n.income),
                    items: liveSources
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.localizedName(live.localeCode)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setModal(() => sourceId = v);
                    },
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final created = await _createIncomeSource(ctx);
                          if (created == null || !ctx.mounted) return;
                          setModal(() {
                            sourceId = created.id;
                            pendingSource = created;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addIncomeSource),
                      ),
                      if (sourceId != null && live.canEditPlan)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final source = liveSources
                                .where((s) => s.id == sourceId)
                                .firstOrNull;
                            if (source == null) return;
                            await _editIncomeSource(ctx, source);
                            if (!ctx.mounted) return;
                            setModal(() {});
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l10n.editIncomeSource),
                        ),
                    ],
                  ),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.amount),
                ),
                TextField(
                  controller: noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.note),
                ),
                FilledButton(
                  onPressed: sourceId == null
                      ? null
                      : () => Navigator.pop(ctx, 'save'),
                  child: Text(l10n.save),
                ),
                if (entry != null)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'delete'),
                    child: Text(
                      l10n.deleteIncome,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                  ),
              ],
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

  if (result == 'delete' && entry != null) {
    await state.repo.deleteIncomeEntry(
      householdId: hid,
      monthId: monthId,
      entryId: entry.id,
    );
    return;
  }

  final selectedSourceId = sourceId;
  if (selectedSourceId == null) return;
  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  if (amount <= 0) return;
  final noteText = sentenceCase(noteCtrl.text);
  final note = noteText.isEmpty ? null : noteText;

  if (entry == null) {
    await state.addIncomeEntry(
      sourceId: selectedSourceId,
      amount: amount,
      note: note,
    );
  } else {
    await state.repo.updateIncomeEntry(
      householdId: hid,
      monthId: monthId,
      entry: entry.copyWith(
        sourceId: selectedSourceId,
        amount: amount,
        note: note,
      ),
    );
  }
}
