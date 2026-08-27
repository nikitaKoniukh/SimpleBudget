import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../navigation/adaptive_page_route.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/text_format.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/onboarding_flow.dart';
import '../../widgets/sync_app_bar.dart';
import '../category/budget_sheets.dart';
import '../income/income_dialogs.dart';

enum LogKind { spend, save, income, monthly, debt }

enum _LogFlowStep { type, category, subcategory, details }

class LogEntryFlowScreen extends StatefulWidget {
  const LogEntryFlowScreen({
    super.key,
    this.kind,
    this.expense,
    this.incomeEntry,
    this.subcategoryId,
    this.incomeSourceId,
  });

  final LogKind? kind;
  final Expense? expense;
  final IncomeEntry? incomeEntry;
  final String? subcategoryId;
  final String? incomeSourceId;

  @override
  State<LogEntryFlowScreen> createState() => _LogEntryFlowScreenState();
}

class _LogEntryFlowScreenState extends State<LogEntryFlowScreen> {
  late LogKind _selectedKind;
  late bool _editing;
  String? _pinnedSubId;
  String? _selectedSubId;
  String? _selectedCategoryId;
  String? _selectedSourceId;
  var _step = 0;
  var _saving = false;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _date;
  var _billDay = DateTime.now().day.clamp(1, 28);

  bool _skipWhereStepFor(AppState state) {
    if (_editing) return false;
    if (_pinnedSubId == null) return false;
    final pinned = state.subcategoryById(_pinnedSubId!);
    if (pinned == null) return false;
    return _subMatchesKind(state, pinned, _selectedKind);
  }

  bool _needsCategoryStep(LogKind kind) =>
      kind == LogKind.spend ||
      kind == LogKind.monthly ||
      kind == LogKind.debt;

  List<_LogFlowStep> _stepsFor(AppState state) {
    final steps = <_LogFlowStep>[];
    if (!_editing && !_skipWhereStepFor(state)) {
      steps.add(_LogFlowStep.type);
    }
    if (!_skipWhereStepFor(state)) {
      if (_needsCategoryStep(_selectedKind)) {
        steps.add(_LogFlowStep.category);
      }
      steps.add(_LogFlowStep.subcategory);
    }
    steps.add(_LogFlowStep.details);
    return steps;
  }

