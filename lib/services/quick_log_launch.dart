import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'quick_log_widget_service.dart';

/// Tracks whether the app was opened from a quick-log home-screen widget.
abstract final class QuickLogLaunch {
  static final ValueNotifier<bool> spendOverlay = ValueNotifier(false);

  static StreamSubscription<Uri?>? _clickSub;

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(QuickLogWidgetService.appGroupId);
      }
      handleUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
      await _clickSub?.cancel();
      _clickSub = HomeWidget.widgetClicked.listen(handleUri);
    } catch (_) {
      // Plugin unavailable on unsupported platforms/hosts.
    }
  }

  static void handleUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != 'syncmonth') return;
    if (uri.host != 'quicklog') return;
    final path = uri.path;
    if (path == '/spend' || uri.pathSegments.contains('spend')) {
      spendOverlay.value = true;
    }
  }

  static void clear() {
    spendOverlay.value = false;
  }
}
