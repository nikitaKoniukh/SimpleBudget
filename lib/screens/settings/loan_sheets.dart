import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../widgets/form_sheet.dart';

/// Shows the add-loan form. Returns the new loan id, or null if cancelled.
Future<String?> showAddLoanSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final remainingCtrl = TextEditingController();
  final paymentCtrl = TextEditingController();
  final installmentsCtrl = TextEditingController();
  final paidCtrl = TextEditingController(text: '0');
  var type = 'balance';

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FormSheet(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  l10n.addLoan,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.description),
                  textCapitalization: TextCapitalization.sentences,
                ),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'balance',
                      label: Text(l10n.loanTypeBalance),
                    ),
                    ButtonSegment(
                      value: 'installment',
                      label: Text(l10n.loanTypeInstallment),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setModal(() => type = v.first),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.originalAmount,
                  ),
                ),
                TextField(
                  controller: remainingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.remainingBalance,
                    helperText: l10n.remainingBalanceHint,
                  ),
                ),
                TextField(
                  controller: paymentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.amountMonthly,
                  ),
                ),
                if (type == 'installment') ...[
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.installmentCurrent,
                      helperText: l10n.installmentHelper,
                    ),
                  ),
                  TextField(
                    controller: installmentsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.installmentTotal,
                    ),
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
  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
  if (nameCtrl.text.trim().isEmpty || amount <= 0) return null;
  final remainingRaw = remainingCtrl.text.trim();
  final remaining = remainingRaw.isEmpty
      ? null
      : double.tryParse(remainingRaw.replaceAll(',', '.'));
  final payment = double.tryParse(paymentCtrl.text.replaceAll(',', '.'));
  final totalInst = int.tryParse(installmentsCtrl.text.trim());
  final paidInst = int.tryParse(paidCtrl.text.trim()) ?? 0;
  try {
    return await context.read<AppState>().addLoan(
      name: nameCtrl.text.trim(),
      type: type,
      originalAmount: amount,
      remainingBalance: remaining != null && remaining >= 0 ? remaining : null,
      monthlyPayment: payment != null && payment > 0 ? payment : null,
      totalInstallments: type == 'installment' ? totalInst : null,
      paidInstallments: type == 'installment' ? paidInst : null,
    );
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
    return null;
  }
}
