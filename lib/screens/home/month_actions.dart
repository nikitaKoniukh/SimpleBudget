import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/money.dart';

Future<void> showCreateMonthDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final now = DateTime.now();
  var year = now.year;
  var month = now.month;
  var copyFrom = state.months.isNotEmpty ? state.months.first.id : null;
  var useCopy = state.months.isNotEmpty;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(l10n.createMonth),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.yearLabel),
                  DropdownButton<int>(
                    value: year,
                    isExpanded: true,
                    items: [
                      for (var y = now.year - 1; y <= now.year + 2; y++)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => year = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.monthLabel),
                  DropdownButton<int>(
                    value: month,
                    isExpanded: true,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(
                            l10n.monthTitle(DateTime(year, m)),
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => month = v);
                    },
                  ),
                  if (state.months.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.copyFromPrevious),
                      value: useCopy,
                      onChanged: (v) => setLocal(() => useCopy = v),
                    ),
                    if (useCopy)
                      DropdownButton<String>(
                        value: copyFrom,
                        isExpanded: true,
                        hint: Text(l10n.selectMonthToCopy),
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
                        onChanged: (v) => setLocal(() => copyFrom = v),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.createMonth),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != true || !context.mounted) return;

  final monthId =
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  try {
    await state.createMonth(
      monthId: monthId,
      copyFromMonthId: useCopy ? copyFrom : null,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.monthCreated}: $monthId')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGeneric}: $e')),
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
                showCreateMonthDialog(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