  @override
  void initState() {
    super.initState();
    _editing = widget.expense != null || widget.incomeEntry != null;
    final state = context.read<AppState>();
    _pinnedSubId = widget.expense?.subcategoryId ?? widget.subcategoryId;

    var initialKind = widget.kind ??
        (widget.incomeEntry != null
            ? LogKind.income
            : (widget.expense != null && state.isDepositExpense(widget.expense!)
                ? LogKind.save
                : LogKind.spend));

    if (widget.incomeEntry == null) {
      final subId = widget.expense?.subcategoryId ?? widget.subcategoryId;
      if (widget.expense != null && state.isDepositExpense(widget.expense!)) {
        initialKind = LogKind.save;
      } else if (subId != null) {
        final fromCat = kindForSubcategory(state, subId);
        if (fromCat != null) initialKind = fromCat;
      }
    }

    _selectedKind = initialKind;
    _selectedSubId = _pinnedSubId ?? defaultSubForKind(state, initialKind);
    _selectedCategoryId =
        state.subcategoryById(_selectedSubId ?? '')?.categoryId ??
            catsForKind(state, initialKind).firstOrNull?.id;
    _selectedSourceId = widget.incomeEntry?.sourceId ??
        widget.incomeSourceId ??
        state.incomeSources.firstOrNull?.id;

    _amountCtrl = TextEditingController(
      text: widget.expense != null
          ? widget.expense!.amount.toStringAsFixed(2)
          : widget.incomeEntry != null
              ? widget.incomeEntry!.amount.toStringAsFixed(2)
              : '',
    );
    _noteCtrl = TextEditingController(
      text: widget.expense?.note ?? widget.incomeEntry?.note ?? '',
    );
    _date = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.maybePop(context);
    }
  }

  void _syncSelections(AppState state) {
    final kindCats = catsForKind(state, _selectedKind);
    final savingsCat = state.savingsCategory;
    final pots = savingsCat == null
        ? const <Subcategory>[]
        : state.subcategoriesForMonth(savingsCat.id);

    if (_selectedKind == LogKind.save) {
      if (_selectedSubId != null && !pots.any((s) => s.id == _selectedSubId)) {
        _selectedSubId = pots.firstOrNull?.id;
      }
    } else if (_selectedKind != LogKind.income) {
      final pinnedSub =
          _pinnedSubId == null ? null : state.subcategoryById(_pinnedSubId!);
      final pinnedMatchesKind = pinnedSub != null &&
          _subMatchesKind(state, pinnedSub, _selectedKind);
      if (pinnedMatchesKind && !_editing) {
        _selectedCategoryId = pinnedSub.categoryId;
        _selectedSubId = pinnedSub.id;
      } else {
        if (_selectedCategoryId != null &&
            !kindCats.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = kindCats.firstOrNull?.id;
        }
        _selectedCategoryId ??= kindCats.firstOrNull?.id;
        final catSubs = _selectedCategoryId == null
            ? const <Subcategory>[]
            : state.subcategoriesForMonth(_selectedCategoryId!);
        if (_selectedSubId != null &&
            !catSubs.any((s) => s.id == _selectedSubId)) {
          _selectedSubId = catSubs.firstOrNull?.id;
        }
        _selectedSubId ??= catSubs.firstOrNull?.id;
      }
    }

    if (_selectedKind == LogKind.income) {
      final sources = state.incomeSources;
      if (_selectedSourceId != null &&
          !sources.any((s) => s.id == _selectedSourceId)) {
        _selectedSourceId = sources.firstOrNull?.id;
      }
      _selectedSourceId ??= sources.firstOrNull?.id;
    }
  }

  bool _canContinue(AppState state, _LogFlowStep stepKind) {
    return switch (stepKind) {
      _LogFlowStep.type => true,
      _LogFlowStep.category => _selectedCategoryId != null,
      _LogFlowStep.subcategory => switch (_selectedKind) {
          LogKind.spend ||
          LogKind.save ||
          LogKind.monthly ||
          LogKind.debt =>
            _selectedSubId != null,
          LogKind.income => _selectedSourceId != null,
        },
      _LogFlowStep.details =>
        (double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0) > 0,
    };
  }

  Future<void> _onPrimaryAction(
    AppState state,
    AppLocalizations l10n,
    _LogFlowStep stepKind,
    List<_LogFlowStep> steps,
  ) async {
    if (_saving || !_canContinue(state, stepKind)) return;

    if (stepKind == _LogFlowStep.type &&
        _selectedKind == LogKind.income &&
        state.incomeSources.isEmpty) {
      final id = await showAddIncomeSourceDialog(context);
      if (!mounted) return;
      if (id == null && state.incomeSources.isEmpty) return;
      setState(() => _selectedSourceId = id ?? state.incomeSources.firstOrNull?.id);
    }

    if (stepKind == _LogFlowStep.subcategory &&
        _selectedKind == LogKind.income &&
        state.incomeSources.isEmpty) {
      final id = await showAddIncomeSourceDialog(context);
      if (!mounted) return;
      if (id == null && state.incomeSources.isEmpty) return;
      setState(() => _selectedSourceId = id ?? state.incomeSources.firstOrNull?.id);
    }

    if (_step < steps.length - 1) {
      setState(() => _step++);
      return;
    }
    await _save(state, l10n);
  }

  Future<void> _save(AppState state, AppLocalizations l10n) async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);
    try {
      final note = sentenceCase(_noteCtrl.text);
      final noteOrNull = note.isEmpty ? null : note;

      switch (_selectedKind) {
        case LogKind.spend:
        case LogKind.debt:
          final subId = _selectedSubId;
          if (subId == null) return;
          if (widget.expense == null) {
            await state.addExpense(
              subcategoryId: subId,
              amount: amount,
              date: _date,
              note: noteOrNull,
            );
          } else {
            await state.updateExpense(
              Expense(
                id: widget.expense!.id,
                subcategoryId: subId,
                amount: amount,
                date: _date,
                note: noteOrNull,
                createdAt: widget.expense!.createdAt,
                createdBy: widget.expense!.createdBy,
                createdByName: widget.expense!.createdByName,
                isDeposit: false,
              ),
            );
          }
        case LogKind.save:
          final subId = _selectedSubId;
          if (subId == null) return;
          if (widget.expense == null) {
            await state.addDeposit(
              subcategoryId: subId,
              amount: amount,
              date: _date,
              note: noteOrNull,
            );
          } else {
            await state.updateExpense(
              Expense(
                id: widget.expense!.id,
                subcategoryId: subId,
                amount: amount,
                date: _date,
                note: noteOrNull,
                createdAt: widget.expense!.createdAt,
                createdBy: widget.expense!.createdBy,
                createdByName: widget.expense!.createdByName,
                isDeposit: true,
              ),
            );
          }
        case LogKind.income:
          final sourceId = _selectedSourceId;
          if (sourceId == null) return;
          if (widget.incomeEntry == null) {
            await state.addIncomeEntry(
              sourceId: sourceId,
              amount: amount,
              note: noteOrNull,
            );
          } else {
            final hid = state.activeHouseholdId;
            final monthId = state.monthId;
            if (hid == null || monthId == null) return;
            await state.repo.updateIncomeEntry(
              householdId: hid,
              monthId: monthId,
              entry: widget.incomeEntry!.copyWith(
                sourceId: sourceId,
                amount: amount,
                note: noteOrNull,
              ),
            );
          }
        case LogKind.monthly:
          final subId = _selectedSubId;
          if (subId == null) return;
          if (!state.canEditPlan) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.viewerReadOnlyPlan)),
              );
            }
            return;
          }
          final sub = state.subcategoryById(subId);
          final billName = noteOrNull ??
              (sub != null ? state.localizedSubcategoryName(sub) : null) ??
              l10n.logFixed;
          await state.addRecurringBill(
            name: billName,
            amount: amount,
            dayOfMonth: _billDay,
            subcategoryId: subId,
          );
          await state.upsertPlan(subcategoryId: subId, planned: amount);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(AppState state) async {
    if (widget.expense != null) {
      await state.deleteExpense(widget.expense!.id);
    } else if (widget.incomeEntry != null) {
      final hid = state.activeHouseholdId;
      final monthId = state.monthId;
      if (hid != null && monthId != null) {
        await state.repo.deleteIncomeEntry(
          householdId: hid,
          monthId: monthId,
          entryId: widget.incomeEntry!.id,
        );
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    _syncSelections(state);

    final steps = _stepsFor(state);
    if (_step >= steps.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _step = steps.length - 1);
      });
    }
    final currentStepKind = steps[_step.clamp(0, steps.length - 1)];
    final isLastStep = _step >= steps.length - 1;
    final primaryLabel = isLastStep ? l10n.save : l10n.continueLabel;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.flow(onBack: _goBack),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (steps.length > 1) ...[
                    FlowStepProgress(current: _step, total: steps.length),
                    const SizedBox(height: 20),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      child: switch (currentStepKind) {
                        _LogFlowStep.type => _LogTypeStep(
                            l10n: l10n,
                            selectedKind: _selectedKind,
                            onKindSelected: (kind) {
                              setState(() {
                                _selectedKind = kind;
                                _selectedSubId =
                                    defaultSubForKind(state, kind);
                                _selectedCategoryId = state
                                        .subcategoryById(_selectedSubId ?? '')
                                        ?.categoryId ??
                                    catsForKind(state, kind).firstOrNull?.id;
                                _selectedSourceId =
                                    state.incomeSources.firstOrNull?.id;
                              });
                            },
                          ),
                        _LogFlowStep.category => _LogCategoryStep(
                            l10n: l10n,
                            state: state,
                            kind: _selectedKind,
                            selectedCategoryId: _selectedCategoryId,
                            onCategoryChanged: (id) => setState(() {
                              _selectedCategoryId = id;
                              _selectedSubId = state
                                  .subcategoriesForMonth(id)
                                  .firstOrNull
                                  ?.id;
                            }),
                            onSubCreated: (id) =>
                                setState(() => _selectedSubId = id),
                          ),
                        _LogFlowStep.subcategory => _LogSubcategoryStep(
                            l10n: l10n,
                            state: state,
                            kind: _selectedKind,
                            selectedCategoryId: _selectedCategoryId,
                            selectedSubId: _selectedSubId,
                            selectedSourceId: _selectedSourceId,
                            billDay: _billDay,
                            editing: _editing,
                            onSubChanged: (id) =>
                                setState(() => _selectedSubId = id),
                            onSourceChanged: (id) =>
                                setState(() => _selectedSourceId = id),
                            onBillDayChanged: (day) =>
                                setState(() => _billDay = day),
                          ),
                        _LogFlowStep.details => _LogDetailsStep(
                            l10n: l10n,
                            kind: _selectedKind,
                            amountCtrl: _amountCtrl,
                            noteCtrl: _noteCtrl,
                            date: _date,
                            onDateChanged: (d) => setState(() => _date = d),
                            autofocusAmount: !_editing,
                          ),
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving || !_canContinue(state, currentStepKind)
                        ? null
                        : () => _onPrimaryAction(state, l10n, currentStepKind, steps),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(primaryLabel),
                  ),
                  if (_editing && isLastStep) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : () => _delete(state),
                      child: Text(
                        _selectedKind == LogKind.income
                            ? l10n.deleteIncome
                            : l10n.delete,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogTypeStep extends StatelessWidget {
  const _LogTypeStep({
    required this.l10n,
    required this.selectedKind,
    required this.onKindSelected,
  });

  final AppLocalizations l10n;
  final LogKind selectedKind;
  final ValueChanged<LogKind> onKindSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowOnboardingHeader(
          icon: Icons.receipt_long_outlined,
          title: l10n.log,
          subtitle: l10n.quickLog,
        ),
        for (final kind in LogKind.values)
          FlowOptionCard(
            icon: iconForLogKind(kind),
            title: kindLabel(l10n, kind),
            selected: selectedKind == kind,
            onTap: () => onKindSelected(kind),
          ),
      ],
    );
  }
}

