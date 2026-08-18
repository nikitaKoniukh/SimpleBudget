import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

/// Full-screen create-month flow (replaces dense AlertDialog).
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
  final _pageController = PageController();
  var _step = 0;
  late int _year;
  late int _month;
  var _useCopy = false;
  String? _copyFrom;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    // Categories stay unselected — user opts in via chips or copy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      setState(() {
        // Prefer empty month; copy only if user turns it on.
        _useCopy = false;
        _copyFrom = state.months.isNotEmpty ? state.months.first.id : null;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final monthId =
        '${_year.toString().padLeft(4, '0')}-${_month.toString().padLeft(2, '0')}';
    final chosen = DefaultCategories.all
        .where((c) => _selected.contains(c.nameEn))
        .toList();
    try {
      await state.createMonth(
        monthId: monthId,
        copyFromMonthId: _useCopy ? _copyFrom : null,
        selectedCategories: _useCopy ? const [] : chosen,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.monthCreated}: $monthId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  void _goNext() {
    if (_step == 0) {
      setState(() => _step = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final now = DateTime.now();

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_step == 0 ? l10n.stepPickMonth : l10n.stepCategoriesOrCopy),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.createThisMonth,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.howAreWeDoing,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SyncColors.textMuted,
                        ),
                  ),
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
                    initialValue: _month,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(l10n.monthTitle(DateTime(_year, m))),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _month = v);
                    },
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _goNext,
                    child: Text(l10n.continueLabel),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.months.isNotEmpty) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.copyFromPrevious),
                      value: _useCopy,
                      onChanged: (v) => setState(() => _useCopy = v),
                    ),
                    if (_useCopy)
                      DropdownButtonFormField<String>(
                        initialValue: _copyFrom,
                        decoration: InputDecoration(
                          labelText: l10n.selectMonthToCopy,
                        ),
                        items: state.months
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(
                                  l10n.monthTitle(dateFromMonthId(m.id)),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _copyFrom = v),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (!_useCopy) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.selectCategories,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _selected
                              ..clear()
                              ..addAll(
                                DefaultCategories.all.map((c) => c.nameEn),
                              );
                          }),
                          child: Text(l10n.selectAll),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selected.clear()),
                          child: Text(l10n.selectNone),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DefaultCategories.all.map((cat) {
                            final label = state.localeCode == 'ru'
                                ? cat.nameRu
                                : cat.nameEn;
                            final selected = _selected.contains(cat.nameEn);
                            return FilterChip(
                              selected: selected,
                              avatar: CircleAvatar(
                                backgroundColor: Color(cat.colorValue),
                                radius: 8,
                              ),
                              label: Text(label),
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selected.add(cat.nameEn);
                                  } else {
                                    _selected.remove(cat.nameEn);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  FilledButton(
                    onPressed: _goNext,
                    child: Text(l10n.done),
                  ),
                ],
              ),
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
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      );
    },
  );
}

/// Back-compat alias used by settings and older call sites.
Future<void> showCreateMonthDialog(BuildContext context) =>
    openCreateMonthFlow(context);
