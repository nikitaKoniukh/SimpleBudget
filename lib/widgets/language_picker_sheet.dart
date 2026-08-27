import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/language_options.dart';

Future<void> showLanguagePickerSheet(
  BuildContext context, {
  required String selectedCode,
  required ValueChanged<String> onSelected,
}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(
                l10n.language,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in orderedLanguageOptions)
                    ListTile(
                      leading: _LanguageFlag(flag: option.flag),
                      title: Text(option.label),
                      trailing: selectedCode == option.code
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      selected: selectedCode == option.code,
                      onTap: () {
                        onSelected(option.code);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class LanguagePickerTile extends StatelessWidget {
  const LanguagePickerTile({
    super.key,
    required this.localeCode,
    required this.onLocaleSelected,
  });

  final String localeCode;
  final ValueChanged<String> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = languageOptionFor(localeCode);

    return ListTile(
      leading: _LanguageFlag(flag: selected.flag),
      title: Text(l10n.language),
      subtitle: Text(selected.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showLanguagePickerSheet(
        context,
        selectedCode: localeCode,
        onSelected: onLocaleSelected,
      ),
    );
  }
}

class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        flag,
        style: const TextStyle(fontSize: 28, height: 1.1),
        textAlign: TextAlign.center,
      ),
    );
  }
}
