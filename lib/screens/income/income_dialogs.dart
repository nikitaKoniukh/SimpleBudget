import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/text_format.dart';

Future<String?> showAddIncomeSourceDialog(BuildContext context) async {
  final source = await _createIncomeSource(context);
  return source?.id;
}

Future<IncomeSource?> _createIncomeSource(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final nameCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.addIncomeSource),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: TextField(
        controller: nameCtrl,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.description),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;
  final name = sentenceCase(nameCtrl.text);
  if (name.isEmpty) return null;
  final state = context.read<AppState>();
  final sortOrder = state.incomeSources.length;
  final id = await state.repo.addIncomeSource(
    householdId: state.activeHouseholdId!,
    monthId: state.monthId!,
    nameEn: name,
    nameRu: name,
    sortOrder: sortOrder,
  );
  return IncomeSource(
    id: id,
    nameEn: name,
    nameRu: name,
    sortOrder: sortOrder,
  );
}