class _LogCategoryStep extends StatelessWidget {
  const _LogCategoryStep({
    required this.l10n,
    required this.state,
    required this.kind,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onSubCreated,
  });

  final AppLocalizations l10n;
  final AppState state;
  final LogKind kind;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSubCreated;

  @override
  Widget build(BuildContext context) {
    final kindCats = catsForKind(state, kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowOnboardingHeader(
          icon: Icons.folder_open_outlined,
          title: l10n.category,
          subtitle: kindLabel(l10n, kind),
        ),
        if (kindCats.isEmpty)
          _EmptyPicker(
            message: l10n.noSubcategories,
            actions: [
              OutlinedButton.icon(
                onPressed: () async {
                  final id = await addCategoryAndSubcategory(context);
                  if (id == null || !context.mounted) return;
                  final catId =
                      context.read<AppState>().subcategoryById(id)?.categoryId;
                  if (catId != null) onCategoryChanged(catId);
                  onSubCreated(id);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addCategory),
              ),
            ],
          )
        else
          for (final cat in kindCats)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selectedCategoryId == cat.id
                      ? SyncColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: CategoryColorIcon(
                  colorValue: cat.colorValue,
                  iconKey: cat.iconKey,
                  size: 28,
                ),
                title: Text(cat.localizedName(state.localeCode)),
                trailing: selectedCategoryId == cat.id
                    ? Icon(Icons.check_circle, color: SyncColors.primary)
                    : null,
                onTap: () => onCategoryChanged(cat.id),
              ),
            ),
      ],
    );
  }
}

