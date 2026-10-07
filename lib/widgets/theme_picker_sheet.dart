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

/// Settings row: switch between light and dark (persists via [ThemePrefs]).
class AppearanceSwitcherTile extends StatelessWidget {
  const AppearanceSwitcherTile({super.key});

  bool _isDark(BuildContext context, ThemeMode mode) {
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemePrefs.mode,
      builder: (context, mode, _) {
        final isDark = _isDark(context, mode);
        return SwitchListTile(
          secondary: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          ),
          title: Text(l10n.appearance),
          subtitle: Text(isDark ? l10n.themeDark : l10n.themeLight),
          value: isDark,
          onChanged: (dark) =>
              ThemePrefs.set(dark ? ThemeMode.dark : ThemeMode.light),
        );
      },
    );
  }
}
