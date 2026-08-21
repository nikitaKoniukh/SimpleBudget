import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import 'budget_sheets.dart';
import '../home/log_entry_sheet.dart';

/// Register for one subcategory: list expenses, tap to edit, add new, edit plan.
Future<void> showSubcategoryRegisterSheet(
  BuildContext context, {
  required Subcategory subcategory,
}) async {
  final l10n = AppLocalizations.of(context);
  final dateFmt = DateFormat.yMMMd(
    Localizations.localeOf(context).languageCode,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Consumer<AppState>(
                builder: (ctx, state, _) {
                  final isSavings =
                      state.categoryById(subcategory.categoryId)?.isSavings ??
                          false;
                  final expenses = state.expensesFor(subcategory.id);
                  final planned = state.plannedFor(subcategory.id);
                  final spent = state.spentFor(subcategory.id);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        subcategory.localizedName(state.localeCode),
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      Text(
                        '${formatIls(spent)} / ${formatIls(planned)}',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: SyncColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            showPlanEditor(context, subcategory: subcategory);
                          },
                          child: Text(l10n.editPlan),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: expenses.isEmpty
                            ? Center(child: Text(l10n.noExpensesYet))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: expenses.length,
                                itemBuilder: (ctx, index) {
                                  final expense = expenses[index];
                                  final note = expense.note?.trim();
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      note == null || note.isEmpty
                                          ? '—'
                                          : note,
                                    ),
                                    subtitle:
                                        Text(dateFmt.format(expense.date)),
                                    trailing: Text(
                                      formatIls(expense.amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      showLogEntrySheet(
                                        context,
                                        kind: isSavings || expense.isDeposit
                                            ? LogKind.save
                                            : LogKind.spend,
                                        expense: expense,
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          showLogEntrySheet(
                            context,
                            kind: isSavings ? LogKind.save : LogKind.spend,
                            subcategoryId: subcategory.id,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          isSavings ? l10n.logDeposit : l10n.addExpense,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}