class _LogSubcategoryStep extends StatelessWidget {
  const _LogSubcategoryStep({
    required this.l10n,
    required this.state,
    required this.kind,
    required this.selectedCategoryId,
    required this.selectedSubId,
    required this.selectedSourceId,
    required this.billDay,
    required this.editing,
    required this.onSubChanged,
    required this.onSourceChanged,
    required this.onBillDayChanged,
  });

  final AppLocalizations l10n;
  final AppState state;
  final LogKind kind;
  final String? selectedCategoryId;
  final String? selectedSubId;
  final String? selectedSourceId;
  final int billDay;
  final bool editing;
  final ValueChanged<String> onSubChanged;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<int> onBillDayChanged;

  @override
  Widget build(BuildContext context) {
    final savingsCat = state.savingsCategory;
    var pots = savingsCat == null
        ? const <Subcategory>[]
        : state.subcategoriesForMonth(savingsCat.id);
    if (editing &&
        selectedSubId != null &&
        !pots.any((s) => s.id == selectedSubId)) {
      final pinned = state.subcategoryById(selectedSubId!);
      if (pinned != null) pots = [...pots, pinned];
    }

    var catSubs = selectedCategoryId == null
        ? const <Subcategory>[]
        : state.subcategoriesForMonth(selectedCategoryId!);
    if (editing && selectedSubId != null) {
      final sub = state.subcategoryById(selectedSubId!);
      if (sub != null &&
          sub.categoryId == selectedCategoryId &&
          !catSubs.any((s) => s.id == sub.id)) {
        catSubs = [...catSubs, sub];
      }
    }

    final sources = state.incomeSources;
    final categoryName = selectedCategoryId == null
        ? null
        : state
            .categoryById(selectedCategoryId!)
            ?.localizedName(state.localeCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowOnboardingHeader(
          icon: switch (kind) {
            LogKind.save => Icons.savings_outlined,
            LogKind.income => Icons.payments_outlined,
            _ => Icons.bookmark_outline,
          },
          title: switch (kind) {
            LogKind.save => l10n.sectionSavings,
            LogKind.income => l10n.income,
            _ => l10n.subcategory,
          },
          subtitle: switch (kind) {
            LogKind.income || LogKind.save => kindLabel(l10n, kind),
            _ => categoryName,
          },
        ),
        if (kind == LogKind.spend ||
            kind == LogKind.monthly ||
            kind == LogKind.debt)
          ..._subcategoryPicker(context, catSubs: catSubs)
        else if (kind == LogKind.save)
          ..._potPicker(context, pots: pots)
        else if (kind == LogKind.income)
          ..._incomePicker(context, sources: sources),
        if (kind == LogKind.monthly) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: billDay,
            decoration: InputDecoration(labelText: l10n.billDay),
            items: [
              for (var d = 1; d <= 28; d++)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (v) {
              if (v != null) onBillDayChanged(v);
            },
          ),
          Text(
            l10n.logFixedHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SyncColors.textMuted,
                ),
          ),
        ],
      ],
    );
  }

  List<Widget> _subcategoryPicker(
    BuildContext context, {
    required List<Subcategory> catSubs,
  }) {
    if (catSubs.isEmpty) {
      return [
        _EmptyPicker(
          message: l10n.noSubcategories,
          actions: [
            OutlinedButton.icon(
              onPressed: selectedCategoryId == null
                  ? null
                  : () async {
                      final id = await showAddSubcategorySheet(
                        context,
                        categoryId: selectedCategoryId!,
                      );
                      if (id != null) onSubChanged(id);
                    },
              icon: const Icon(Icons.add),
              label: Text(l10n.addSubcategory),
            ),
          ],
        ),
      ];
    }

    return [
      for (final sub in catSubs)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selectedSubId == sub.id
                  ? SyncColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: CategoryColorIcon(
              colorValue: state.categoryById(sub.categoryId)?.colorValue ?? 0,
              iconKey: state.categoryById(sub.categoryId)?.iconKey ?? '',
              size: 28,
            ),
            title: Text(state.localizedSubcategoryName(sub)),
            trailing: selectedSubId == sub.id
                ? Icon(Icons.check_circle, color: SyncColors.primary)
                : null,
            onTap: () => onSubChanged(sub.id),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: selectedCategoryId == null
              ? null
              : () async {
                  final id = await showAddSubcategorySheet(
                    context,
                    categoryId: selectedCategoryId!,
                  );
                  if (id != null) onSubChanged(id);
                },
          icon: const Icon(Icons.add),
          label: Text(l10n.addSubcategory),
        ),
      ),
    ];
  }

  List<Widget> _potPicker(BuildContext context, {required List<Subcategory> pots}) {
    if (pots.isEmpty) {
      return [
        _EmptyPicker(
          message: l10n.emptyPots,
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                final id = await promptAddPot(context);
                if (id != null) onSubChanged(id);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addPot),
            ),
          ],
        ),
      ];
    }

    return [
      for (final sub in pots)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selectedSubId == sub.id
                  ? SyncColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: CategoryColorIcon(
              colorValue: state.categoryById(sub.categoryId)?.colorValue ?? 0,
              iconKey: state.categoryById(sub.categoryId)?.iconKey ?? '',
              size: 28,
            ),
            title: Text(state.localizedSubcategoryName(sub)),
            trailing: selectedSubId == sub.id
                ? Icon(Icons.check_circle, color: SyncColors.primary)
                : null,
            onTap: () => onSubChanged(sub.id),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () async {
            final id = await promptAddPot(context);
            if (id != null) onSubChanged(id);
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addPot),
        ),
      ),
    ];
  }

  List<Widget> _incomePicker(
    BuildContext context, {
    required List<IncomeSource> sources,
  }) {
    if (sources.isEmpty) {
      return [
        _EmptyPicker(
          message: l10n.emptyIncome,
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                final id = await showAddIncomeSourceDialog(context);
                if (id != null) onSourceChanged(id);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addIncomeSource),
            ),
          ],
        ),
      ];
    }

    return [
      for (final source in sources)
        FlowOptionCard(
          icon: Icons.payments_outlined,
          title: source.localizedName(state.localeCode),
          selected: selectedSourceId == source.id,
          onTap: () => onSourceChanged(source.id),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () async {
            final id = await showAddIncomeSourceDialog(context);
            if (id != null) onSourceChanged(id);
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addIncomeSource),
        ),
      ),
    ];
  }
}

