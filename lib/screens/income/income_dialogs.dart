import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';
import '../../widgets/form_sheet.dart';

Future<void> showAddIncomeSourceDialog(BuildContext context) async {
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
  if (ok != true || !context.mounted) return;
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return;
  final state = context.read<AppState>();
  await state.repo.addIncomeSource(
    householdId: state.appUser!.householdId!,
    monthId: state.monthId!,
    nameEn: name,
    nameRu: name,
    sortOrder: state.incomeSources.length,
  );
}

Future<void> showAddIncomeEntryFlow(BuildContext context) async {
  final state = context.read<AppState>();
  if (state.incomeSources.isEmpty) {
    await showAddIncomeSourceDialog(context);
    if (!context.mounted) return;
    if (context.read<AppState>().incomeSources.isEmpty) return;
  }
  final sources = context.read<AppState>().incomeSources;
  await showIncomeEntryEditor(context, sources: sources);
}

Future<void> showIncomeEntryEditor(
  BuildContext context, {
  required List<IncomeSource> sources,
  IncomeEntry? entry,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (sources.isEmpty) return;

  var sourceId = entry?.sourceId ?? sources.first.id;
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  entry == null ? l10n.addEntry : l10n.editIncome,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                DropdownButtonFormField<String>(
                  initialValue: sourceId,
                  decoration: InputDecoration(labelText: l10n.income),
                  items: sources
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.localizedName(state.localeCode)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setModal(() => sourceId = v);
                  },
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
                  onPressed: () => Navigator.pop(ctx, 'save'),
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

  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  if (amount <= 0) return;
  final noteText = sentenceCase(noteCtrl.text);
  final note = noteText.isEmpty ? null : noteText;

  if (entry == null) {
    await state.repo.addIncomeEntry(
      householdId: hid,
      monthId: monthId,
      sourceId: sourceId,
      amount: amount,
      note: note,
    );
  } else {
    await state.repo.updateIncomeEntry(
      householdId: hid,
      monthId: monthId,
      entry: entry.copyWith(
        sourceId: sourceId,
        amount: amount,
        note: note,
      ),
    );
  }
}
