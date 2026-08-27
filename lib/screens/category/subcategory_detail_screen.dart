import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../navigation/adaptive_page_route.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../utils/text_format.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/detail_info_card.dart';
import '../../widgets/sync_app_bar.dart';
import '../home/log_entry_sheet.dart';

class SubcategoryDetailScreen extends StatefulWidget {
  const SubcategoryDetailScreen({super.key, required this.subcategoryId});

  final String subcategoryId;

  @override
  State<SubcategoryDetailScreen> createState() =>
      _SubcategoryDetailScreenState();
}

class _SubcategoryDetailScreenState extends State<SubcategoryDetailScreen> {
  bool _editing = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _plannedCtrl;
  late final TextEditingController _installmentCurrentCtrl;
  late final TextEditingController _installmentTotalCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _categoryTargetCtrl;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _plannedCtrl = TextEditingController();
    _installmentCurrentCtrl = TextEditingController();
    _installmentTotalCtrl = TextEditingController();
    _targetCtrl = TextEditingController();
    _categoryTargetCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncFromData();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _plannedCtrl.dispose();
    _installmentCurrentCtrl.dispose();
    _installmentTotalCtrl.dispose();
    _targetCtrl.dispose();
    _categoryTargetCtrl.dispose();
    super.dispose();
  }

  void _syncFromData() {
    final state = context.read<AppState>();
    final sub = state.subcategoryById(widget.subcategoryId);
    if (sub == null) return;
    final cat = state.categoryById(sub.categoryId);
    final plan = state.planFor(sub.id);

    _nameCtrl.text = state.localizedSubcategoryName(sub);
    _plannedCtrl.text = plan != null && plan.planned > 0
        ? plan.planned.toStringAsFixed(2)
        : '';
    _installmentCurrentCtrl.text =
        plan?.installmentCurrent != null ? '${plan!.installmentCurrent}' : '';
    _installmentTotalCtrl.text =
        sub.installmentTotal != null ? '${sub.installmentTotal}' : '';
    _targetCtrl.text = sub.targetAmount != null && sub.targetAmount! > 0
        ? sub.targetAmount!.toStringAsFixed(2)
        : '';
    _categoryTargetCtrl.text =
        cat?.targetAmount != null && cat!.targetAmount! > 0
            ? cat.targetAmount!.toStringAsFixed(2)
            : '';
    _targetDate = sub.targetDate;
  }

  void _startEditing() {
    _syncFromData();
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _syncFromData();
    setState(() => _editing = false);
  }

  Future<void> _save(
    AppState state,
    Subcategory sub,
    BudgetCategory? category,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!state.canEditPlan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.viewerReadOnlyPlan)),
      );
      return;
    }

    final name = sentenceCase(_nameCtrl.text);
    if (name.isEmpty) return;

    final planned =
        double.tryParse(_plannedCtrl.text.replaceAll(',', '')) ?? 0;
    final curText = _installmentCurrentCtrl.text.trim();
    final totText = _installmentTotalCtrl.text.trim();
    final instCur = int.tryParse(curText);
    final instTot = int.tryParse(totText);
    final isPot = category?.isSavings ?? false;
    final isDebt = category?.isDebt ?? false;

    try {
      if (category != null &&
          (category.isSavings || category.targetAmount != null)) {
        final parsedCat =
            double.tryParse(_categoryTargetCtrl.text.replaceAll(',', ''));
        final catTarget =
            parsedCat != null && parsedCat > 0 ? parsedCat : null;
        await state.updateCategory(
          category.copyWith(
            targetAmount: catTarget,
            clearTargetAmount: catTarget == null,
          ),
        );
      }

      if (isPot) {
        final parsed = double.tryParse(_targetCtrl.text.replaceAll(',', ''));
        final target = parsed != null && parsed > 0 ? parsed : null;
        await state.updateSubcategory(
          sub.copyWith(
            targetAmount: target,
            clearTargetAmount: target == null,
            targetDate: _targetDate,
            clearTargetDate: _targetDate == null,
          ),
        );
      } else if (isDebt) {
        await state.updateSubcategory(
          sub.copyWith(
            installmentTotal: instTot,
            clearInstallmentTotal: totText.isEmpty,
          ),
        );
      }

      final nameEnOverride = name == sub.nameEn ? null : name;
      final nameRuOverride = name == sub.nameRu ? null : name;
      await state.upsertPlan(
        subcategoryId: sub.id,
        planned: planned,
        installmentCurrent: isDebt ? instCur : null,
        clearInstallmentCurrent: !isDebt || curText.isEmpty,
        nameEn: nameEnOverride,
        nameRu: nameRuOverride,
        clearNameEn: nameEnOverride == null,
        clearNameRu: nameRuOverride == null,
      );

      if (!mounted) return;
      setState(() => _editing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    AppState state,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.removeFromMonth),
        content: Text(l10n.removeFromMonthConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(l10n.removeFromMonth),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await state.removeSubcategoryFromMonth(widget.subcategoryId);
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.flow(),
          body: Center(child: Text(l10n.noMonthSelected)),
        ),
      );
    }

    final sub = state.subcategoryById(widget.subcategoryId);
    if (sub == null) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.flow(),
          body: Center(child: Text(l10n.noData)),
        ),
      );
    }

    final category = state.categoryById(sub.categoryId);
    final isPot = category?.isSavings ?? false;
    final isDebt = category?.isDebt ?? false;
    final expenses = state.expensesFor(sub.id);
    final spent = state.spentFor(sub.id);
    final planned = state.planFor(sub.id)?.planned ?? 0;
    final plan = state.planFor(sub.id);
    final canEdit = state.canEditPlan;
    final dateFmt = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.flow(
          onBack: _editing ? _cancelEditing : null,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (category != null) ...[
              Center(
                child: CategoryColorIcon(
                  colorValue: category.colorValue,
                  iconKey: category.iconKey,
                  size: 56,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.localizedName(state.localeCode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _editing
                  ? l10n.editSubcategory
                  : state.localizedSubcategoryName(sub),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            if (_editing)
              _SubcategoryEditForm(
                l10n: l10n,
                category: category,
                isPot: isPot,
                isDebt: isDebt,
                nameCtrl: _nameCtrl,
                plannedCtrl: _plannedCtrl,
                installmentCurrentCtrl: _installmentCurrentCtrl,
                installmentTotalCtrl: _installmentTotalCtrl,
                targetCtrl: _targetCtrl,
                categoryTargetCtrl: _categoryTargetCtrl,
                targetDate: _targetDate,
                dateFmt: dateFmt,
                onTargetDateChanged: (d) => setState(() => _targetDate = d),
              )
            else ...[
              DetailInfoCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DetailStatCell(
                          label: l10n.spentLabel,
                          amount: formatIls(spent),
                          color: spent > planned && planned > 0
                              ? SyncColors.overspend
                              : SyncColors.accent,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: SyncColors.textMuted.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: DetailStatCell(
                          label: l10n.plannedLabel,
                          amount: formatIls(planned),
                          color: SyncColors.text,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isPot || (category?.targetAmount != null)) ...[
                const SizedBox(height: 12),
                DetailInfoCard(
                  children: [
                    if (category != null && category.savedTotal > 0)
                      DetailInfoRow(
                        label: l10n.savedLabel,
                        value: formatIls(category.savedTotal),
                        valueColor: SyncColors.primary,
                      ),
                    if (category?.targetAmount != null &&
                        category!.targetAmount! > 0)
                      DetailInfoRow(
                        label: l10n.targetAmount,
                        value: formatIls(category.targetAmount!),
                      ),
                    if (isPot && sub.savedTotal > 0)
                      DetailInfoRow(
                        label: l10n.savedLabel,
                        value: formatIls(sub.savedTotal),
                        valueColor: SyncColors.primary,
                      ),
                    if (isPot && sub.targetAmount != null && sub.targetAmount! > 0)
                      DetailInfoRow(
                        label: l10n.targetAmount,
                        value: formatIls(sub.targetAmount!),
                      ),
                    if (isPot && sub.targetDate != null)
                      DetailInfoRow(
                        label: l10n.targetDate,
                        value: dateFmt.format(sub.targetDate!),
                      ),
                  ],
                ),
              ],
              if (isDebt &&
                  (plan?.installmentCurrent != null ||
                      sub.installmentTotal != null)) ...[
                const SizedBox(height: 12),
                DetailInfoCard(
                  children: [
                    if (plan?.installmentCurrent != null)
                      DetailInfoRow(
                        label: l10n.installmentCurrent,
                        value: '${plan!.installmentCurrent}',
                      ),
                    if (sub.installmentTotal != null)
                      DetailInfoRow(
                        label: l10n.installmentTotal,
                        value: '${sub.installmentTotal}',
                      ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 20),
            Text(
              isPot ? l10n.thisMonthDeposits : l10n.recentExpenses,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (expenses.isEmpty)
              DetailInfoCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      isPot ? l10n.noDepositsThisMonth : l10n.noExpensesYet,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SyncColors.textMuted,
                          ),
                    ),
                  ),
                ],
              )
            else
              for (final expense in expenses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ExpenseTile(
                    expense: expense,
                    isPot: isPot,
                    isDebt: isDebt,
                    dateFmt: dateFmt,
                    onTap: _editing
                        ? () {
                            final editKind = isPot || expense.isDeposit
                                ? LogKind.save
                                : isDebt
                                    ? LogKind.debt
                                    : LogKind.spend;
                            showLogEntrySheet(
                              context,
                              kind: editKind,
                              expense: expense,
                            );
                          }
                        : null,
                  ),
                ),
            const SizedBox(height: 16),
            if (_editing) ...[
              FilledButton(
                onPressed: canEdit ? () => _save(state, sub, category) : null,
                child: Text(l10n.save),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _cancelEditing,
                child: Text(l10n.cancel),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () {
                  final addKind = isPot
                      ? LogKind.save
                      : isDebt
                          ? LogKind.debt
                          : LogKind.spend;
                  showLogEntrySheet(
                    context,
                    kind: addKind,
                    subcategoryId: sub.id,
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(isPot ? l10n.logDeposit : l10n.addExpense),
              ),
              if (canEdit) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.edit),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _confirmRemove(context, state),
                  child: Text(l10n.removeFromMonth),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SubcategoryEditForm extends StatelessWidget {
  const _SubcategoryEditForm({
    required this.l10n,
    required this.category,
    required this.isPot,
    required this.isDebt,
    required this.nameCtrl,
    required this.plannedCtrl,
    required this.installmentCurrentCtrl,
    required this.installmentTotalCtrl,
    required this.targetCtrl,
    required this.categoryTargetCtrl,
    required this.targetDate,
    required this.dateFmt,
    required this.onTargetDateChanged,
  });

  final AppLocalizations l10n;
  final BudgetCategory? category;
  final bool isPot;
  final bool isDebt;
  final TextEditingController nameCtrl;
  final TextEditingController plannedCtrl;
  final TextEditingController installmentCurrentCtrl;
  final TextEditingController installmentTotalCtrl;
  final TextEditingController targetCtrl;
  final TextEditingController categoryTargetCtrl;
  final DateTime? targetDate;
  final DateFormat dateFmt;
  final ValueChanged<DateTime?> onTargetDateChanged;

  @override
  Widget build(BuildContext context) {
    return DetailInfoCard(
      children: [
        if (category != null &&
            (category!.isSavings || category!.targetAmount != null)) ...[
          TextField(
            controller: categoryTargetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.targetAmount),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.subcategoryName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: plannedCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.plannedLabel),
        ),
        if (isDebt) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: installmentCurrentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.installmentCurrent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: installmentTotalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.installmentTotal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.installmentHelper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
        ],
        if (isPot) ...[
          const SizedBox(height: 12),
          TextField(
            controller: targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.targetAmount),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.targetDate),
            subtitle: Text(
              targetDate == null ? '—' : dateFmt.format(targetDate!),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: targetDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 5),
                ),
                lastDate: DateTime.now().add(
                  const Duration(days: 365 * 30),
                ),
              );
              if (picked == null) return;
              onTargetDateChanged(picked);
            },
          ),
        ],
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.isPot,
    required this.isDebt,
    required this.dateFmt,
    this.onTap,
  });

  final Expense expense;
  final bool isPot;
  final bool isDebt;
  final DateFormat dateFmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final note = expense.note?.trim();
    final amountColor = isPot
        ? SyncColors.primary
        : isDebt
            ? SyncColors.warning
            : SyncColors.accent;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note == null || note.isEmpty ? '—' : note,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(expense.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SyncColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Text(
            formatIls(expense.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: SyncColors.textMuted.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: SyncColors.frostedSurface,
      borderRadius: BorderRadius.circular(14),
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: content,
            ),
    );
  }
}

Future<void> showSubcategoryRegisterSheet(
  BuildContext context, {
  required Subcategory subcategory,
}) {
  return pushAdaptivePage(
    context,
    SubcategoryDetailScreen(subcategoryId: subcategory.id),
  );
}
