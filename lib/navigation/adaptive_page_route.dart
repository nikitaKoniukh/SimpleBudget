import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

Route<T> adaptivePageRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  if (_isApplePlatform) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
  return MaterialPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
  );
}

Future<T?> pushAdaptivePage<T>(
  BuildContext context,
  Widget page, {
  bool fullscreenDialog = false,
}) {
  return Navigator.of(context).push<T>(
    adaptivePageRoute<T>(
      builder: (_) => page,
      fullscreenDialog: fullscreenDialog,
    ),
  );
}
