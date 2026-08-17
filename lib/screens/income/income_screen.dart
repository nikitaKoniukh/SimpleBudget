import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/money.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.income)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSource(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addIncomeSource),
      ),
      body: state.incomeSources.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.emptyIncome, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          ...state.incomeSources.map((source) {
            final total = state.incomeForSource(source.id);
            final entries = state.incomeEntries
                .where((e) => e.sourceId == source.id)
                .toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(source.localizedName(state.localeCode)),
                subtitle: Text(formatIls(total)),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: l10n.addEntry,
                  onPressed: () => _addEntry(context, source.id),
                ),
                children: [
                  if (entries.isEmpty)
                    ListTile(title: Text(l10n.noData))
                  else
                    ...entries.map(
                      (e) => ListTile(
                        dense: true,
                        title: Text(formatIls(e.amount)),
                        subtitle: e.note != null ? Text(e.note!) : null,
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(
            '${l10n.totalIncome}: ${formatIls(state.totals.income)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _addEntry(BuildContext context, String sourceId) async {
    final l10n = AppLocalizations.of(context);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addEntry),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.amount),
            ),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(labelText: l10n.note),
            ),
          ],
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
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;
    final state = context.read<AppState>();
    final hid = state.appUser!.householdId!;
    await state.repo.addIncomeEntry(
      householdId: hid,
      monthId: state.monthId,
      sourceId: sourceId,
      amount: amount,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
  }

  Future<void> _addSource(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addIncomeSource),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: l10n.description),
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
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final state = context.read<AppState>();
    await state.repo.addIncomeSource(
      householdId: state.appUser!.householdId!,
      monthId: state.monthId,
      nameEn: name,
      nameRu: name,
      sortOrder: state.incomeSources.length,
    );
  }
}
