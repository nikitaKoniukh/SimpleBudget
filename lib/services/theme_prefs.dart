import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the appearance choice (system / light / dark).
abstract final class ThemePrefs {
  static const key = 'theme_mode';

  /// Current choice; [MaterialApp] listens to this.
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = _decode(prefs.getString(key));
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value.name);
  }

  static ThemeMode _decode(String? name) {
    for (final m in ThemeMode.values) {
      if (m.name == name) return m;
    }
    return ThemeMode.system;
  }
}
