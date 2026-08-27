import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../navigation/adaptive_page_route.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/form_sheet.dart';
import '../../widgets/sync_app_bar.dart';

/// Full-screen create-month flow. Catalog lives on the household, so this
/// only picks a month and copies the previous plan when one exists.
Future<void> openCreateMonthFlow(BuildContext context) async {
  await pushAdaptivePage<void>(context, const CreateMonthFlowScreen());
}

class CreateMonthFlowScreen extends StatefulWidget {
  const CreateMonthFlowScreen({super.key});

  @override
  State<CreateMonthFlowScreen> createState() => _CreateMonthFlowScreenState();
}

class _CreateMonthFlowScreenState extends State<CreateMonthFlowScreen> {
  late int _year;
  late int _month;
  var _step = 0;
  var _saving = false;
  String? _copyFromId;
  var _empty = false;
  var _rollover = false;
  final Set<String> _selectedCategoryIds = {};
  var _categoriesInitialized = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      final suggested = suggestedNewMonthDate(
        state.months.map((m) => m.id),
      );
      setState(() {
        _year = suggested.year;
        _month = suggested.month;
        if (state.months.isNotEmpty) {
          final sorted = state.months.map((m) => m.id).toList()..sort();
          _copyFromId = sorted.last;
        }
        _initCategorySelection(state.categories);
      });
    });
  }

  void _initCategorySelection(List<BudgetCategory> categories) {
    if (_categoriesInitialized || categories.isEmpty) return;
    _selectedCategoryIds
      ..clear()
      ..addAll(categories.map((c) => c.id));
    _categoriesInitialized = true;
  }

  String get _selectedMonthId => monthIdFromDate(DateTime(_year, _month));

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.maybePop(context);
    }
  }

  DropdownMenuItem<int> _monthMenuItem(
    AppLocalizations l10n,
    Set<String> existingIds,
    int month,
  ) {
    final exists =
        existingIds.contains(monthIdFromDate(DateTime(_year, month)));
    final title = l10n.monthTitle(DateTime(_year, month));
    return DropdownMenuItem(
      value: month,
      enabled: !exists,
      child: Text(exists ? '$title (${l10n.monthAlreadyAdded})' : title),
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final monthId = _selectedMonthId;
    if (state.months.any((m) => m.id == monthId)) return;
    setState(() => _saving = true);
    try {
      final copyFrom = _empty ? null : _copyFromId;
      await state.createMonth(
        monthId: monthId,
        copyFromMonthId: copyFrom,
        empty: copyFrom == null,
        rolloverLeftover: _rollover,
        categoryIdsToCopy: copyFrom == null ? null : {..._selectedCategoryIds},
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.monthCreated}: $monthId')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  void _onPrimaryAction({
    required bool isLastStep,
    required bool monthAlreadyExists,
  }) {
    if (_saving || monthAlreadyExists) return;
    if (isLastStep) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final existingIds = {for (final m in state.months) m.id};
    final monthId = _selectedMonthId;
    final alreadyExists = existingIds.contains(monthId);
    final copyCandidates =
        state.months.where((m) => m.id != monthId).toList();
    final categories = state.categories;
    final showLeftoverStep = existingIds.isNotEmpty;
    final showCopyStep = copyCandidates.isNotEmpty;
    final totalSteps =
        1 + (showLeftoverStep ? 1 : 0) + (showCopyStep ? 1 : 0);
    final isLastStep = _step >= totalSteps - 1;
    final selectedDate = DateTime(_year, _month);
    final copyStepIndex = showLeftoverStep ? 2 : 1;
    final leftoverStepIndex = 1;

    if (!_categoriesInitialized && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _categoriesInitialized) return;
        setState(() => _initCategorySelection(categories));
      });
    }

    if (_step >= totalSteps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _step = totalSteps - 1);
      });
    }

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
                  _StepProgress(current: _step, total: totalSteps),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: switch (_step) {
                        0 => _PickMonthStep(
                            l10n: l10n,
                            now: now,
                            year: _year,
                            month: _month,
                            selectedDate: selectedDate,
                            alreadyExists: alreadyExists,
                            existingIds: existingIds,
                            monthMenuItem: _monthMenuItem,
                            onYearChanged: (year) =>
                                setState(() => _year = year),
                            onMonthChanged: (month) =>
                                setState(() => _month = month),
                          ),
                        _ when showLeftoverStep && _step == leftoverStepIndex =>
                          _LeftoverStep(
                            l10n: l10n,
                            rollover: _rollover,
                            onRolloverChanged: (rollover) =>
                                setState(() => _rollover = rollover),
                          ),
                        _ when showCopyStep && _step == copyStepIndex =>
                          _CopyPlanStep(
                            l10n: l10n,
                            state: state,
                            empty: _empty,
                            copyFromId: _copyFromId,
                            copyCandidates: copyCandidates,
                            categories: categories,
                            selectedCategoryIds: _selectedCategoryIds,
                            onEmptyChanged: (empty) =>
                                setState(() => _empty = empty),
                            onCopyFromChanged: (id) =>
                                setState(() => _copyFromId = id),
                            onCategoryToggled: (catId, selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategoryIds.add(catId);
                                } else {
                                  _selectedCategoryIds.remove(catId);
                                }
                              });
                            },
                            onSelectAll: () => setState(() {
                              _selectedCategoryIds
                                ..clear()
                                ..addAll(categories.map((c) => c.id));
                            }),
                            onSelectNone: () =>
                                setState(_selectedCategoryIds.clear),
                          ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving || alreadyExists
                        ? null
                        : () => _onPrimaryAction(
                              isLastStep: isLastStep,
                              monthAlreadyExists: alreadyExists,
                            ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastStep ? l10n.done : l10n.continueLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                color: i <= current
                    ? SyncColors.primary
                    : SyncColors.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          size: 64,
          color: SyncColors.primary.withValues(alpha: 0.85),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SyncColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}

