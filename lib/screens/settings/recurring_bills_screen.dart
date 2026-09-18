import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../widgets/budget/bill_card.dart';
import '../../widgets/sync_app_bar.dart';
import 'bill_sheets.dart';

class RecurringBillsScreen extends StatelessWidget {
  const RecurringBillsScreen({super.key});

  /// Days until [dayOfMonth] from [today], wrapping to next month when past.
  static int daysUntilDue(int dayOfMonth, DateTime today) {
    final day = dayOfMonth.clamp(1, 28);
    final thisMonth = DateTime(today.year, today.month, day);
    final start = DateTime(today.year, today.month, today.day);
    if (!thisMonth.isBefore(start)) {
      return thisMonth.difference(start).inDays;
    }
    final nextMonth = DateTime(today.year, today.month + 1, day);
    return nextMonth.difference(start).inDays;
  }

  static bool isDueSoon(int dayOfMonth, DateTime today) =>
      daysUntilDue(dayOfMonth, today) <= 7;

  static List<RecurringBill> sortedByNextDue(
    List<RecurringBill> bills,
    DateTime today,
  ) {
    final list = List.of(bills);
    list.sort((a, b) {
      final byDue = daysUntilDue(a.dayOfMonth, today)
          .compareTo(daysUntilDue(b.dayOfMonth, today));
      if (byDue != 0) return byDue;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> _delete(BuildContext context, RecurringBill bill) async {
    final ok = await confirmDeleteBill(context, bill);
    if (!ok || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    try {
      await context.read<AppState>().deleteRecurringBill(bill.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  String? _subcategoryLabel(AppState state, RecurringBill bill) {
    final subId = bill.subcategoryId;
    if (subId == null) return null;
    final sub = state.subcategoryById(subId);
    if (sub == null) return null;
    final cat = state.categoryById(sub.categoryId);
    final catName = cat?.localizedName(state.localeCode);
    final subName = sub.localizedName(state.localeCode);
    if (catName == null || catName.isEmpty) return subName;
    return '$catName · $subName';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final canEdit = state.canEditPlan;
    final today = DateTime.now();
    final bills = sortedByNextDue(state.recurringBills, today);
    final monthlyTotal = bills.fold<double>(0, (s, b) => s + b.amount);
    final next = bills.isEmpty ? null : bills.first;

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.page(title: l10n.recurringBills),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: () => showAddBillSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addBill),
              )
            : null,
        body: bills.isEmpty
            ? _EmptyBills(
                canEdit: canEdit,
                onAdd: () => showAddBillSheet(context),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _BillsHero(
                    monthlyTotal: monthlyTotal,
                    next: next,
                  ),
                  for (final bill in bills)
                    BillCard(
                      bill: bill,
                      dueSoon: isDueSoon(bill.dayOfMonth, today),
                      subcategoryLabel: _subcategoryLabel(state, bill),
                      canEdit: canEdit,
                      onEdit: canEdit
                          ? () => showEditBillSheet(context, bill: bill)
                          : null,
                      onDelete: canEdit ? () => _delete(context, bill) : null,
                    ),
                ],
              ),
      ),
    );
  }
}

class _BillsHero extends StatelessWidget {
  const _BillsHero({
    required this.monthlyTotal,
    required this.next,
  });

  final double monthlyTotal;
  final RecurringBill? next;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.monthlyBillsTotal,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                formatIls(monthlyTotal),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: SyncColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (next != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: SyncColors.surfaceMint.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.nextBill,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: SyncColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              next!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.billDay} ${next!.dayOfMonth}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SyncColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills({required this.canEdit, required this.onAdd});

  final bool canEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: SyncColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyBills,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: SyncColors.textMuted,
                  ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(l10n.addBill),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
