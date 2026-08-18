import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
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
      await state.createMonth(monthId: monthId);
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
    final willCopy = state.months.any((m) => m.id != monthId);

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
        body: Padding(
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
                willCopy ? l10n.copyFromPrevious : l10n.howAreWeDoing,
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
              const Spacer(),
              FilledButton(
                onPressed: _saving || alreadyExists ? null : _finish,
                child: Text(l10n.done),
              ),
            ],
          ),
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
