import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../category/category_detail_screen.dart';
import '../income/income_dialogs.dart';

Future<void> showQuickLogSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  if (!state.hasMonthSelected) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.quickLog,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.payments_outlined),
                ),
                title: Text(l10n.income),
                subtitle: Text(l10n.addEntry),
                onTap: () async {
                  Navigator.pop(ctx);
                  await showAddIncomeEntryFlow(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.shopping_bag_outlined),
                ),
                title: Text(l10n.expense),
                subtitle: Text(l10n.addExpense),
                onTap: () {
                  Navigator.pop(ctx);
                  if (state.categories.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.emptyCategories)),
                    );
                    return;
                  }
                  showLineItemEditor(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
