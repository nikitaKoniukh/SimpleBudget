import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../widgets/form_sheet.dart';

/// Shows the add-loan form. Returns the new loan id, or null if cancelled.
Future<String?> showAddLoanSheet(BuildContext context) async {
  final result = await _showLoanFormSheet(context);
  if (result == null || !context.mounted) return null;
  final l10n = AppLocalizations.of(context);
  try {
    return await context.read<AppState>().addLoan(
          name: result.name,
          type: result.type,
          originalAmount: result.originalAmount,
          remainingBalance: result.remainingBalance,
          monthlyPayment: result.monthlyPayment,
          totalInstallments: result.totalInstallments,
          paidInstallments: result.paidInstallments,
        );
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
    return null;
  }
}

/// Edit an existing loan. Returns true if saved.
Future<bool> showEditLoanSheet(
  BuildContext context, {
  required Loan loan,
}) async {
  final result = await _showLoanFormSheet(context, existing: loan);
  if (result == null || !context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  final remaining = result.remainingBalance ?? result.originalAmount;
  final paid = result.type == 'installment'
      ? (result.paidInstallments ?? 0)
          .clamp(0, result.totalInstallments ?? 999999)
      : 0;
  final updated = loan.copyWith(
    name: result.name,
    type: result.type,
    originalAmount: result.originalAmount,
    remainingBalance: remaining,
    monthlyPayment: result.monthlyPayment,
    clearMonthlyPayment: result.monthlyPayment == null,
    totalInstallments: result.type == 'installment'
        ? result.totalInstallments
        : null,
    clearTotalInstallments: result.type != 'installment',
    paidInstallments: result.type == 'installment' ? paid : null,
    clearPaidInstallments: result.type != 'installment',
    status: remaining <= 0 ? 'paidOff' : 'active',
  );
  try {
    await context.read<AppState>().updateLoan(updated);
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
    );
    return false;
  }
}

Future<bool> confirmDeleteLoan(BuildContext context, Loan loan) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteLoanConfirm),
      content: Text(loan.name),
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

class _LoanFormResult {
  const _LoanFormResult({
    required this.name,
    required this.type,
    required this.originalAmount,
    this.remainingBalance,
    this.monthlyPayment,
    this.totalInstallments,
    this.paidInstallments,
  });

  final String name;
  final String type;
  final double originalAmount;
  final double? remainingBalance;
  final double? monthlyPayment;
  final int? totalInstallments;
  final int? paidInstallments;
}

Future<_LoanFormResult?> _showLoanFormSheet(
  BuildContext context, {
  Loan? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final editing = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final amountCtrl = TextEditingController(
    text: existing != null ? _fmtNum(existing.originalAmount) : '',
  );
  final remainingCtrl = TextEditingController(
    text: existing != null ? _fmtNum(existing.remainingBalance) : '',
  );
  final paymentCtrl = TextEditingController(
    text: existing?.monthlyPayment != null
        ? _fmtNum(existing!.monthlyPayment!)
        : '',
  );
  final installmentsCtrl = TextEditingController(
    text: existing?.totalInstallments?.toString() ?? '',
  );
  final paidCtrl = TextEditingController(
    text: existing != null ? '${existing.paidCount}' : '0',
  );
  var type = existing?.type ?? 'balance';

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
                  editing ? l10n.editLoan : l10n.addLoan,
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

  if (ok != true) return null;
  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
  if (nameCtrl.text.trim().isEmpty || amount <= 0) return null;
  final remainingRaw = remainingCtrl.text.trim();
  final remaining = remainingRaw.isEmpty
      ? null
      : double.tryParse(remainingRaw.replaceAll(',', '.'));
  final paymentRaw = paymentCtrl.text.trim();
  final payment = paymentRaw.isEmpty
      ? null
      : double.tryParse(paymentRaw.replaceAll(',', '.'));
  final totalInst = int.tryParse(installmentsCtrl.text.trim());
  final paidInst = int.tryParse(paidCtrl.text.trim()) ?? 0;

  return _LoanFormResult(
    name: nameCtrl.text.trim(),
    type: type,
    originalAmount: amount,
    remainingBalance: remaining != null && remaining >= 0 ? remaining : null,
    monthlyPayment: payment != null && payment > 0 ? payment : null,
    totalInstallments: type == 'installment' ? totalInst : null,
    paidInstallments: type == 'installment' ? paidInst : null,
  );
}

String _fmtNum(double value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toString();
}
