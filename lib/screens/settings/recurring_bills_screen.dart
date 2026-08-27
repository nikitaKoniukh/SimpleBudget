import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/form_sheet.dart';
import '../../widgets/sync_app_bar.dart';

class RecurringBillsScreen extends StatelessWidget {
  const RecurringBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final bills = List.of(state.recurringBills)
      ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.page(title: l10n.recurringBills),
        floatingActionButton: state.canEditPlan
            ? FloatingActionButton.extended(
                onPressed: () => _showAddBill(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addBill),
              )
            : null,
        body: bills.isEmpty
            ? Center(child: Text(l10n.noData))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  for (final bill in bills)
                    Card(
                      child: ListTile(
                        title: Text(bill.name),
                        subtitle: Text(
                          '${l10n.billDay} ${bill.dayOfMonth}'
                          '${bill.subcategoryId != null ? ' · ${state.subcategoryById(bill.subcategoryId!)?.localizedName(state.localeCode) ?? ''}' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatIls(bill.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (state.canEditPlan)
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    state.deleteRecurringBill(bill.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _showAddBill(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var day = 1;
    String? subId = state.subcategories.where((s) {
      final cat = state.categoryById(s.categoryId);
      return cat != null && !cat.isSavings;
    }).firstOrNull?.id;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return FormSheet(
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final live = ctx.watch<AppState>();
              final spendSubs = live.subcategories.where((s) {
                final cat = live.categoryById(s.categoryId);
                return cat != null && !cat.isSavings;
              }).toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text(l10n.addBill, style: Theme.of(ctx).textTheme.titleLarge),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l10n.description),
                  ),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.amountMonthly),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: day,
                    decoration: InputDecoration(labelText: l10n.billDay),
                    items: [
                      for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModal(() => day = v);
                    },
                  ),
                  if (spendSubs.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: subId,
                      decoration: InputDecoration(labelText: l10n.subcategory),
                      items: spendSubs.map((s) {
                        final cat = live.categoryById(s.categoryId);
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            '${cat?.localizedName(live.localeCode) ?? ''} · ${s.localizedName(live.localeCode)}',
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setModal(() => subId = v),
                    ),
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
    if (ok != true || !context.mounted) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
    final name = nameCtrl.text.trim();
    if (name.isEmpty || amount <= 0) return;
    await context.read<AppState>().addRecurringBill(
          name: name,
          amount: amount,
          dayOfMonth: day,
          subcategoryId: subId,
        );
  }
}
