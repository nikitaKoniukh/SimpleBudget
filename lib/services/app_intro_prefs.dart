import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the first-launch feature tour has been completed.
abstract final class AppIntroPrefs {
  static const key = 'has_completed_app_intro';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