class _LogDetailsStep extends StatelessWidget {
  const _LogDetailsStep({
    required this.l10n,
    required this.kind,
    required this.amountCtrl,
    required this.noteCtrl,
    required this.date,
    required this.onDateChanged,
    required this.autofocusAmount,
  });

  final AppLocalizations l10n;
  final LogKind kind;
  final TextEditingController amountCtrl;
  final TextEditingController noteCtrl;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final bool autofocusAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowOnboardingHeader(
          icon: Icons.payments_outlined,
          title: l10n.amount,
        ),
        TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: autofocusAmount,
          decoration: InputDecoration(
            labelText: switch (kind) {
              LogKind.spend => l10n.amountSpend,
              LogKind.save => l10n.amountSave,
              LogKind.income => l10n.amountIncome,
              LogKind.monthly => l10n.amountMonthly,
              LogKind.debt => l10n.amountDebt,
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: kind == LogKind.monthly ? l10n.description : l10n.note,
          ),
        ),
        if (kind == LogKind.spend ||
            kind == LogKind.save ||
            kind == LogKind.debt) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(l10n.date),
              subtitle: Text(DateFormat.yMMMd().format(date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(date.year - 2),
                  lastDate: DateTime(date.year + 2),
                );
                if (picked != null) onDateChanged(picked);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({required this.message, required this.actions});

  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}

IconData iconForLogKind(LogKind kind) {
  return switch (kind) {
    LogKind.spend => Icons.receipt_long_outlined,
    LogKind.save => Icons.savings_outlined,
    LogKind.income => Icons.payments_outlined,
    LogKind.monthly => Icons.event_repeat_outlined,
    LogKind.debt => Icons.credit_card_outlined,
  };
}

String kindLabel(AppLocalizations l10n, LogKind kind) {
  return switch (kind) {
    LogKind.spend => l10n.logSpend,
    LogKind.save => l10n.logSave,
    LogKind.income => l10n.income,
    LogKind.monthly => l10n.logFixed,
    LogKind.debt => l10n.logDebt,
  };
}

LogKind? kindForSubcategory(AppState state, String subcategoryId) {
  final cat = state.categoryById(
    state.subcategoryById(subcategoryId)?.categoryId ?? '',
  );
  if (cat == null) return null;
  if (cat.isDebt) return LogKind.debt;
  if (cat.isSavings) return LogKind.save;
  if (cat.isSpend || cat.isMonthly) return LogKind.spend;
  return null;
}

bool _subMatchesKind(AppState state, Subcategory sub, LogKind kind) {
  final cat = state.categoryById(sub.categoryId);
  return switch (kind) {
    LogKind.spend => cat?.isSpend == true || cat?.isMonthly == true,
    LogKind.monthly => cat?.isMonthly ?? false,
    LogKind.debt => cat?.isDebt ?? false,
    LogKind.save => cat?.isSavings ?? false,
    LogKind.income => false,
  };
}

List<BudgetCategory> catsForKind(AppState state, LogKind kind) {
  return switch (kind) {
    LogKind.spend => [
        ...state.categoriesOfType('spend'),
        ...state.categoriesOfType('monthly'),
      ],
    LogKind.monthly => state.categoriesOfType('monthly'),
    LogKind.debt => state.categoriesOfType('debt'),
    LogKind.save || LogKind.income => const [],
  };
}

List<Subcategory> subsForKind(AppState state, LogKind kind) {
  return switch (kind) {
    LogKind.spend => [
        ...state.subcategoriesOfType('spend'),
        ...state.subcategoriesOfType('monthly'),
      ],
    LogKind.monthly => state.subcategoriesOfType('monthly'),
    LogKind.debt => state.subcategoriesOfType('debt'),
    LogKind.save => state.savingsPots,
    LogKind.income => const [],
  };
}

String? defaultSubForKind(AppState state, LogKind kind) {
  return subsForKind(state, kind).firstOrNull?.id;
}

Future<String?> promptAddPot(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final nameCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.addPot),
      content: TextField(
        controller: nameCtrl,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.subcategoryName),
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
  return context.read<AppState>().addPot(name: name);
}