class _PickMonthStep extends StatelessWidget {
  const _PickMonthStep({
    required this.l10n,
    required this.now,
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.alreadyExists,
    required this.existingIds,
    required this.monthMenuItem,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  final AppLocalizations l10n;
  final DateTime now;
  final int year;
  final int month;
  final DateTime selectedDate;
  final bool alreadyExists;
  final Set<String> existingIds;
  final DropdownMenuItem<int> Function(AppLocalizations, Set<String>, int)
      monthMenuItem;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OnboardingHeader(
          icon: Icons.calendar_month_outlined,
          title: l10n.createThisMonth,
          subtitle: l10n.howAreWeDoing,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.monthTitle(selectedDate),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: year,
          decoration: InputDecoration(labelText: l10n.yearLabel),
          items: [
            for (var y = now.year - 1; y <= now.year + 2; y++)
              DropdownMenuItem(value: y, child: Text('$y')),
          ],
          onChanged: (v) {
            if (v == null) return;
            onYearChanged(v);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey(year),
          initialValue: month,
          decoration: InputDecoration(labelText: l10n.monthLabel),
          items: [
            for (var m = 1; m <= 12; m++)
              monthMenuItem(l10n, existingIds, m),
          ],
          onChanged: (v) {
            if (v == null) return;
            onMonthChanged(v);
          },
        ),
        if (alreadyExists) ...[
          const SizedBox(height: 16),
          Text(
            l10n.monthAlreadyAdded,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _CopyPlanStep extends StatelessWidget {
  const _CopyPlanStep({
    required this.l10n,
    required this.state,
    required this.empty,
    required this.copyFromId,
    required this.copyCandidates,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onEmptyChanged,
    required this.onCopyFromChanged,
    required this.onCategoryToggled,
    required this.onSelectAll,
    required this.onSelectNone,
  });

  final AppLocalizations l10n;
  final AppState state;
  final bool empty;
  final String? copyFromId;
  final List<BudgetMonth> copyCandidates;
  final List<BudgetCategory> categories;
  final Set<String> selectedCategoryIds;
  final ValueChanged<bool> onEmptyChanged;
  final ValueChanged<String?> onCopyFromChanged;
  final void Function(String catId, bool selected) onCategoryToggled;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OnboardingHeader(
          icon: Icons.auto_awesome_motion_outlined,
          title: l10n.stepCategoriesOrCopy,
        ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.createEmptyMonth)),
            ButtonSegment(value: false, label: Text(l10n.copyFromPrevious)),
          ],
          selected: {empty},
          onSelectionChanged: (selection) => onEmptyChanged(selection.first),
        ),
        if (!empty) ...[
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: copyCandidates.any((m) => m.id == copyFromId)
                ? copyFromId
                : copyCandidates.first.id,
            decoration: InputDecoration(labelText: l10n.selectMonthToCopy),
            items: [
              for (final m in copyCandidates)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(l10n.monthTitle(dateFromMonthId(m.id))),
                ),
            ],
            onChanged: onCopyFromChanged,
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.selectCategories,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.copyPlanOnly,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SyncColors.textMuted,
                  ),
            ),
            Row(
              children: [
                TextButton(onPressed: onSelectAll, child: Text(l10n.selectAll)),
                TextButton(onPressed: onSelectNone, child: Text(l10n.selectNone)),
              ],
            ),
            for (final cat in categories)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  secondary: CategoryColorIcon(
                    colorValue: cat.colorValue,
                    iconKey: cat.iconKey,
                    size: 28,
                  ),
                  title: Text(cat.localizedName(state.localeCode)),
                  value: selectedCategoryIds.contains(cat.id),
                  onChanged: (v) => onCategoryToggled(cat.id, v ?? false),
                ),
              ),
          ],
        ],
      ],
    );
  }
}

class _LeftoverStep extends StatelessWidget {
  const _LeftoverStep({
    required this.l10n,
    required this.rollover,
    required this.onRolloverChanged,
  });

  final AppLocalizations l10n;
  final bool rollover;
  final ValueChanged<bool> onRolloverChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OnboardingHeader(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.rolloverLeftover,
          subtitle: l10n.leftoverPotHint,
        ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(l10n.leftoverToggleOff),
            ),
            ButtonSegment(
              value: true,
              label: Text(l10n.leftoverToggleOn),
            ),
          ],
          selected: {rollover},
          onSelectionChanged: (selection) =>
              onRolloverChanged(selection.first),
        ),
      ],
    );
  }
}

Future<void> showSelectMonthSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final months = List<BudgetMonth>.from(state.months);
  final currentId = state.monthId;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetMaxHeight(ctx)),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(l10n.selectMonth)),
              if (months.isEmpty)
                ListTile(title: Text(l10n.emptyMonths))
              else
                ...months.map(
                  (m) => ListTile(
                    title: Text(l10n.monthTitle(dateFromMonthId(m.id))),
                    trailing:
                        m.id == currentId ? const Icon(Icons.check) : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await state.setMonth(m.id);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    },
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.addMonth),
                onTap: () {
                  Navigator.pop(ctx);
                  openCreateMonthFlow(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Back-compat alias used by settings and older call sites.
Future<void> showCreateMonthDialog(BuildContext context) =>
    openCreateMonthFlow(context);
