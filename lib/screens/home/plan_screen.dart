import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../category/categories_screen.dart';
import '../category/category_detail_screen.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'savings':
        return l10n.typeSavings;
      case 'debt':
        return l10n.typeDebt;
      default:
        return l10n.typeExpense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    if (!state.hasMonthSelected) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.plan)),
          body: Center(child: Text(l10n.noMonthSelected)),
        ),
      );
    }

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.plan),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              },
              child: Text(l10n.manageCategories),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            );
          },
          icon: const Icon(Icons.category_outlined),
          label: Text(l10n.addCategory),
        ),
        body: state.categories.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.emptyCategories,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          final n = await state.addDefaultCategories();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                n > 0
                                    ? l10n.defaultsAdded
                                    : l10n.defaultsAlreadyPresent,
                              ),
                            ),
                          );
                        },
                        child: Text(l10n.addDefaultCategories),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final cat = state.categories[index];
                  final planned = state.categoryPlanned(cat.id);
                  final actual = state.categoryActual(cat.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CategoryDetailScreen(categoryId: cat.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Color(cat.colorValue)
                                          .withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      cat.type == 'savings'
                                          ? Icons.savings_outlined
                                          : cat.type == 'debt'
                                              ? Icons.credit_card_outlined
                                              : Icons.shopping_bag_outlined,
                                      color: SyncColors.text,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat.localizedName(state.localeCode),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SyncColors.surfaceMint,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _typeLabel(l10n, cat.type),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PlanMetric(
                                      label: l10n.plannedLabel,
                                      value: formatIls(planned),
                                    ),
                                  ),
                                  Expanded(
                                    child: _PlanMetric(
                                      label: l10n.spentLabel,
                                      value: formatIls(actual),
                                    ),
                                  ),
                                  Expanded(
                                    child: _PlanMetric(
                                      label: l10n.difference,
                                      value: formatIls(planned - actual),
                                      emphasize: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SyncColors.textMuted,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