Future<void> openLogEntryFlow(
  BuildContext context, {
  LogKind? kind,
  Expense? expense,
  IncomeEntry? incomeEntry,
  String? subcategoryId,
  String? incomeSourceId,
}) async {
  final state = context.read<AppState>();
  if (!state.hasMonthSelected) return;

  var initialKind = kind ??
      (incomeEntry != null
          ? LogKind.income
          : (expense != null && state.isDepositExpense(expense)
              ? LogKind.save
              : LogKind.spend));

  if (incomeEntry == null) {
    final subId = expense?.subcategoryId ?? subcategoryId;
    if (expense != null && state.isDepositExpense(expense)) {
      initialKind = LogKind.save;
    } else if (subId != null) {
      final fromCat = kindForSubcategory(state, subId);
      if (fromCat != null) initialKind = fromCat;
    }
  }

  final editing = expense != null || incomeEntry != null;
  if (initialKind == LogKind.income && !editing && state.incomeSources.isEmpty) {
    final created = await showAddIncomeSourceDialog(context);
    if (!context.mounted) return;
    if (created == null && state.incomeSources.isEmpty) return;
  }

  await pushAdaptivePage<void>(
    context,
    LogEntryFlowScreen(
      kind: kind,
      expense: expense,
      incomeEntry: incomeEntry,
      subcategoryId: subcategoryId,
      incomeSourceId: incomeSourceId,
    ),
  );
}
