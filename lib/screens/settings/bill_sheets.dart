import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../widgets/form_sheet.dart';

Future<bool> showAddBillSheet(BuildContext context) async {
  final result = await _showBillFormSheet(context);
  if (result == null || !context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  try {
    await context.read<AppState>().addRecurringBill(
          name: result.name,
          amount: result.amount,
          dayOfMonth: result.dayOfMonth,
          subcategoryId: result.subcategoryId,
        );
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
    return false;
  }
}

Future<bool> showEditBillSheet(
  BuildContext context, {
  required RecurringBill bill,
}) async {
  final result = await _showBillFormSheet(context, existing: bill);
  if (result == null || !context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  final updated = bill.copyWith(
    name: result.name,
    amount: result.amount,
    dayOfMonth: result.dayOfMonth,
    subcategoryId: result.subcategoryId,
    clearSubcategoryId: result.subcategoryId == null,
  );
  try {
    await context.read<AppState>().updateRecurringBill(updated);
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
    return false;
  }
}

Future<bool> confirmDeleteBill(BuildContext context, RecurringBill bill) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteBillConfirm),
      content: Text(bill.name),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.confirmDelete),
        ),
      ],
    ),
  );
  return ok == true;
}

class _BillFormResult {
  const _BillFormResult({
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    this.subcategoryId,
  });

  final String name;
  final double amount;
  final int dayOfMonth;
  final String? subcategoryId;
}

Future<_BillFormResult?> _showBillFormSheet(
  BuildContext context, {
  RecurringBill? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final editing = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final amountCtrl = TextEditingController(
    text: existing != null ? _fmtNum(existing.amount) : '',
  );
  var day = (existing?.dayOfMonth ?? 1).clamp(1, 28);
  String? subId = existing?.subcategoryId;
  if (subId == null && existing == null) {
    subId = state.subcategories.where((s) {
      final cat = state.categoryById(s.categoryId);
      return cat != null && !cat.isSavings;
    }).firstOrNull?.id;
  }
  String? formError;

  try {
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
              if (subId != null &&
                  spendSubs.every((s) => s.id != subId)) {
                subId = spendSubs.firstOrNull?.id;
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text(
                    editing ? l10n.editBill : l10n.addBill,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.description),
                  ),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l10n.amountMonthly),
                  ),
                  DropdownButtonFormField<int>(
                    key: ValueKey('bill-day-$day'),
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
                    DropdownButtonFormField<String?>(
                      key: ValueKey('bill-sub-$subId'),
                      initialValue: subId,
                      decoration: InputDecoration(labelText: l10n.subcategory),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: const Text('—'),
                        ),
                        for (final s in spendSubs)
                          DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(
                              '${live.categoryById(s.categoryId)?.localizedName(live.localeCode) ?? ''} · ${s.localizedName(live.localeCode)}',
                            ),
                          ),
                      ],
                      onChanged: (v) => setModal(() => subId = v),
                    ),
                  if (formError != null)
                    Text(
                      formError!,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final amount = double.tryParse(
                            amountCtrl.text.replaceAll(',', '.'),
                          ) ??
                          0;
                      if (name.isEmpty) {
                        setModal(() => formError = l10n.fieldRequired);
                        return;
                      }
                      if (amount <= 0) {
                        setModal(() => formError = l10n.fieldRequired);
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    child: Text(l10n.save),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true) return null;
    final name = nameCtrl.text.trim();
    final amount =
        double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (name.isEmpty || amount <= 0) return null;
    return _BillFormResult(
      name: name,
      amount: amount,
      dayOfMonth: day,
      subcategoryId: subId,
    );
  } finally {
    nameCtrl.dispose();
    amountCtrl.dispose();
  }
}

String _fmtNum(double value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toString();
}
