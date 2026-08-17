import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/csv_export.dart';

Future<void> exportAndShareMonthCsv(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final household = state.household;
  if (household == null) return;

  final csv = buildMonthCsv(
    monthId: state.monthId,
    householdName: household.name,
    incomeSources: state.incomeSources,
    incomeEntries: state.incomeEntries,
    categories: state.categories,
    lineItems: state.lineItems,
    localeCode: state.localeCode,
  );

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/syncmonth_${state.monthId}.csv');
  await file.writeAsString(csv, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'SyncMonth ${state.monthId}',
      text: l10n.exportCsv,
    ),
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.exportDone)),
    );
  }
}
