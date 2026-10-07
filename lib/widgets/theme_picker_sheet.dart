import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/theme_prefs.dart';

String themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return l10n.themeSystem;
    case ThemeMode.light:
      return l10n.themeLight;
    case ThemeMode.dark:
      return l10n.themeDark;
  }
}

IconData themeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return Icons.brightness_auto_outlined;
    case ThemeMode.light:
      return Icons.light_mode_outlined;
    case ThemeMode.dark:
      return Icons.dark_mode_outlined;
  }
}

Future<void> showThemePickerSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final selected = ThemePrefs.mode.value;

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
                l10n.appearance,
                style: theme.textTheme.titleLarge,
              ),
            ),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(themeModeIcon(mode)),
                title: Text(themeModeLabel(l10n, mode)),
                trailing: selected == mode
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                selected: selected == mode,
                onTap: () {
                  ThemePrefs.set(mode);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      );
    },
  );
}

/// Settings row: Appearance — System / Light / Dark.
class ThemePickerTile extends StatelessWidget {
  const ThemePickerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemePrefs.mode,
      builder: (context, mode, _) {
        return ListTile(
          leading: Icon(themeModeIcon(mode)),
          title: Text(l10n.appearance),
          subtitle: Text(themeModeLabel(l10n, mode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showThemePickerSheet(context),
        );
      },
    );
  }
}
