import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/quick_log_launch.dart';
import '../../services/quick_log_widget_service.dart';
import '../../theme/sync_theme.dart';
import 'log_entry_flow.dart';

/// Compact spend-only log opened from the Android home-screen widget.
class QuickLogOverlayScreen extends StatelessWidget {
  const QuickLogOverlayScreen({super.key});

  void _exitToAndroidHome() {
    QuickLogLaunch.clear();
    SystemNavigator.pop();
  }

  void _openMainApp() {
    QuickLogLaunch.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);

    if (state.loading || (state.hasHousehold && !state.budgetDataReady)) {
      return const SyncBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!state.isSignedIn) {
      return _QuickLogBlockedScreen(
        message: l10n.widgetSignInToLog,
        onDismiss: _openMainApp,
      );
    }

    if (!state.hasHousehold) {
      return _QuickLogBlockedScreen(
        message: l10n.widgetNeedHousehold,
        onDismiss: _openMainApp,
      );
    }

    if (!state.hasMonthSelected) {
      return _QuickLogBlockedScreen(
        message: l10n.noMonthSelected,
        onDismiss: _openMainApp,
      );
    }

    return LogEntryFlowScreen(
      kind: LogKind.spend,
      skipTypeStep: true,
      onCompleted: () {
        unawaited(QuickLogWidgetService.sync(state));
        _exitToAndroidHome();
      },
      onCancel: _openMainApp,
    );
  }
}

class _QuickLogBlockedScreen extends StatelessWidget {
  const _QuickLogBlockedScreen({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SyncBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Spacer(),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onDismiss,
                  child: Text(l10n.done),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
