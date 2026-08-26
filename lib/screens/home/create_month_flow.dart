import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/form_sheet.dart';

/// Full-screen create-month flow. Catalog lives on the household, so this
/// only picks a month and copies the previous plan when one exists.
Future<void> openCreateMonthFlow(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CreateMonthFlowScreen(),
    ),
  );
}

class CreateMonthFlowScreen extends StatefulWidget {
  const CreateMonthFlowScreen({super.key});

  @override
  State<CreateMonthFlowScreen> createState() => _CreateMonthFlowScreenState();
}

class _CreateMonthFlowScreenState extends State<CreateMonthFlowScreen> {
  late int _year;
  late int _month;
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
      setState(() {
        if (state.months.isNotEmpty) {
          _copyFromId = state.months.first.id;
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
        rolloverLeftover: copyFrom != null && _rollover,
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
    final willCopy = !_empty && copyCandidates.isNotEmpty;
    final categories = state.categories;
    if (!_categoriesInitialized && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _categoriesInitialized) return;
        setState(() => _initCategorySelection(categories));
      });
    }

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.stepPickMonth),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
              Text(
                l10n.createThisMonth,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                willCopy ? l10n.copyFromPrevious : l10n.howAreWeDoing,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
              if (copyCandidates.isNotEmpty) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.createEmptyMonth),
                  value: _empty,
                  onChanged: (v) => setState(() => _empty = v),
                ),
                if (!_empty)
                  DropdownButtonFormField<String>(
                    initialValue: copyCandidates.any((m) => m.id == _copyFromId)
                        ? _copyFromId
                        : copyCandidates.first.id,
                    decoration:
                        InputDecoration(labelText: l10n.selectMonthToCopy),
                    items: [
                      for (final m in copyCandidates)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(l10n.monthTitle(dateFromMonthId(m.id))),
                        ),
                    ],
                    onChanged: (v) => setState(() => _copyFromId = v),
                  ),
                if (!_empty)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.rolloverLeftover),
                    subtitle: Text(l10n.leftoverPotHint),
                    value: _rollover,
                    onChanged: (v) =>
                        setState(() => _rollover = v ?? false),
                  ),
                if (!_empty && categories.isNotEmpty) ...[
                  const SizedBox(height: 16),
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
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedCategoryIds
                            ..clear()
                            ..addAll(categories.map((c) => c.id));
                        }),
                        child: Text(l10n.selectAll),
                      ),
                      TextButton(
                        onPressed: () => setState(_selectedCategoryIds.clear),
                        child: Text(l10n.selectNone),
                      ),
                    ],
                  ),
                  for (final cat in categories)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: CategoryColorIcon(
                        colorValue: cat.colorValue,
                        iconKey: cat.iconKey,
                        size: 28,
                      ),
                      title: Text(cat.localizedName(state.localeCode)),
                      value: _selectedCategoryIds.contains(cat.id),
                      onChanged: (v) => setState(() {
                        if (v ?? false) {
                          _selectedCategoryIds.add(cat.id);
                        } else {
                          _selectedCategoryIds.remove(cat.id);
                        }
                      }),
                    ),
                ],
              ],
              const SizedBox(height: 28),
              Text(l10n.yearLabel),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _year,
                items: [
                  for (var y = now.year - 1; y <= now.year + 2; y++)
                    DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _year = v);
                },
              ),
              const SizedBox(height: 16),
              Text(l10n.monthLabel),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                key: ValueKey(_year),
                initialValue: _month,
                items: [
                  for (var m = 1; m <= 12; m++)
                    _monthMenuItem(l10n, existingIds, m),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _month = v);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving || alreadyExists ? null : _finish,
                child: Text(l10n.done),
              ),
            ],
          ),
        ),
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
