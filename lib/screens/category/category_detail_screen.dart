import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/category_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../navigation/adaptive_page_route.dart';
import '../../providers/app_state.dart';
import '../../theme/sync_theme.dart';
import '../../utils/money.dart';
import '../../utils/text_format.dart';
import '../../widgets/budget/category_color_icon.dart';
import '../../widgets/detail_info_card.dart';
import '../../widgets/sync_app_bar.dart';
import 'budget_sheets.dart';
import 'category_sheets.dart';
import 'subcategory_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _editing = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late String _type;
  late int _colorValue;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _targetCtrl = TextEditingController();
    _type = 'spend';
    _colorValue = categoryColorPalette.first;
    _iconKey = defaultCategoryIconKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncFromCategory(_readCategory());
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  BudgetCategory _readCategory() {
    final state = context.read<AppState>();
    return state.categoryById(widget.categoryId)!;
  }

  void _syncFromCategory(BudgetCategory category) {
    final state = context.read<AppState>();
    _nameCtrl.text = category.localizedName(state.localeCode);
    _targetCtrl.text = category.targetAmount != null && category.targetAmount! > 0
        ? category.targetAmount!.toStringAsFixed(2)
        : '';
    _type = category.type;
    _colorValue = category.colorValue;
    _iconKey = category.iconKey;
  }

  void _startEditing(BudgetCategory category) {
    _syncFromCategory(category);
    setState(() => _editing = true);
  }

  void _cancelEditing(BudgetCategory category) {
    _syncFromCategory(category);
    setState(() => _editing = false);
  }

  Future<void> _save(AppState state, BudgetCategory category) async {
    final l10n = AppLocalizations.of(context);
    final name = sentenceCase(_nameCtrl.text);
    if (name.isEmpty) return;

    final parsedTarget = double.tryParse(_targetCtrl.text.replaceAll(',', ''));
    final target = _type == 'savings' && parsedTarget != null && parsedTarget > 0
        ? parsedTarget
        : null;

    try {
      await state.updateCategory(
        category.copyWith(
          nameEn: name,
          nameRu: name,
          colorValue: _colorValue,
          iconKey: _iconKey,
          type: _type,
          targetAmount: target,
          clearTargetAmount: target == null,
        ),
      );
      if (!mounted) return;
      setState(() => _editing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    BudgetCategory category,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(category.localizedName(state.localeCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await state.deleteCategory(category.id);
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final category = state.categoryById(widget.categoryId);
    if (category == null) {
      return SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SyncAppBar.flow(),
          body: Center(child: Text(l10n.noData)),
        ),
      );
    }

    final subs = state.subcategoriesForMonth(category.id);
    final canEdit = state.canEditPlan;
    final planned = state.categoryPlanned(category.id);
    final actual = state.categoryActual(category.id);

    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SyncAppBar.flow(
          onBack: _editing ? () => _cancelEditing(category) : null,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: CategoryColorIcon(
                colorValue: _editing ? _colorValue : category.colorValue,
                iconKey: _editing ? _iconKey : category.iconKey,
                size: 72,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _editing
                  ? l10n.editCategory
                  : category.localizedName(state.localeCode),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!_editing) ...[
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: Text(categoryTypeLabel(l10n, category.type)),
                  backgroundColor: SyncColors.surfaceMint,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_editing)
              _CategoryEditForm(
                l10n: l10n,
                nameCtrl: _nameCtrl,
                targetCtrl: _targetCtrl,
                type: _type,
                colorValue: _colorValue,
                iconKey: _iconKey,
                onTypeChanged: (t) => setState(() => _type = t),
                onColorChanged: (c) => setState(() => _colorValue = c),
                onIconChanged: (k) => setState(() => _iconKey = k),
              )
            else ...[
              if (!category.isSavings) ...[
                DetailInfoCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DetailStatCell(
                            label: l10n.spentLabel,
                            amount: formatIls(actual),
                            color: actual > planned && planned > 0
                                ? SyncColors.overspend
                                : SyncColors.accent,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: SyncColors.textMuted.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: DetailStatCell(
                            label: l10n.plannedLabel,
                            amount: formatIls(planned),
                            color: SyncColors.text,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              DetailInfoCard(
                children: [
                  DetailInfoRow(
                    label: l10n.categoryType,
                    value: categoryTypeLabel(l10n, category.type),
                  ),
                  if (category.isSavings && category.savedTotal > 0)
                    DetailInfoRow(
                      label: l10n.savedLabel,
                      value: formatIls(category.savedTotal),
                      valueColor: SyncColors.primary,
                    ),
                  if (category.targetAmount != null && category.targetAmount! > 0)
                    DetailInfoRow(
                      label: l10n.targetAmount,
                      value: formatIls(category.targetAmount!),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  category.isSavings ? l10n.sectionSavings : l10n.subcategory,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (canEdit && !_editing)
                  TextButton.icon(
                    onPressed: () async {
                      final subId = await showAddSubcategorySheet(
                        context,
                        categoryId: category.id,
                      );
                      if (subId == null || !context.mounted) return;
                      final sub = context.read<AppState>().subcategoryById(subId);
                      if (sub != null) {
                        pushAdaptivePage(
                          context,
                          SubcategoryDetailScreen(subcategoryId: sub.id),
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      category.isSavings ? l10n.addPot : l10n.addSubcategory,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (subs.isEmpty)
              DetailInfoCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.noSubcategories,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SyncColors.textMuted,
                          ),
                    ),
                  ),
                ],
              )
            else
              for (final sub in subs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SubcategoryListTile(
                    subcategory: sub,
                    state: state,
                    l10n: l10n,
                  ),
                ),
            const SizedBox(height: 16),
            if (_editing) ...[
              FilledButton(
                onPressed: canEdit ? () => _save(state, category) : null,
                child: Text(l10n.save),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _cancelEditing(category),
                child: Text(l10n.cancel),
              ),
            ] else if (canEdit) ...[
              FilledButton.icon(
                onPressed: () => _startEditing(category),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.edit),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _confirmDelete(context, state, category),
                child: Text(l10n.delete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryEditForm extends StatelessWidget {
  const _CategoryEditForm({
    required this.l10n,
    required this.nameCtrl,
    required this.targetCtrl,
    required this.type,
    required this.colorValue,
    required this.iconKey,
    required this.onTypeChanged,
    required this.onColorChanged,
    required this.onIconChanged,
  });

  final AppLocalizations l10n;
  final TextEditingController nameCtrl;
  final TextEditingController targetCtrl;
  final String type;
  final int colorValue;
  final String iconKey;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<String> onIconChanged;

  @override
  Widget build(BuildContext context) {
    return DetailInfoCard(
      children: [
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.categoryName),
        ),
        const SizedBox(height: 12),
        Text(l10n.categoryType),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in const ['spend', 'monthly', 'debt', 'savings'])
              ChoiceChip(
                label: Text(categoryTypeLabel(l10n, t)),
                selected: type == t,
                onSelected: (_) => onTypeChanged(t),
              ),
          ],
        ),
        if (type == 'savings') ...[
          const SizedBox(height: 12),
          TextField(
            controller: targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.targetAmount),
          ),
        ],
        if (type != 'savings') ...[
          const SizedBox(height: 12),
          Text(l10n.categoryColor),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryColorPalette.map((c) {
              final selected = c == colorValue;
              return GestureDetector(
                onTap: () => onColorChanged(c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(width: 3, color: Colors.black87)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(l10n.categoryIcon),
          const SizedBox(height: 8),
          categoryIconPicker(
            iconKey: iconKey,
            colorValue: colorValue,
            onSelected: onIconChanged,
          ),
        ],
      ],
    );
  }
}

class _SubcategoryListTile extends StatelessWidget {
  const _SubcategoryListTile({
    required this.subcategory,
    required this.state,
    required this.l10n,
  });

  final Subcategory subcategory;
  final AppState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final spent = state.spentFor(subcategory.id);
    final planned = state.planFor(subcategory.id)?.planned ?? 0;

    return Material(
      color: SyncColors.frostedSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => pushAdaptivePage(
          context,
          SubcategoryDetailScreen(subcategoryId: subcategory.id),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.localizedSubcategoryName(subcategory),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                formatIls(spent),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: spent > planned && planned > 0
                          ? SyncColors.overspend
                          : SyncColors.accent,
                    ),
              ),
              const SizedBox(width: 12),
              Text(
                formatIls(planned),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncColors.textMuted,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: SyncColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
